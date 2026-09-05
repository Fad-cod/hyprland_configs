#!/bin/bash

# Watcher de couleurs ambxst — hybride inotify/polling
# Utilise inotifywait si disponible (événementiel, instantané, 0% CPU idle)
# Sinon, fallback sur stat toutes les 1s (zéro dépendance, universel)

COLORS="$HOME/.cache/ambxst/colors.json"
SCHEME_SCRIPT="$HOME/.config/hypr/scripts/generate-scheme.sh"

# Attendre que colors.json existe (ambxst peut prendre un moment au démarrage)
while [ ! -f "$COLORS" ]; do
  sleep 1
done

# Génération initiale au démarrage
"$SCHEME_SCRIPT"
hyprctl reload

# --- Détection de inotifywait ---
if command -v inotifywait &>/dev/null; then
  # Mode événementiel : 0% CPU, instantané
  # Boucle infinie : même si inotifywait échoue (fichier supprimé/recréé),
  # le watcher redémarre automatiquement au lieu de mourir silencieusement
  while true; do
    inotifywait -qq -e close_write "$COLORS" 2>/dev/null
    sleep 0.3
    if "$SCHEME_SCRIPT"; then
      hyprctl reload
    fi
  done
fi

# --- Fallback polling ---
echo "scheme-watcher: inotifywait introuvable, fallback polling 1s" >&2

LAST_MTIME=$(stat -c %Y "$COLORS" 2>/dev/null || echo 0)

while true; do
  sleep 1
  NEW_MTIME=$(stat -c %Y "$COLORS" 2>/dev/null)
  if [ -n "$NEW_MTIME" ] && [ "$NEW_MTIME" != "$LAST_MTIME" ]; then
    LAST_MTIME=$NEW_MTIME
    if "$SCHEME_SCRIPT"; then
      hyprctl reload
    fi
  fi
done
