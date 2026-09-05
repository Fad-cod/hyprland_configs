# Hyprland Configuration

## Files Structure
- `hyprland.conf` - Main config entry point (sources everything)
- `hyprland.lua` - Main Lua config (source files)
- `hyprland/` - All module configs (.lua and .conf)
- `scheme/` - Color scheme files
- `scripts/` - Shell scripts
- `ambxst*.conf` - ambxst base configs

## Installation
1. Copy files to `~/.config/hypr/`
2. Copy ambxst configs to `~/.local/share/ambxst/`
3. Make scripts executable: `chmod +x scripts/*`

## Dependencies
- ambxst (custom dock/lockscreen/etc.)
- pywal for color schemes
- hyprland
