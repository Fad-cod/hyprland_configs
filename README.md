<div align="center">

# 🌙 Hyprland Config

**A clean, modular Hyprland configuration with Lua support**

[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-blue?style=flat-square)](https://hyprland.org)
[![Lua](https://img.shields.io/badge/Lua-5.4-orange?style=flat-square)](https://www.lua.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](#)

---

</div>

## ✨ Features

- 🎨 **Modular Lua configs** - Clean, readable configuration
- 🎭 **Dynamic color schemes** - pywal integration for automatic theming
- ⚡ **Optimized keybinds** - Efficient workflow shortcuts
- 🖼️ **ambxst integration** - Dock, lockscreen, notifications & more

## 🚀 Quick Install

Copy-paste this single command:

```bash
curl -sSL https://raw.githubusercontent.com/Fad-cod/hyprland_configs/main/install.sh | bash
```

<br>

<details>
<summary><b>📦 Manual Installation</b></summary>

```bash
# Clone the repo
git clone https://github.com/Fad-cod/hyprland_configs.git
cd hyprland_configs

# Run installer
chmod +x install.sh
./install.sh
```

</details>

<br>

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

## 🎨 Customization

| File | Purpose |
|------|---------|
| `variables.conf` | Change apps, keybinds, colors |
| `scheme/default.conf` | Default color palette |
| `hyprland/keybinds.conf` | Keyboard shortcuts |

## 📋 Requirements

- [Hyprland](https://hyprland.org) - Window manager
- [pywal](https://github.com/dylanaraps/pywal) - Color schemes *(optional)*
- [ambxst](https://github.com/ambxst) - Desktop components *(optional)*

## 🤝 Contributing

Feel free to open issues or submit PRs!

---

<div align="center">

**Made with 💜 for the Hyprland community**

</div>
