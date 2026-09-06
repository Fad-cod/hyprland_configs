#!/usr/bin/env node

/**
 * state_manager.cjs
 * Gestionnaire d'état de l'orchestrateur d'agents (agent-orchestrator)
 * Phase 3.3 — Antigravity CLI Skill
 *
 * Responsabilités :
 *  - Persistance de l'état de l'orchestrateur dans un fichier JSON (écriture atomique)
 *  - Suivi du compteur de récursion (Safety Break à 3 cycles max)
 *  - Détection des double-verdicts RED consécutifs → arrêt forcé
 *  - Crash Recovery : détection et nettoyage des worktrees zombies au démarrage
 */

'use strict';

const fs   = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// ==============================================================================
// CONFIGURATION
// ==============================================================================
const RECURSION_LIMIT = 3;
const STATE_FILE      = path.resolve(__dirname, '../.orchestrator-state.json');
const TEMP_STATE_FILE = STATE_FILE + '.tmp';

// États valides de l'orchestrateur (machine à états finis)
const VALID_STATES = ['Idle', 'Planning', 'Tasking', 'Audit', 'Synthesis', 'Blocked'];

// Structure d'état initiale
const DEFAULT_STATE = {
  state: 'Idle',
  currentTask: null,
  recursionCount: 0,
  consecutiveRedCount: 0,
  activeTasks: {},   // { task_id: { branch, worktreeDir, startedAt } }
  history: [],
};

// ==============================================================================
// 1. PERSISTANCE — Lecture / Écriture Atomique
// ==============================================================================

/**
 * Lit l'état persistant depuis le fichier JSON.
 * Retourne l'état par défaut si le fichier est absent ou corrompu.
 */
function readState() {
  try {
    if (!fs.existsSync(STATE_FILE)) return { ...DEFAULT_STATE };
    const raw = fs.readFileSync(STATE_FILE, 'utf8');
    return JSON.parse(raw);
  } catch (err) {
    console.error(`[state_manager] Avertissement: Impossible de lire l'état (${err.message}). Réinitialisation.`);
    return { ...DEFAULT_STATE };
  }
}

/**
 * Écrit l'état dans le fichier JSON de manière ATOMIQUE.
 * Utilise un fichier temporaire + renommage pour éviter toute corruption.
 */
function writeState(state) {
  const json = JSON.stringify(state, null, 2);
  fs.writeFileSync(TEMP_STATE_FILE, json, 'utf8');
  fs.renameSync(TEMP_STATE_FILE, STATE_FILE);
}

// ==============================================================================
// 2. SAFETY BREAK — Compteur de récursion et verdicts RED
// ==============================================================================

/**
 * Incrémente le compteur de récursion.
 * Déclenche un arrêt forcé (état Blocked) si la limite est atteinte.
 * @returns {boolean} true si on peut continuer, false si bloqué
 */
function incrementRecursion() {
  const state = readState();
  state.recursionCount += 1;

  if (state.recursionCount >= RECURSION_LIMIT) {
    state.state = 'Blocked';
    state.history.push({
      at: new Date().toISOString(),
      event: 'SAFETY_BREAK',
      reason: `Limite de récursion atteinte (${state.recursionCount}/${RECURSION_LIMIT})`,
    });
    writeState(state);
    console.error(`[state_manager] ⛔ SAFETY BREAK : Limite de récursion atteinte (${state.recursionCount}/${RECURSION_LIMIT}). Intervention humaine requise.`);
    return false;
  }

  writeState(state);
  console.log(`[state_manager] Compteur de récursion : ${state.recursionCount}/${RECURSION_LIMIT}`);
  return true;
}

/**
 * Enregistre un verdict de l'agent-criticateur (GREEN, ORANGE, RED).
 * Déclenche un arrêt forcé après 2 verdicts RED consécutifs.
 * @param {'GREEN'|'ORANGE'|'RED'} verdict
 * @returns {boolean} true si on peut continuer, false si arrêt forcé
 */
function recordVerdict(verdict) {
  const state = readState();

  state.history.push({
    at: new Date().toISOString(),
    event: 'VERDICT',
    verdict,
  });

  if (verdict === 'RED') {
    state.consecutiveRedCount += 1;
    if (state.consecutiveRedCount >= 2) {
      state.state = 'Blocked';
      state.history.push({
        at: new Date().toISOString(),
        event: 'FORCED_STOP',
        reason: `Double verdict RED consécutif (${state.consecutiveRedCount}). Arrêt forcé.`,
      });
      writeState(state);
      console.error(`[state_manager] ⛔ ARRÊT FORCÉ : ${state.consecutiveRedCount} verdicts RED consécutifs. Intervention humaine requise.`);
      return false;
    }
  } else {
    // Réinitialiser le compteur de RED si le verdict n'est pas RED
    state.consecutiveRedCount = 0;
  }

  writeState(state);
  console.log(`[state_manager] Verdict enregistré : ${verdict} (RED consécutifs : ${state.consecutiveRedCount})`);
  return true;
}

// ==============================================================================
// 3. TRANSITIONS D'ÉTAT
// ==============================================================================

/**
 * Effectue une transition d'état validée.
 * @param {string} newState - L'état cible
 */
