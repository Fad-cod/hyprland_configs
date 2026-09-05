#!/usr/bin/env bash

# update-system.sh — Mise à jour système Arch Linux robuste
# Usage : ./update-system.sh
#
# Fonctionnalités :
# - Rafraîchit les mirrors (pacman -Sy)
# - Télécharge TOUS les paquets avant d'installer (sépare download et install)
# - Boucle de retry si le réseau coupe ou si pacman est interrompu
# - Inhibe la veille pendant toute l'opération
# - Logs datés dans /tmp/

set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────

LOGFILE="/tmp/update-system-$(date +%Y%m%d-%H%M%S).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
MAX_RETRIES=10
RETRY_DELAY=10
TOGGLE_SLEEP="$HOME/.config/hypr/scripts/toggle-sleep.sh"

# ─── Fonctions ──────────────────────────────────────────────────────────────

notify() {
    notify-send "$@" 2>/dev/null || true
}

log() {
    local msg="[$(date '+%H:%M:%S')] $*"
    echo "$msg" | tee -a "$LOGFILE"
}

die() {
    log "❌ ERREUR: $*"
    [ -f /tmp/toggle-sleep.pid ] && "$TOGGLE_SLEEP" 2>/dev/null || true
    exit 1
}

cleanup() {
    log "🧹 Nettoyage..."
    if [ -f /tmp/toggle-sleep.pid ]; then
        "$TOGGLE_SLEEP" 2>/dev/null || true
        log "🔓 Inhibition veille désactivée"
    fi
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

retry() {
    local cmd="$*"
    local attempt=1
    local exit_code=0

    while [ $attempt -le "$MAX_RETRIES" ]; do
        log "🔄 Tentative $attempt/$MAX_RETRIES : $(echo "$cmd" | head -c 120)"
        # bash -c n'hérite pas de pipefail → on le passe explicitement
        if bash -c "set -o pipefail; $cmd"; then
            log "✅ Succès (tentative $attempt)"
            return 0
        fi
        exit_code=$?
        log "⚠️  Échec (code $exit_code) — tentative $attempt/$MAX_RETRIES"

        if [ $attempt -lt "$MAX_RETRIES" ]; then
            log "⏳ Attente ${RETRY_DELAY}s avant nouvelle tentative..."
            sleep "$RETRY_DELAY"
        fi
        ((attempt++)) || true
    done

    log "❌ Échec après $MAX_RETRIES tentatives"
    return "$exit_code"
}

# ─── Début du script ───────────────────────────────────────────────────────

notify "Mise à jour" "🔄 Début de la mise à jour système — logs dans $LOGFILE" -t 5000

{
    echo "╔══════════════════════════════════════════════╗"
    echo "║        Mise à jour système Arch Linux        ║"
    echo "╚══════════════════════════════════════════════╝"
} >> "$LOGFILE"

log "Début: $TIMESTAMP"
log "Log: $LOGFILE"
log ""

# Vérification connexion réseau
if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
    die "Aucune connexion Internet détectée. Vérifie le réseau avant de relancer."
fi

# Vérification que pacman n'est pas déjà en cours d'utilisation
if [ -f /var/lib/pacman/db.lck ]; then
    die "pacman est déjà utilisé (db.lck présent). Fermez l'autre instance pacman."
fi

# ─── Activation inhibition veille ───────────────────────────────────────────

log "🛑 Activation de l'inhibition de veille..."
if [ -f "$TOGGLE_SLEEP" ]; then
    if [ ! -f /tmp/toggle-sleep.pid ]; then
        "$TOGGLE_SLEEP" 2>/dev/null || log "⚠️  Impossible d'activer l'inhibition — on continue quand même"
    else
        log "ℹ️  Inhibition déjà active"
    fi
else
    log "⚠️  Script toggle-sleep.sh non trouvé — on continue sans inhibition"
fi

trap cleanup EXIT

# ─── 1. Rafraîchissement des mirrors ───────────────────────────────────────

log ""
log "📡 Étape 1/5 : Rafraîchissement des mirrors..."
log "──────────────────────────────────────────"
retry "sudo pacman -Sy >> '$LOGFILE' 2>&1"

# ─── 2. Vérification des mises à jour disponibles ───────────────────────────

log ""
log "🔍 Étape 2/5 : Vérification des paquets à mettre à jour..."
log "──────────────────────────────────────────────────────────"

PACKAGES=$(pacman -Quq 2>/dev/null || true)
if [ -z "$PACKAGES" ]; then
    log "🎉 Le système est déjà à jour !"
    notify "Mise à jour" "✅ Système déjà à jour !" -t 5000
    exit 0
fi

PKG_COUNT=$(echo "$PACKAGES" | wc -l)
log "📦 $PKG_COUNT paquets à mettre à jour"
notify "Mise à jour" "📦 $PKG_COUNT paquets à mettre à jour — téléchargement..." -t 5000

# ─── 3. Téléchargement des paquets ─────────────────────────────────────────

log ""
log "⬇️  Étape 3/5 : Téléchargement des paquets..."
log "──────────────────────────────────────────────"

DOWNLOAD_LIST=$(echo "$PACKAGES" | tr '\n' ' ')
retry "sudo pacman -Sw --noconfirm --needed $DOWNLOAD_LIST >> '$LOGFILE' 2>&1"

# ─── 4. Installation des paquets ────────────────────────────────────────────

log ""
log "⚙️  Étape 4/5 : Installation des mises à jour..."
log "────────────────────────────────────────────────"

retry "sudo pacman -Su --noconfirm >> '$LOGFILE' 2>&1"

# ─── 5. Nettoyage post-mise à jour ──────────────────────────────────────────

log ""
log "🧹 Étape 5/5 : Nettoyage du système..."
log "──────────────────────────────────────"

# Suppression des paquets orphelins
ORPHANS=$(pacman -Qtdq 2>/dev/null || true)
if [ -n "$ORPHANS" ]; then
    ORPHAN_COUNT=$(echo "$ORPHANS" | wc -l)
    log "🗑️  Suppression de $ORPHAN_COUNT paquets orphelins..."
    echo "$ORPHANS" >> "$LOGFILE"
    sudo pacman -Rns --noconfirm $ORPHANS >> "$LOGFILE" 2>&1 && log "✅ Paquets orphelins supprimés" || log "⚠️  Échec suppression orphelins"
else
    log "✅ Aucun paquet orphelin"
fi

# Nettoyage du cache pacman (garde les 2 dernières versions)
if command -v paccache &>/dev/null; then
    log "📦 Nettoyage du cache pacman (garde 2 versions)..."
    sudo paccache -rk2 >> "$LOGFILE" 2>&1 && log "✅ Cache nettoyé" || log "⚠️  Échec nettoyage cache"
else
    log "⚠️  paccache non installé (pacman-contrib manquant)"
fi

# ─── Fin ────────────────────────────────────────────────────────────────────

log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "✅ Mise à jour terminée avec succès !"
log "   → Log: $LOGFILE"
notify "Mise à jour" "✅ Mise à jour système terminée avec succès ! (logs: $LOGFILE)" -t 10000
