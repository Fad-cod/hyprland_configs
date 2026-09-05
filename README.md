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

### 🖥️ ambxst Integration
- Custom dock & launcher
- Lockscreen with animations
- Notification system
- Screenshot & screen record
- Wallpapers manager
- Emoji picker
- Notes & Tmux integration

### 📜 Scripts
- **scheme-watcher.sh** - Auto sync colors when wallpaper changes
- **toggle-sleep.sh** - Caffeine mode (prevent sleep)
- **toggle_class_opacity.sh** - Toggle opacity for any app

---

## ⌨️ Keyboard Shortcuts

### ambxst (priority)
| Shortcut | Action |
|----------|--------|
| `Super` | Launcher |
| `Super+D` | Dashboard |
| `Super+A` | Assistant |
| `Super+V` | Clipboard |
| `Super+Shift+O` | Emoji |
| `Super+N` | Notes |
| `Super+Shift+T` | Tmux |
| `Super+,` | Wallpapers |
| `Super+Tab` | Overview |
| `Super+Escape` | Power menu |
| `Super+Shift+C` | Config |
| `Super+L` | Lock screen |
| `Super+S` | Tools |
| `Super+Shift+S` | Screenshot |
| `Super+Shift+R` | Screen record |
| `Super+Shift+A` | Lens |
| `Super+Alt+B` | Reload ambxst |
| `Super+C` | Close window |
| `Super+Z` | Workspace left |
| `Super+X` | Workspace right |
| `Super+1-9` | Go to workspace |
| `Super+Shift+1-9` | Move window to workspace |

### Hyprland extras
| Shortcut | Action |
|----------|--------|
| `Super+T` | Terminal (kitty) |
| `Super+W` | Browser (chromium) |
| `Super+G` | GitHub Desktop |
| `Super+E` | Dolphin |
| `Super+Alt+E` | Nemo |
| `Super+Shift+H` | Color picker |
| `Ctrl+Shift+Escape` | System monitor (btop) |
| `Ctrl+Alt+V` | Volume control |
| `Ctrl+Shift+Alt+V` | Clipboard paste |
| `Super+O` | Toggle opacity |
| `Super+Ctrl+B` | Caffeine mode |
| `Super+Shift+L` | Sleep/Suspend |

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

**crafted for those who live in the terminal**

</div>
