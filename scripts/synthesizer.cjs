#!/usr/bin/env node

/**
 * synthesizer.cjs
 * Logique de Synthesis et d'Arbitrage de Fusion pour l'orchestrateur d'agents
 * Phase 3.4 — Antigravity CLI Skill
 *
 * Fonctionnement :
 *  1. Fusion en mémoire via `git merge-tree` (sans toucher au répertoire de travail)
 *  2. Si succès → commit via `git commit-tree` + mise à jour de la ref via `git update-ref`
 *  3. Si conflit → rapport détaillé + 3 stratégies d'arbitrage :
 *     - AUTO  : délégation à un agent de synthèse (message vers Antigravity)
 *     - OURS  : priorité à la branche de l'Agent 1
 *     - THEIRS: priorité à la branche de l'Agent 2
 */

'use strict';

const { execSync, execFileSync } = require('child_process');
const path = require('path');

// ==============================================================================
// UTILITAIRES GIT
// ==============================================================================

/**
 * Exécute une commande git et retourne sa sortie (stdout).
 * Lève une exception en cas d'erreur.
 */
function git(...args) {
  return execFileSync('git', args, { encoding: 'utf8' }).trim();
}

/**
 * Tente une commande git et retourne null en cas d'échec (sans lancer d'exception).
 */
function gitSafe(...args) {
  try {
    return git(...args);
  } catch {
    return null;
  }
}

// ==============================================================================
// 1. FUSION EN MÉMOIRE — git merge-tree
// ==============================================================================

/**
 * Tente une fusion en mémoire entre deux branches à partir d'une base commune.
 * N'affecte PAS le répertoire de travail ni l'index.
 *
 * @param {string} baseBranch   - La branche de base commune (ex: main)
 * @param {string} branch1      - La branche de l'Agent 1 (ex: task-123)
 * @param {string} branch2      - La branche de l'Agent 2 (ex: task-456)
 * @returns {{ success: boolean, mergeTree: string|null, conflicts: string[]|null }}
 */
function mergeInMemory(baseBranch, branch1, branch2) {
  console.log(`[synthesizer] Fusion en mémoire : base=${baseBranch}, branch1=${branch1}, branch2=${branch2}`);

  // Résolution des SHAs des branches
  const baseSha   = git('rev-parse', '--verify', baseBranch);
  const branch1Sha = git('rev-parse', '--verify', branch1);
  const branch2Sha = git('rev-parse', '--verify', branch2);

  let mergeTreeOutput;
  let mergeTreeSha;

  // git merge-tree --write-tree écrit l'arbre fusionné et retourne son SHA
  // Si des conflits existent, la sortie contient des marqueurs et le code de sortie est non-nul
  try {
    mergeTreeOutput = execFileSync(
      'git',
      ['merge-tree', '--write-tree', '--no-messages', baseSha, branch1Sha, branch2Sha],
      { encoding: 'utf8' }
    ).trim();

    // Première ligne = SHA de l'arbre fusionné
    mergeTreeSha = mergeTreeOutput.split('\n')[0].trim();
    console.log(`[synthesizer] ✅ Fusion réussie. Arbre de fusion SHA : ${mergeTreeSha}`);
    return { success: true, mergeTree: mergeTreeSha, conflicts: null };

  } catch (err) {
    // git merge-tree retourne code 1 en cas de conflit
    const output = (err.stdout || '').trim();
    mergeTreeSha = output.split('\n')[0].trim();

    // Extraction des blocs de conflits depuis la sortie
    const conflictLines = (err.stderr || err.stdout || '')
      .split('\n')
      .filter(l => l.includes('<<<<<<<') || l.includes('>>>>>>>') || l.includes('======='));

    // Récupération des fichiers en conflit via git ls-files
    let conflictFiles = [];
    try {
      const conflictOutput = execFileSync(
        'git',
        ['merge-tree', '--write-tree', '--name-only', baseSha, branch1Sha, branch2Sha],
        { encoding: 'utf8' }
      ).trim();
      conflictFiles = conflictOutput.split('\n').filter(Boolean);
    } catch (e) {
      conflictFiles = ['Fichiers en conflit non déterminés'];
    }

    console.error(`[synthesizer] ⚠️  Conflits détectés dans ${conflictFiles.length} fichier(s) :`);
    conflictFiles.forEach(f => console.error(`  - ${f}`));

    return {
      success: false,
      mergeTree: mergeTreeSha || null,
      conflicts: conflictFiles,
    };
  }
}

