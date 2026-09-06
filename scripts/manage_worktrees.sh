#!/usr/bin/env bash

# ==============================================================================
# Script : manage_worktrees.sh
# Description : Gestion sécurisée et robuste des git worktrees pour l'orchestrateur.
# Phase 3.1 du projet agent-orchestrator (v2 — corrections sécurité et robustesse)
# ==============================================================================

set -o pipefail

# S'assurer qu'on est dans un dépôt Git et se positionner à sa racine
ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$ROOT_DIR" ]; then
    echo "Erreur: Ce script doit être exécuté depuis l'intérieur d'un dépôt Git." >&2
    exit 1
fi
cd "$ROOT_DIR" || exit 1

# ==============================================================================
# CORRECTION BLOQUANTE #3 : Validation stricte du task_id (Path Traversal)
# ==============================================================================
validate_task_id() {
    local task_id="$1"
    if [[ ! "$task_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Erreur: task_id invalide '$task_id'. Seuls les caractères [a-zA-Z0-9_-] sont autorisés." >&2
        return 1
    fi
    return 0
}

# ==============================================================================
# CORRECTION BLOQUANTE #2 : Extraction du SHA brut via reflog (pas de ref symbolique)
# ==============================================================================
get_base_sha() {
    local branch_name="$1"
    local base_sha=""

    # SHA brut depuis le reflog (pas de référence symbolique textuelle)
    base_sha=$(git reflog "refs/heads/$branch_name" --format="%H" 2>/dev/null | tail -n 1)

    # Fallback : merge-base avec la branche principale
    if [ -z "$base_sha" ]; then
        base_sha=$(git merge-base main "$branch_name" 2>/dev/null)
    fi
    # Fallback ultime : premier commit du dépôt
    if [ -z "$base_sha" ]; then
        base_sha=$(git rev-list --max-parents=0 HEAD 2>/dev/null | head -n 1)
    fi

    echo "$base_sha"
}

# ==============================================================================
# 1. Wrapper Git avec Retry et Backoff Exponentiel
# CORRECTION BLOQUANTE #1 : Retry sur les erreurs de verrou réelles de Git
# CORRECTION AVERTISSEMENT #1 : Recherche de verrous ciblée (pas les worktrees tiers)
# ==============================================================================
git_with_retry() {
    local attempt=1
    local max_attempts=10
    local wait_ms=500
    local output
    local exit_code

    while [ $attempt -le $max_attempts ]; do
        # Répertoire Git commun (partagé entre tous les worktrees du même dépôt)
        local git_dir
        git_dir=$(git rev-parse --git-common-dir 2>/dev/null || echo ".git")

        # CORRECTION : Verrous ciblés sur le dépôt commun — exclure les verrous
        # d'index des worktrees concurrents indépendants (pour ne pas les bloquer)
        local locks=""
        if [ -d "$git_dir" ]; then
            locks=$(find "$git_dir" -maxdepth 2 -name "*.lock" \
                ! -path "$git_dir/worktrees/*/index.lock" 2>/dev/null)
        fi

        # CORRECTION BLOQUANTE #1 : Exécuter la commande et intercepter les erreurs
        output=$(git "$@" 2>&1)
        exit_code=$?

        if [ $exit_code -eq 0 ]; then
            # Succès : afficher la sortie et retourner
            [ -n "$output" ] && echo "$output"
            return 0
        fi

        # Vérifie si l'erreur est liée à un verrou Git (race condition)
        if echo "$output" | grep -qiE "(index\.lock|unable to lock|cannot lock|\.lock' exists)"; then
            echo "Avertissement: Erreur de verrou Git interceptée (tentative $attempt/$max_attempts) :" >&2
            echo "$output" >&2
        elif [ -n "$locks" ]; then
            # Verrous présents sans erreur explicite dans le stdout — attente préventive
            echo "Avertissement: Verrous Git présents, attente préventive (tentative $attempt/$max_attempts)..." >&2
        else
            # Erreur sans rapport avec les verrous — pas de retry, on sort immédiatement
            echo "$output" >&2
            return $exit_code
        fi

        # Dernier essai : diagnostic avancé des PIDs
        if [ $attempt -eq $max_attempts ]; then
            echo "Erreur: Échec persistant après $max_attempts tentatives." >&2
            if command -v lsof >/dev/null 2>&1; then
                for lock in $locks; do
                    local pids
                    pids=$(lsof -t "$lock" 2>/dev/null)
                    if [ -n "$pids" ]; then
                        echo "  PID(s) sur $lock : $pids" >&2
                        ps -fp $pids >&2 || true
                    fi
                done
            fi
            pgrep -fl git >&2 || true
            return 1
        fi

        # Backoff exponentiel plafonné à 2000ms
        local sleep_time
        sleep_time=$(printf "%d.%03d" $((wait_ms / 1000)) $((wait_ms % 1000)))
        sleep "$sleep_time"
        wait_ms=$((wait_ms * 2))
        [ $wait_ms -gt 2000 ] && wait_ms=2000
        attempt=$((attempt + 1))
    done
}

# ==============================================================================
# 2. Fonction setup <task_id> [base_commit]
# ==============================================================================
setup_task() {
    local task_id="$1"
    local base_commit="${2:-HEAD}"

    if [ -z "$task_id" ]; then
        echo "Erreur: task_id est requis. Usage: setup <task_id> [base_commit]" >&2
        return 1
    fi

    # CORRECTION BLOQUANTE #3 : Validation stricte du task_id
    validate_task_id "$task_id" || return 1

    local branch_name="task-$task_id"
    local worktree_dir=".worktrees/$branch_name"

    # Vérifications de conflits préalables
    if git_with_retry show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo "Erreur: La branche $branch_name existe déjà dans le dépôt." >&2
        return 1
    fi

    if [ -d "$worktree_dir" ]; then
        echo "Erreur: Le répertoire $worktree_dir existe déjà." >&2
        return 1
    fi

    # Résolution et validation du commit de base
    local base_sha
    if ! base_sha=$(git_with_retry rev-parse --verify "$base_commit" 2>/dev/null); then
        echo "Erreur: Le commit de base '$base_commit' est invalide." >&2
        return 1
    fi

    # Résolution de HEAD pour la vérification asymétrique
    local head_sha
    head_sha=$(git_with_retry rev-parse --verify HEAD 2>/dev/null)

    # Vérification asymétrique du statut Git
    local git_status
    git_status=$(git_with_retry status --porcelain 2>/dev/null)

    if [ -n "$git_status" ]; then
        if [ "$base_sha" = "$head_sha" ]; then
            echo "Avertissement: Le dépôt principal a des modifications locales non validées." >&2
            echo "La tâche sera isolée sur la base du commit propre ($base_sha)." >&2
        else
            echo "Note: Le dépôt a des modifications, mais la base ($base_commit / $base_sha) diffère de HEAD." >&2
            echo "Le worktree sera configuré sans blocage." >&2
        fi
    fi

    # Création du conteneur de worktrees si absent
    mkdir -p .worktrees

    # Création et rattachement du worktree
    echo "Création du worktree pour la tâche $task_id à partir de $base_commit ($base_sha)..."
    if ! git_with_retry worktree add -b "$branch_name" "$worktree_dir" "$base_sha"; then
        echo "Erreur: Échec de la commande git worktree add." >&2
        return 1
    fi

    echo "Succès: Worktree créé dans $worktree_dir sur la branche $branch_name."
    return 0
}

# ==============================================================================
# 3. Fonction cleanup <task_id> <status>
# ==============================================================================
cleanup_task() {
    local task_id="$1"
    local status="$2"

    if [ -z "$task_id" ] || [ -z "$status" ]; then
        echo "Erreur: task_id et status sont requis. Usage: cleanup <task_id> <SUCCESS|FAILED>" >&2
        return 1
    fi

    # CORRECTION BLOQUANTE #3 : Validation stricte du task_id
    validate_task_id "$task_id" || return 1

    local branch_name="task-$task_id"
    local worktree_dir=".worktrees/$branch_name"

    # Vérification de l'existence du worktree
    if ! git_with_retry worktree list | grep -q "$branch_name"; then
        echo "Erreur: Aucun worktree enregistré pour la tâche $task_id." >&2
        return 1
    fi

    if [ "$status" = "FAILED" ]; then
        echo "Tâche $task_id en échec. Récupération des informations de diagnostic..."

        # CORRECTION BLOQUANTE #2 : SHA brut via get_base_sha()
        local base_commit
        base_commit=$(get_base_sha "$branch_name")

        # Répertoire d'archive
        local archive_dir="$HOME/.agent-output/failed_tasks"
        mkdir -p "$archive_dir"
        local patch_file="$archive_dir/$branch_name.patch"

        # CORRECTION AVERTISSEMENT #2 : Vérification du code de retour du sous-shell
        # CORRECTION AVERTISSEMENT #3 : Pas de git add -A -N pour ne pas altérer l'index
        if [ -d "$worktree_dir" ]; then
            echo "Extraction du diff complet depuis $worktree_dir..."
            local subshell_exit=0
            (
                cd "$worktree_dir" || exit 1
                # Diff des fichiers suivis (sans toucher à l'index)
                git diff "$base_commit" > "$patch_file"
                # Ajout des fichiers non suivis en annexe (sans git add -A -N)
                git ls-files --others --exclude-standard | while IFS= read -r f; do
                    echo "--- /dev/null" >> "$patch_file"
                    echo "+++ b/$f" >> "$patch_file"
                    diff /dev/null "$f" | tail -n +3 | sed 's/^/+/' >> "$patch_file" || true
                done
            ) || subshell_exit=$?

            if [ $subshell_exit -ne 0 ]; then
                echo "Erreur: Échec lors de l'extraction du diff de diagnostic (code: $subshell_exit)." >&2
                return 1
            fi
            echo "Diagnostic archivé avec succès : $patch_file"
        else
            echo "Avertissement: Répertoire $worktree_dir absent. Diff commits uniquement..." >&2
            git_with_retry diff "$base_commit" "$branch_name" > "$patch_file" 2>/dev/null || true
        fi
    fi

    # Suppression physique et logique du worktree
    echo "Suppression du worktree de la tâche $task_id..."
    if ! git_with_retry worktree remove -f "$worktree_dir"; then
        echo "Erreur: Impossible de supprimer le worktree." >&2
        return 1
    fi

    # Suppression de la branche de la tâche
    echo "Suppression de la branche $branch_name..."
    if ! git_with_retry branch -D "$branch_name"; then
        echo "Avertissement: La branche $branch_name n'a pas pu être supprimée." >&2
    fi

    echo "Succès: Nettoyage de la tâche $task_id terminé."
    return 0
}

# ==============================================================================
# 4. Fonction diff <task_id>
# ==============================================================================
diff_task() {
    local task_id="$1"

    if [ -z "$task_id" ]; then
        echo "Erreur: task_id est requis. Usage: diff <task_id>" >&2
        return 1
    fi

    # CORRECTION BLOQUANTE #3 : Validation stricte du task_id
    validate_task_id "$task_id" || return 1

    local branch_name="task-$task_id"
    local worktree_dir=".worktrees/$branch_name"

    # Vérification de l'existence de la branche
    if ! git_with_retry show-ref --verify --quiet "refs/heads/$branch_name"; then
        echo "Erreur: La branche $branch_name n'existe pas." >&2
        return 1
    fi

    # CORRECTION BLOQUANTE #2 : SHA brut via get_base_sha()
    local base_commit
    base_commit=$(get_base_sha "$branch_name")

    if [ -z "$base_commit" ]; then
        echo "Erreur: Impossible de déterminer le commit de base pour la tâche $task_id." >&2
        return 1
    fi

    # CORRECTION AVERTISSEMENT #3 : Pas de git add -A -N (ne pas altérer l'index)
    if [ -d "$worktree_dir" ]; then
        (
            cd "$worktree_dir" || exit 1
            git diff "$base_commit"
        )
    else
        git_with_retry diff "$base_commit" "$branch_name"
    fi
}

# ==============================================================================
# Point d'entrée principal du script
# ==============================================================================
usage() {
    echo "Usage: $0 {setup|cleanup|diff} [arguments]" >&2
    echo "  setup <task_id> [base_commit]" >&2
    echo "  cleanup <task_id> <SUCCESS|FAILED>" >&2
    echo "  diff <task_id>" >&2
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

COMMAND="$1"
shift

case "$COMMAND" in
    setup)
        setup_task "$@"
        ;;
    cleanup)
        cleanup_task "$@"
        ;;
    diff)
        diff_task "$@"
        ;;
    *)
        usage
        ;;
esac
