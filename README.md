<div align="center">

# 🌙 Hyprland Config

**A clean, modular Hyprland configuration with Lua support**

[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-blue?style=flat-square)](https://hyprland.org)
[![Lua](https://img.shields.io/badge/Lua-5.4-orange?style=flat-square)](https://www.lua.org)

---

</div>

## 🚀 Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/Fad-cod/hyprland_configs/main/install.sh | bash
```

---

## ✨ What You Get

### 🎨 Visual
- **Material You colors** - Dynamic palette from your wallpaper
- **Blur effects** - Configurable glass-like windows
- **20px rounded corners** - Modern window styling
- **Per-app opacity** - Toggle opacity on any app
- **Sweet cursors** - Beautiful cursor theme

### 🖥️ ambxst Integration
- Custom dock
- Lockscreen with animations
- Notification system
- App launcher
- Auto color sync from wallpaper

---

## ⌨️ Keyboard Shortcuts

### Apps
| Shortcut | Action |
|----------|--------|
| `Super+T` | Terminal (kitty) |
| `Super+W` | Browser (chromium) |
| `Super+C` | Editor (VS Code) |
| `Super+E` | File Explorer (dolphin) |
| `Super+G` | GitHub Desktop |

### Window Management
| Shortcut | Action |
|----------|--------|
| `Super+Q` | Close window |
| `Super+F` | Fullscreen toggle |
| `Super+Space` | Toggle floating |
| `Super+Z` | Move window |
| `Super+X` | Resize window |
| `Super+P` | Pin window |

### Workspaces
| Shortcut | Action |
|----------|--------|
| `Ctrl+Super+Left/Right` | Switch workspace |
| `Super+PageUp/PageDown` | Switch workspace |
| `Super+Alt+PageUp/PageDown` | Move window to workspace |
| `Super+S` | Toggle special workspace |
| `Super+M` | Music workspace |
| `Super+D` | Communication workspace |
| `Super+R` | Todo workspace |

### Window Groups
| Shortcut | Action |
|----------|--------|
| `Alt+Tab` | Cycle windows in group |
| `Super+Comma` | Toggle group |
| `Super+U` | Ungroup window |

### Utilities
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+Alt+V` | Clipboard history |
| `Ctrl+Alt+V` | Volume control |
| `Ctrl+Shift+Escape` | System monitor (btop) |
| `Super+Shift+H` | Color picker |
| `Super+L` | Lock screen |
| `Super+Shift+L` | Sleep/Suspend |
| `Super+Ctrl+B` | Caffeine mode (prevent sleep) |
| `Super+O` | Toggle window opacity |

---

## 📜 Scripts

| Script | Shortcut | Description |
|--------|----------|-------------|
| `toggle-sleep.sh` | `Super+Ctrl+B` | Toggle sleep inhibition (caffeine mode) |
| `toggle_class_opacity.sh` | `Super+O` | Toggle opacity for current app |
| `scheme-watcher.sh` | Auto | Sync colors when wallpaper changes |
| `generate-scheme.sh` | Auto | Generate Material You colors |
| `layout_bind_watcher.sh` | Auto | Update shortcuts based on layout |

---

## 📁 What's Inside

```
hyprland_configs/
├── hyprland.conf          # Main entry point
├── hyprland.lua           # Lua config loader
├── variables.conf         # Custom variables
├── install.sh            # One-click installer
│
├── hyprland/             # Module configs
│   ├── animations.*      # Animation settings
│   ├── decoration.*      # Window decoration
│   ├── keybinds.*        # Keyboard shortcuts
│   ├── rules.*           # Window rules
│   └── ...               # More modules
│
├── scheme/               # Color schemes
│   ├── current.*         # Active scheme
│   └── default.*         # Fallback scheme
│
└── scripts/              # Helper scripts
    ├── generate-scheme.sh
    ├── scheme-watcher.sh
    └── ...
```

---

## 🎨 Customization

Edit `variables.conf` to change:
- Default apps (terminal, browser, editor)
- Touchpad settings
- Blur and shadow options
- Window gaps and rounding
- All keybinds

---

<div align="center">

**Made with 💜 for the Hyprland community**

</div>