// ==============================================================================
// 2. COMMIT EN MÉMOIRE — git commit-tree + git update-ref
// ==============================================================================

/**
 * Crée un commit de fusion en mémoire à partir d'un arbre de fusion déjà calculé.
 * Met ensuite à jour la référence de la branche cible.
 *
 * @param {string} mergeTreeSha   - Le SHA de l'arbre de fusion (issu de mergeInMemory)
 * @param {string} branch1        - Première branche parente
 * @param {string} branch2        - Deuxième branche parente
 * @param {string} targetBranch   - La branche cible à mettre à jour (ex: main)
 * @param {string} message        - Message du commit de fusion
 * @returns {string} Le SHA du nouveau commit de fusion
 */
function commitMerge(mergeTreeSha, branch1, branch2, targetBranch, message) {
  const branch1Sha = git('rev-parse', '--verify', branch1);
  const branch2Sha = git('rev-parse', '--verify', branch2);

  // Création du commit de fusion en mémoire avec deux parents
  const commitSha = git(
    'commit-tree',
    mergeTreeSha,
    '-p', branch1Sha,
    '-p', branch2Sha,
    '-m', message
  );

  // Mise à jour de la référence de la branche cible
  git('update-ref', `refs/heads/${targetBranch}`, commitSha);

  console.log(`[synthesizer] ✅ Commit de fusion créé : ${commitSha}`);
  console.log(`[synthesizer] ✅ Branche '${targetBranch}' mise à jour → ${commitSha}`);
  return commitSha;
}

// ==============================================================================
// 3. ARBITRAGE DES CONFLITS
// ==============================================================================

/**
 * Résout un conflit selon la stratégie choisie.
 *
 * @param {string} baseBranch   - Branche de base
 * @param {string} branch1      - Branche Agent 1
 * @param {string} branch2      - Branche Agent 2
 * @param {string} targetBranch - Branche cible
 * @param {'AUTO'|'OURS'|'THEIRS'} strategy
 * @returns {{ success: boolean, commitSha: string|null, report: string }}
 */
function resolveConflict(baseBranch, branch1, branch2, targetBranch, strategy) {
  console.log(`[synthesizer] Arbitrage de conflit — Stratégie : ${strategy}`);

  switch (strategy) {

    // Stratégie OURS : on prend uniquement les modifications de branch1
    case 'OURS': {
      const branch1Sha = git('rev-parse', '--verify', branch1);
      const treeSha = git('rev-parse', `${branch1Sha}^{tree}`);
      const baseSha = git('rev-parse', '--verify', baseBranch);
      const commitSha = git(
        'commit-tree', treeSha,
        '-p', baseSha,
        '-m', `[Arbitrage OURS] Conflits résolus en faveur de ${branch1}`
      );
      git('update-ref', `refs/heads/${targetBranch}`, commitSha);
      console.log(`[synthesizer] ✅ Conflit résolu (OURS) → ${commitSha}`);
      return {
        success: true,
        commitSha,
        report: `Conflits résolus par stratégie OURS (priorité à ${branch1}).`,
      };
    }

    // Stratégie THEIRS : on prend uniquement les modifications de branch2
    case 'THEIRS': {
      const branch2Sha = git('rev-parse', '--verify', branch2);
      const treeSha = git('rev-parse', `${branch2Sha}^{tree}`);
      const baseSha = git('rev-parse', '--verify', baseBranch);
      const commitSha = git(
        'commit-tree', treeSha,
        '-p', baseSha,
        '-m', `[Arbitrage THEIRS] Conflits résolus en faveur de ${branch2}`
      );
      git('update-ref', `refs/heads/${targetBranch}`, commitSha);
      console.log(`[synthesizer] ✅ Conflit résolu (THEIRS) → ${commitSha}`);
      return {
        success: true,
        commitSha,
        report: `Conflits résolus par stratégie THEIRS (priorité à ${branch2}).`,
      };
    }

    // Stratégie AUTO : escalade vers Antigravity pour arbitrage manuel ou par agent
    case 'AUTO':
    default: {
      const report = `
[synthesizer] ⚠️  ARBITRAGE AUTOMATIQUE REQUIS
──────────────────────────────────────────────
Des conflits de fusion non triviaux ont été détectés entre :
  - Branch Agent 1 : ${branch1}
  - Branch Agent 2 : ${branch2}
  - Base           : ${baseBranch}
  - Cible          : ${targetBranch}

Action requise : L'agent principal (Antigravity) doit arbitrer manuellement
ou déléguer à un agent de résolution de conflits.

Stratégies disponibles :
  OURS   → Priorité totale aux modifications de ${branch1}
  THEIRS → Priorité totale aux modifications de ${branch2}
  MANUAL → Résolution interactive ligne par ligne

Commande pour relancer avec une stratégie :
  node synthesizer.cjs synthesize ${baseBranch} ${branch1} ${branch2} ${targetBranch} OURS
  node synthesizer.cjs synthesize ${baseBranch} ${branch1} ${branch2} ${targetBranch} THEIRS
──────────────────────────────────────────────`;
      console.log(report);
      return { success: false, commitSha: null, report };
    }
  }
}

