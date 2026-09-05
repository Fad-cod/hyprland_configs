#!/bin/bash
# Hyprland Config Installer

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HYPR_DIR="$HOME/.config/hypr"
AMBXST_DIR="$HOME/.local/share/ambxst"

echo "Installing Hyprland config..."

# Create directories
mkdir -p "$HYPR_DIR/hyprland"
mkdir -p "$HYPR_DIR/scheme"
mkdir -p "$HYPR_DIR/scripts"
mkdir -p "$AMBXST_DIR"

# Copy main configs
cp "$SCRIPT_DIR/hyprland.conf" "$HYPR_DIR/"
cp "$SCRIPT_DIR/hyprland.lua" "$HYPR_DIR/"
cp "$SCRIPT_DIR/variables.conf" "$HYPR_DIR/"

# Copy module configs
cp "$SCRIPT_DIR"/*.lua "$HYPR_DIR/hyprland/"
cp "$SCRIPT_DIR"/*.conf "$HYPR_DIR/hyprland/"

# Copy scheme files
cp "$SCRIPT_DIR/scheme/"* "$HYPR_DIR/scheme/"

# Copy scripts
cp "$SCRIPT_DIR/scripts/"* "$HYPR_DIR/scripts/"
chmod +x "$HYPR_DIR/scripts/"*

# Copy ambxst configs
cp "$SCRIPT_DIR/ambxst"*.conf "$AMBXST_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/ambxst"*.lua "$AMBXST_DIR/" 2>/dev/null || true

echo "Done! Config installed to $HYPR_DIR"
echo "Restart Hyprland to apply changes."
