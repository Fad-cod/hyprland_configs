#!/bin/bash
# Preload Dolphin at login: keeps a hidden instance warm so that
# opening Dolphin later is instant (single-instance reuses the process).
sleep 3 # let Hyprland settle
dolphin --new-window ~ >/dev/null 2>&1 &
for i in $(seq 1 40); do
  if hyprctl clients 2>/dev/null | grep -q "initialClass: org.kde.dolphin"; then
    sleep 1 # let thumbnails/workers settle
    # Atomic move with window selector (hl Lua dispatch syntax)
    hyprctl dispatch 'hl.dsp.window.move({workspace="special:dolphin", window="class:org.kde.dolphin"})' >/dev/null 2>&1
    exit 0
  fi
  sleep 0.25
done
