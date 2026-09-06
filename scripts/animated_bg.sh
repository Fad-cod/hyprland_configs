#!/bin/bash
# Animated wallpaper script using mpvpaper
# Usage: animated_bg.sh /path/to/video.mp4

if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/video.mp4"
    echo "Example: $0 ~/Videos/my-wallpaper.mp4"
    exit 1
fi

VIDEO_PATH="$1"

if [ ! -f "$VIDEO_PATH" ]; then
    echo "Error: '$VIDEO_PATH' not found"
    exit 1
fi

pkill mpvpaper

mpvpaper -o "no-audio --loop" '*' "$VIDEO_PATH" &
echo "Animated wallpaper: $VIDEO_PATH"