// ==============================================================================
// 4. ORCHESTRATION PRINCIPALE — Synthesis complète
// ==============================================================================

/**
 * Point d'entrée principal de la logique de synthesis.
 * Tente la fusion en mémoire et applique l'arbitrage si nécessaire.
 */
function synthesize(baseBranch, branch1, branch2, targetBranch, strategy = 'AUTO') {
  console.log('\n[synthesizer] ══════════════════════════════════════');
  console.log('[synthesizer]  DÉMARRAGE DE LA PHASE DE SYNTHESIS');
  console.log('[synthesizer] ══════════════════════════════════════');

  // Étape 1 : Fusion en mémoire
  const { success, mergeTree, conflicts } = mergeInMemory(baseBranch, branch1, branch2);

  if (success && mergeTree) {
    // Étape 2 : Commit en mémoire sans conflit
    const message = `[Synthesis] Fusion de ${branch1} et ${branch2} dans ${targetBranch}`;
    const commitSha = commitMerge(mergeTree, branch1, branch2, targetBranch, message);
    console.log(`\n[synthesizer] ✅ SYNTHESIS TERMINÉE AVEC SUCCÈS — Commit : ${commitSha}`);
    return { success: true, commitSha, conflicts: null };
  }

  // Étape 3 : Arbitrage des conflits
  console.log(`\n[synthesizer] Conflits détectés (${conflicts?.length || '?'} fichier(s)). Application de la stratégie : ${strategy}`);
  const result = resolveConflict(baseBranch, branch1, branch2, targetBranch, strategy);

  if (!result.success) {
    console.log('\n[synthesizer] ❌ SYNTHESIS BLOQUÉE — Arbitrage manuel requis.');
  }
  return { success: result.success, commitSha: result.commitSha, conflicts };
}

// ==============================================================================
// 5. POINT D'ENTRÉE CLI
// ==============================================================================
function printHelp() {
  console.log(`
Usage: node synthesizer.cjs <commande> [arguments]

Commandes :
  synthesize <base> <branch1> <branch2> <target> [AUTO|OURS|THEIRS]
      Tente la fusion en mémoire et applique l'arbitrage si nécessaire.

  merge-check <base> <branch1> <branch2>
      Vérifie uniquement si la fusion est possible (sans appliquer).

Exemples :
  node synthesizer.cjs synthesize main task-123 task-456 main
  node synthesizer.cjs synthesize main task-123 task-456 main OURS
  node synthesizer.cjs merge-check main task-123 task-456
`);
}

const [,, cmd, ...args] = process.argv;

switch (cmd) {
  case 'synthesize': {
    const [base, b1, b2, target, strat] = args;
    if (!base || !b1 || !b2 || !target) { printHelp(); process.exit(1); }
    const result = synthesize(base, b1, b2, target, strat || 'AUTO');
    process.exit(result.success ? 0 : 1);
  }
  case 'merge-check': {
    const [base, b1, b2] = args;
    if (!base || !b1 || !b2) { printHelp(); process.exit(1); }
    const { success, conflicts } = mergeInMemory(base, b1, b2);
    if (success) {
      console.log('✅ Fusion possible sans conflit.');
      process.exit(0);
    } else {
      console.log(`❌ Conflits dans : ${(conflicts || []).join(', ')}`);
      process.exit(1);
    }
  }
  default:
    printHelp();
    process.exit(1);
}