function transition(newState) {
  if (!VALID_STATES.includes(newState)) {
    throw new Error(`[state_manager] État invalide : '${newState}'. États valides : ${VALID_STATES.join(', ')}`);
  }
  const state = readState();
  const previousState = state.state;
  state.state = newState;
  state.history.push({
    at: new Date().toISOString(),
    event: 'TRANSITION',
    from: previousState,
    to: newState,
  });
  writeState(state);
  console.log(`[state_manager] Transition : ${previousState} → ${newState}`);
}

/**
 * Enregistre une tâche active (worktree démarré).
 */
function registerTask(taskId, branch, worktreeDir) {
  const state = readState();
  state.activeTasks[taskId] = {
    branch,
    worktreeDir,
    startedAt: new Date().toISOString(),
  };
  writeState(state);
  console.log(`[state_manager] Tâche enregistrée : ${taskId} (branche: ${branch})`);
}

/**
 * Supprime une tâche active (worktree nettoyé).
 */
function unregisterTask(taskId) {
  const state = readState();
  if (state.activeTasks[taskId]) {
    delete state.activeTasks[taskId];
    writeState(state);
    console.log(`[state_manager] Tâche supprimée : ${taskId}`);
  }
}

// ==============================================================================
// 4. CRASH RECOVERY — Nettoyage des worktrees zombies au démarrage
// ==============================================================================

/**
 * Détecte et nettoie les worktrees zombies au démarrage de l'orchestrateur.
 * Compare l'état persistant avec la liste réelle des worktrees Git.
 */
function recover() {
  console.log('[state_manager] 🔄 Crash Recovery : Vérification des worktrees zombies...');
  const state = readState();

  // Récupérer la liste des worktrees enregistrés par Git
  let gitWorktrees = [];
  try {
    const output = execSync('git worktree list --porcelain', { encoding: 'utf8' });
    gitWorktrees = output
      .split('\n\n')
      .map(block => {
        const lines = block.trim().split('\n');
        const worktreeLine = lines.find(l => l.startsWith('worktree '));
        return worktreeLine ? worktreeLine.replace('worktree ', '').trim() : null;
      })
      .filter(Boolean);
  } catch (err) {
    console.error(`[state_manager] Impossible de lister les worktrees Git : ${err.message}`);
    return;
  }

  // Pour chaque tâche dans l'état persistant, vérifier si son worktree existe encore
  const zombies = [];
  for (const [taskId, taskInfo] of Object.entries(state.activeTasks)) {
    const worktreeExists = gitWorktrees.some(wt => wt === path.resolve(taskInfo.worktreeDir));
    if (!worktreeExists) {
      zombies.push(taskId);
      console.warn(`[state_manager] ⚠️  Worktree zombie détecté pour la tâche : ${taskId} (${taskInfo.worktreeDir})`);
    }
  }

  // Nettoyer les worktrees zombies de l'état
  if (zombies.length > 0) {
    for (const taskId of zombies) {
      console.log(`[state_manager] Nettoyage de la tâche zombie : ${taskId}`);
      // Tenter de purger via git worktree prune
      try {
        execSync('git worktree prune', { encoding: 'utf8' });
      } catch (err) {
        console.error(`[state_manager] Erreur lors de git worktree prune : ${err.message}`);
      }
      delete state.activeTasks[taskId];
    }

    state.history.push({
      at: new Date().toISOString(),
      event: 'CRASH_RECOVERY',
      cleaned: zombies,
    });
    writeState(state);
    console.log(`[state_manager] ✅ Crash Recovery terminé. ${zombies.length} tâche(s) zombie(s) nettoyée(s).`);
  } else {
    console.log('[state_manager] ✅ Aucun worktree zombie détecté. Démarrage propre.');
  }

  // Si l'état était Blocked, le signaler
  if (state.state === 'Blocked') {
    console.warn('[state_manager] ⛔ L\'orchestrateur était en état BLOQUÉ. Intervention humaine requise avant de continuer.');
  }
}

/**
 * Réinitialise complètement l'état (après résolution manuelle d'un blocage).
 */
function reset() {
  writeState({ ...DEFAULT_STATE });
  console.log('[state_manager] 🔁 État réinitialisé à Idle.');
}

// ==============================================================================
// 5. POINT D'ENTRÉE CLI
// ==============================================================================
function printHelp() {
  console.log(`
Usage: node state_manager.cjs <commande> [arguments]

Commandes :
  recover                        Nettoyage des worktrees zombies au démarrage
  transition <état>              Changer l'état (${VALID_STATES.join('|')})
  increment-recursion            Incrémenter le compteur de récursion
  verdict <GREEN|ORANGE|RED>     Enregistrer un verdict du criticateur
  register <taskId> <branche> <répertoire>  Enregistrer une tâche active
  unregister <taskId>            Supprimer une tâche active
  reset                          Réinitialiser l'état à Idle
  status                         Afficher l'état courant
`);
}

const [,, cmd, ...args] = process.argv;

switch (cmd) {
  case 'recover':
    recover();
    break;
  case 'transition':
    transition(args[0]);
    break;
  case 'increment-recursion':
    process.exit(incrementRecursion() ? 0 : 1);
    break;
  case 'verdict':
    process.exit(recordVerdict(args[0]) ? 0 : 1);
    break;
  case 'register':
    registerTask(args[0], args[1], args[2]);
    break;
  case 'unregister':
    unregisterTask(args[0]);
    break;
  case 'reset':
    reset();
    break;
  case 'status': {
    const s = readState();
    console.log(JSON.stringify(s, null, 2));
    break;
  }
  default:
    printHelp();
    process.exit(1);
}
