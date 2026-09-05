#!/bin/bash
STATE_FILE="/home/fadele/.local/state/ambxst/states.json"
BIND_FILE="/home/fadele/.config/hypr/hyprland/layout_bind.lua"

update_bind() {
    layout=$(grep -oP '"compositorLayout":"\K[^"]+' "$STATE_FILE" 2>/dev/null)
    if [ "$layout" = "scrolling" ]; then
        echo 'hl.bind("SUPER + F", hl.dsp.layout("colresize 1.0"))' > "$BIND_FILE"
    else
        echo 'hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "set" }))' > "$BIND_FILE"
    fi
    hyprctl reload
}

sleep 2
update_bind

if ! command -v inotifywait &>/dev/null; then
    exit 1
fi

while true; do
    inotifywait -e modify "$STATE_FILE" 2>/dev/null
    update_bind
done
