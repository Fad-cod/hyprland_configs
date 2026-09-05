#!/usr/bin/env bash

# Toggle Sleep — Inhibe ou rétablit la mise en veille du système
# Utilise systemd-inhibit pour bloquer sleep/suspend/idle
# Bascule aussi le mode Caffeine d'ambxst pour désactiver le lockscreen
# Un fichier PID permet de tracker l'état actif

PIDFILE="/tmp/toggle-sleep.pid"
INHIBIT_WHAT="sleep:idle"
INHIBIT_WHO="Toggle Sleep (Super+Ctrl+B)"
INHIBIT_WHY="Inhibition manuelle par l'utilisateur"
AMBXST_STATE="$HOME/.local/state/ambxst/states.json"
LOGINLOCK_PIDFILE="/tmp/loginlock.pid"

# ─── Fonctions ──────────────────────────────────────────────────────────────

toggle_ambxst_caffeine() {
    local enable="$1"  # "true" ou "false"

    # Modifier le fichier state d'ambxst pour le mode caffeine
    if [ -f "$AMBXST_STATE" ]; then
        jq --arg val "$enable" '.caffeine = ($val == "true")' "$AMBXST_STATE" > "${AMBXST_STATE}.tmp" && \
            mv "${AMBXST_STATE}.tmp" "$AMBXST_STATE" && \
            return 0
    fi
    return 1
}

# ─── Désactivation de l'inhibition ──────────────────────────────────────────

if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        # Inhibition active → on la tue
        kill "$OLD_PID" 2>/dev/null
        rm -f "$PIDFILE"

        # Désactiver le mode caffeine ambxst (lockscreen normal)
        toggle_ambxst_caffeine "false" || true

        # Relancer loginlock.sh si on l'avait tué
        if [ -f "$LOGINLOCK_PIDFILE" ]; then
            OLD_LOCKPID=$(cat "$LOGINLOCK_PIDFILE")
            if kill -0 "$OLD_LOCKPID" 2>/dev/null; then
                kill "$OLD_LOCKPID" 2>/dev/null || true
            fi
            rm -f "$LOGINLOCK_PIDFILE"
        fi
        if [ -x "$HOME/.local/src/ambxst/scripts/loginlock.sh" ]; then
            nohup bash "$HOME/.local/src/ambxst/scripts/loginlock.sh" >/dev/null 2>&1 &
            echo $! > "$LOGINLOCK_PIDFILE"
        fi

        notify-send "Veille" "✅ Veille normale rétablie — lockscreen réactivé" \
            -i dialog-information \
            -t 3000
        exit 0
    else
        # PID mort, fichier orphelin → nettoyage
        rm -f "$PIDFILE"
    fi
fi

# ─── Activation de l'inhibition ────────────────────────────────────────────

# Tuer loginlock.sh pour éviter le verrouillage par D-Bus
if [ -x "$HOME/.local/src/ambxst/scripts/loginlock.sh" ]; then
    LOCKPID=$(pgrep -f loginlock.sh 2>/dev/null | head -1)
    if [ -n "$LOCKPID" ]; then
        kill "$LOCKPID" 2>/dev/null || true
        echo "$LOCKPID" > "$LOGINLOCK_PIDFILE"
    fi
fi

# Activer le mode caffeine ambxst (désactiver lockscreen)
toggle_ambxst_caffeine "true" || true

# Lance l'inhibition en arrière-plan
systemd-inhibit \
    --what="$INHIBIT_WHAT" \
    --who="$INHIBIT_WHO" \
    --why="$INHIBIT_WHY" \
    --mode=block \
    sleep infinity &

INHIBIT_PID=$!
echo "$INHIBIT_PID" > "$PIDFILE"

# Vérifie rapidement que le processus tourne
sleep 0.3
if kill -0 "$INHIBIT_PID" 2>/dev/null; then
    notify-send "Veille" "🛑 Veille + lockscreen désactivés (inhibition active)" \
        -i dialog-warning \
        -t 3000
else
    rm -f "$PIDFILE"
    notify-send "Veille" "❌ Échec de l'inhibition" \
        -i dialog-error \
        -t 3000
    exit 1
fi
