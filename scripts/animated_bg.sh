#!/bin/bash
# Script pour lancer un fond d'écran animé avec mpvpaper

# Vidéo par défaut si aucun argument n'est fourni
DEFAULT_VIDEO="$HOME/Vidéos/from-klickpin-cf-see-these-18-stunning-travel-packing-tips-that-help-you-create_ClDrOFCx.mp4"

# Utilise l'argument si présent, sinon la vidéo par défaut
VIDEO_PATH="${1:-$DEFAULT_VIDEO}"

# Vérifier si le fichier existe
if [ ! -f "$VIDEO_PATH" ]; then
    echo "Erreur : Le fichier '$VIDEO_PATH' n'existe pas."
    exit 1
fi

# Tuer l'instance précédente
pkill mpvpaper

# Lancer le nouveau fond d'écran
mpvpaper -o "no-audio --loop" '*' "$VIDEO_PATH" &
echo "Fond d'écran animé lancé avec : $VIDEO_PATH"
