#!/usr/bin/env bash

CLASS=$(hyprctl activewindow -j | jq -r '.class')

if [ -z "$CLASS" ] || [ "$CLASS" == "null" ]; then
    notify-send "Opacity Toggle" "No active window or class found"
    exit 1
fi

LUA_FILE="$HOME/.config/hypr/hyprland/opaque_classes.lua"
touch "$LUA_FILE"

# The rule we want to add (single-line pour un grep/remove simple)
SAFE_NAME=$(printf '%s' "$CLASS" | sed 's/[^a-zA-Z0-9_]/_/g')
RULE="hl.window_rule({ name = \"opacity_0_85_${SAFE_NAME}\", match = { class = \"^(${CLASS})\$\" }, opacity = \"0.85 override 0.85 override\" })"

# Check if the rule already exists
if grep -qF "$RULE" "$LUA_FILE"; then
    # Remove the rule
    grep -vF "$RULE" "$LUA_FILE" > "${LUA_FILE}.tmp"
    mv "${LUA_FILE}.tmp" "$LUA_FILE"
    notify-send "Opacity Toggle" "Removed opacity 0.85 (restored default 1.0) for class: $CLASS"
else
    # Add the rule
    echo "$RULE" >> "$LUA_FILE"
    notify-send "Opacity Toggle" "Set opacity 0.85 for class: $CLASS"
fi

# Reload hyprland config
hyprctl reload
