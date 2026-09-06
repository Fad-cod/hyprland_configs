#!/bin/bash
# Hyprland Config Installer

set -e

# Colors & Styles
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
WHITE='\033[37m'
BG_BLACK='\033[40m'
RESET='\033[0m'

# Config
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HYPR_DIR="$HOME/.config/hypr"
AMBXST_DIR="$HOME/.local/share/ambxst"

# Spinner animation
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while kill -0 "$pid" 2>/dev/null; do
        for (( i=0; i<${#spinstr}; i++ )); do
            printf "\r    ${CYAN}${spinstr:$i:1}${RESET} "
            sleep $delay
        done
    done
    printf "\r"
}

# Print functions
print_logo() {
    clear
    echo ""
    echo -e "${MAGENTA}${BOLD}"
    echo "    ┌─────────────────────────────────────────────────────────────┐"
    echo "    │                                                             │"
    echo "    │     █████╗  ███╗   ███╗ ██████╗  ██╗  ██╗ ███████╗ ████████╗│"
    echo "    │    ██╔══██╗ ████╗ ████║ ██╔══██╗ ╚██╗██╔╝ ██╔════╝ ╚══██╔══╝│"
    echo "    │    ███████║ ██╔████╔██║ ██████╔╝  ╚███╔╝  ███████╗    ██║   │"
    echo "    │    ██╔══██║ ██║╚██╔╝██║ ██╔══██╗  ██╔██╗  ╚════██║    ██║   │"
    echo "    │    ██║  ██║ ██║ ╚═╝ ██║ ██████╔╝ ██╔╝ ██╗ ███████║    ██║   │"
    echo "    │    ╚═╝  ╚═╝ ╚═╝     ╚═╝ ╚═════╝  ╚═╝  ╚═╝ ╚══════╝    ╚═╝   │"
    echo "    │                                                             │"
    echo "    │                  ✦ Config Installer v1.0 ✦                  │"
    echo "    │                                                             │"
    echo "    └─────────────────────────────────────────────────────────────┘"
    echo -e "${RESET}"
    echo ""
    echo -e "    ${DIM}${ITALIC}A beautiful setup for a beautiful desktop${RESET}"
    echo ""
}

print_header() {
    echo ""
    echo -e "${MAGENTA}${BOLD}    ╭──────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "${MAGENTA}${BOLD}    │${RESET}  ${CYAN}${BOLD}${1}${RESET}"
    echo -e "${MAGENTA}${BOLD}    ╰──────────────────────────────────────────────────────────────╯${RESET}"
    echo ""
}

print_step() {
    echo -e "    ${GREEN}${BOLD}▸${RESET} ${WHITE}${BOLD}${1}${RESET}"
}

print_info() {
    echo -e "      ${CYAN}◆${RESET} ${DIM}${1}${RESET}"
}

print_success() {
    echo -e "      ${GREEN}${BOLD}✔${RESET} ${GREEN}${1}${RESET}"
}

print_warning() {
    echo -e "      ${YELLOW}${BOLD}⚠${RESET} ${YELLOW}${1}${RESET}"
}

print_error() {
    echo -e "      ${RED}${BOLD}✖${RESET} ${RED}${1}${RESET}"
}

print_progress() {
    local width=40
    local percent=$1
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    printf "\r      ${CYAN}["
    printf "%0.s━" $(seq 1 $filled 2>/dev/null) || true
    if [ $filled -lt $width ]; then
        printf "${DIM}DownList"
        printf "%0.s─" $(seq 1 $empty 2>/dev/null) || true
    fi
    printf "${CYAN}]${RESET} ${BOLD}%3d%%${RESET}" $percent
}

print_section() {
    echo ""
    echo -e "    ${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "    ${MAGENTA}${BOLD}  ${1}${RESET}"
    echo -e "    ${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

# Check if package is installed
is_installed() {
    local pkg="$1"
    command -v "$pkg" &> /dev/null && return 0
    command -v pacman &> /dev/null && pacman -Qi "$pkg" &> /dev/null 2>&1 && return 0
    command -v apt &> /dev/null && dpkg -l "$pkg" 2>/dev/null | grep -q "^ii" && return 0
    command -v dnf &> /dev/null && dnf list installed "$pkg" &> /dev/null 2>&1 && return 0
    command -v zypper &> /dev/null && zypper se -i "$pkg" &> /dev/null 2>&1 && return 0
    return 1
}

# Main installation
main() {
    print_logo
    
    print_header "INITIALIZING"
    print_step "Checking system..."
    sleep 0.3
    
    # Detect package manager
    if command -v pacman &> /dev/null; then
        PKG_MGR="pacman"
        PKG_INSTALL="sudo pacman -S --noconfirm"
        
        # Check for AUR helper
        if command -v yay &> /dev/null; then
            AUR_HELPER="yay"
            AUR_INSTALL="yay -S --noconfirm"
        elif command -v paru &> /dev/null; then
            AUR_HELPER="paru"
            AUR_INSTALL="paru -S --noconfirm"
        else
            AUR_HELPER=""
            AUR_INSTALL=""
            print_warning "No AUR helper found"
            print_info "Installing yay..."
            
            cd /tmp
            git clone https://aur.archlinux.org/yay.git &>/dev/null
            cd yay
            makepkg -si --noconfirm &>/dev/null || print_error "Could not install yay"
            cd ~
            
            if command -v yay &> /dev/null; then
                AUR_HELPER="yay"
                AUR_INSTALL="yay -S --noconfirm"
                print_success "yay installed"
            else
                print_error "yay installation failed"
            fi
        fi
    elif command -v apt &> /dev/null; then
        PKG_MGR="apt"
        PKG_INSTALL="sudo apt install -y"
    elif command -v dnf &> /dev/null; then
        PKG_MGR="dnf"
        PKG_INSTALL="sudo dnf install -y"
    elif command -v zypper &> /dev/null; then
        PKG_MGR="zypper"
        PKG_INSTALL="sudo zypper install -y"
    else
        print_error "Unknown package manager"
        PKG_MGR="unknown"
    fi
    
    print_success "System: ${CYAN}$PKG_MGR${RESET}"
    [ -n "$AUR_HELPER" ] && print_success "AUR: ${CYAN}$AUR_HELPER${RESET}"
    sleep 0.3
    
    print_header "DEPENDENCIES"
    
    # List of required dependencies
    DEPS=(
        "hyprland"
        "jq"
        "curl"
        "wget"
        "git"
        "python"
        "fish"
        "nodejs"
        "npm"
        "dunst"
        "wl-clipboard"
        "brightnessctl"
        "playerctl"
        "pavucontrol"
        "network-manager-applet"
        "file-roller"
        "thunar"
        "qt5-wayland"
        "qt6-wayland"
    )
    
    # AUR packages (if yay/paru available)
    AUR_DEPS=(
        "pywal"
    )
    
    MISSING_DEPS=()
    MISSING_AUR=()
    
    # Check each dependency
    for dep in "${DEPS[@]}"; do
        if is_installed "$dep"; then
            print_success "$dep"
        else
            print_warning "$dep"
            MISSING_DEPS+=("$dep")
        fi
    done
    
    # Check AUR dependencies
    if [ -n "$AUR_HELPER" ]; then
        for dep in "${AUR_DEPS[@]}"; do
            if is_installed "$dep"; then
                print_success "$dep"
            else
                print_warning "$dep (AUR)"
                MISSING_AUR+=("$dep")
            fi
        done
    fi
    
    sleep 0.2
    
    # Install missing dependencies
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        print_header "INSTALLING PACKAGES"
        
        for dep in "${MISSING_DEPS[@]}"; do
            print_step "Installing $dep..."
            ($PKG_INSTALL "$dep" &>/dev/null) &
            spinner $!
            print_success "$dep"
        done
    fi
    
    # Install missing AUR dependencies
    if [ ${#MISSING_AUR[@]} -gt 0 ] && [ -n "$AUR_HELPER" ]; then
        print_header "INSTALLING AUR PACKAGES"
        
        for dep in "${MISSING_AUR[@]}"; do
            print_step "Installing $dep..."
            ($AUR_INSTALL "$dep" &>/dev/null) &
            spinner $!
            print_success "$dep"
        done
    fi
    
    print_header "SETTING UP DIRECTORIES"
    
    mkdir -p "$HYPR_DIR/hyprland"
    mkdir -p "$HYPR_DIR/scheme"
    mkdir -p "$HYPR_DIR/scripts"
    mkdir -p "$AMBXST_DIR"
    
    print_success "Directory structure created"
    sleep 0.2
    
    print_header "INSTALLING CONFIGURATION"
    
    # Count total files first
    TOTAL_FILES=0
    for file in "$SCRIPT_DIR"/*.lua "$SCRIPT_DIR"/*.conf; do
        [ -f "$file" ] && TOTAL_FILES=$((TOTAL_FILES + 1))
    done
    for file in "$SCRIPT_DIR/scheme/"*; do
        [ -f "$file" ] && TOTAL_FILES=$((TOTAL_FILES + 1))
    done
    for file in "$SCRIPT_DIR/scripts/"*; do
        [ -f "$file" ] && TOTAL_FILES=$((TOTAL_FILES + 1))
    done
    for file in "$SCRIPT_DIR"/ambxst*.conf "$SCRIPT_DIR"/ambxst*.lua; do
        [ -f "$file" ] && TOTAL_FILES=$((TOTAL_FILES + 1))
    done 2>/dev/null || true
    
    CURRENT_FILE=0
    
    # Copy main configs
    for file in hyprland.conf hyprland.lua variables.conf; do
        if [ -f "$SCRIPT_DIR/$file" ]; then
            cp "$SCRIPT_DIR/$file" "$HYPR_DIR/"
            CURRENT_FILE=$((CURRENT_FILE + 1))
            print_progress $((CURRENT_FILE * 100 / TOTAL_FILES))
            sleep 0.03
        fi
    done
    
    # Copy module configs
    for file in "$SCRIPT_DIR"/*.lua "$SCRIPT_DIR"/*.conf; do
        if [ -f "$file" ] && [ "$(basename "$file")" != "hyprland.conf" ] && [ "$(basename "$file")" != "hyprland.lua" ] && [ "$(basename "$file")" != "variables.conf" ]; then
            cp "$file" "$HYPR_DIR/hyprland/"
            CURRENT_FILE=$((CURRENT_FILE + 1))
            print_progress $((CURRENT_FILE * 100 / TOTAL_FILES))
            sleep 0.03
        fi
    done
    
    # Copy scheme files
    for file in "$SCRIPT_DIR/scheme/"*; do
        if [ -f "$file" ]; then
            cp "$file" "$HYPR_DIR/scheme/"
            CURRENT_FILE=$((CURRENT_FILE + 1))
            print_progress $((CURRENT_FILE * 100 / TOTAL_FILES))
            sleep 0.03
        fi
    done
    
    # Copy scripts
    for file in "$SCRIPT_DIR/scripts/"*; do
        if [ -f "$file" ]; then
            cp "$file" "$HYPR_DIR/scripts/"
            chmod +x "$HYPR_DIR/scripts/$(basename "$file")"
            CURRENT_FILE=$((CURRENT_FILE + 1))
            print_progress $((CURRENT_FILE * 100 / TOTAL_FILES))
            sleep 0.03
        fi
    done
    
    # Copy ambxst configs
    for file in "$SCRIPT_DIR"/ambxst*.conf "$SCRIPT_DIR"/ambxst*.lua; do
        if [ -f "$file" ]; then
            cp "$file" "$AMBXST_DIR/"
            CURRENT_FILE=$((CURRENT_FILE + 1))
            print_progress $((CURRENT_FILE * 100 / TOTAL_FILES))
            sleep 0.03
        fi
    done 2>/dev/null || true
    
    echo ""
    echo ""
    print_success "All files installed!"
    
    print_header "RELOADING SERVICES"
    
    # Reload Hyprland
    print_step "Reloading Hyprland..."
    hyprctl reload &>/dev/null && print_success "Hyprland reloaded" || print_warning "Restart manually"
    
    # Reload ambxst
    print_step "Reloading ambxst..."
    if command -v ambxst-reload &> /dev/null; then
        ambxst-reload &>/dev/null && print_success "ambxst reloaded" || print_warning "Reload manually (SUPER+ALT+B)"
    else
        print_warning "Reload manually (SUPER+ALT+B)"
    fi
    
    # Final screen with features
    echo ""
    echo ""
    echo -e "${MAGENTA}${BOLD}    ╔═══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${MAGENTA}${BOLD}    ║                                                               ║${RESET}"
    echo -e "${MAGENTA}${BOLD}    ║${RESET}  ${GREEN}${BOLD}  ✔ Installation Complete!                                    ${RESET}${MAGENTA}${BOLD}║${RESET}"
    echo -e "${MAGENTA}${BOLD}    ║                                                               ║${RESET}"
    echo -e "${MAGENTA}${BOLD}    ║${RESET}  ${CYAN}  Config installed to: ${WHITE}$HYPR_DIR${RESET}  ${MAGENTA}${BOLD}║${RESET}"
    echo -e "${MAGENTA}${BOLD}    ║                                                               ║${RESET}"
    echo -e "${MAGENTA}${BOLD}    ╚═══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    echo -e "    ${MAGENTA}${BOLD}━━━ FEATURES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo -e "    ${CYAN}◆${RESET} ${WHITE}Material You colors${RESET}       Dynamic palette from wallpaper"
    echo -e "    ${CYAN}◆${RESET} ${WHITE}ambxst integration${RESET}       Launcher, dock, lockscreen"
    echo -e "    ${CYAN}◆${RESET} ${WHITE}Blur effects${RESET}             Glass-like windows"
    echo -e "    ${CYAN}◆${RESET} ${WHITE}Window groups${RESET}            Tab-like window management"
    echo -e "    ${CYAN}◆${RESET} ${WHITE}Clipboard history${RESET}        Super+V"
    echo ""
    
    echo -e "    ${MAGENTA}${BOLD}━━━ SHORTCUTS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo -e "    ${GREEN}Super${RESET} Launcher        ${GREEN}Super+D${RESET} Dashboard     ${GREEN}Super+A${RESET} Assistant"
    echo -e "    ${GREEN}Super+V${RESET} Clipboard    ${GREEN}Super+N${RESET} Notes         ${GREEN}Super+,${RESET} Wallpapers"
    echo -e "    ${GREEN}Super+Tab${RESET} Overview   ${GREEN}Super+S${RESET} Tools         ${GREEN}Super+L${RESET} Lock"
    echo ""
    echo -e "    ${GREEN}Super+T${RESET} Terminal      ${GREEN}Super+W${RESET} Browser       ${GREEN}Super+G${RESET} GitHub"
    echo -e "    ${GREEN}Super+E${RESET} Dolphin       ${GREEN}Super+C${RESET} Close         ${GREEN}Super+O${RESET} Opacity"
    echo ""
    echo -e "    ${YELLOW}Super+Alt+B${RESET} Reload ambxst"
    echo -e "    ${YELLOW}Super+Shift+C${RESET} ambxst Config"
    echo -e "    ${YELLOW}Super+Ctrl+B${RESET} Caffeine mode (prevent sleep)"
    echo -e "    ${YELLOW}Super+Shift+H${RESET} Color picker"
    echo -e "    ${YELLOW}Ctrl+Shift+Escape${RESET} System monitor"
    echo ""
    
    echo -e "    ${DIM}${ITALIC}Enjoy your new Hyprland setup! 💜${RESET}"
    echo ""
    echo ""
}

main "$@"
