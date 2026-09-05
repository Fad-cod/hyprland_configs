#!/bin/bash
# Hyprland Config Installer

set -e

# Colors
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
RESET='\033[0m'

# Config
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HYPR_DIR="$HOME/.config/hypr"
AMBXST_DIR="$HOME/.local/share/ambxst"

# Print functions
print_logo() {
    echo ""
    echo -e "${MAGENTA}${BOLD}"
    echo "╔═════════════════════════════════════════════════════════════════════╗"
    echo "║ ╔═════════════════════════════════════════════════════════════════╗ ║"
    echo "║ ║                                                                 ║ ║"
    echo "║ ║     █████╗  ███╗   ███╗ ██████╗  ██╗  ██╗ ███████╗ ████████╗    ║ ║"
    echo "║ ║    ██╔══██╗ ████╗ ████║ ██╔══██╗ ╚██╗██╔╝ ██╔════╝ ╚══██╔══╝    ║ ║"
    echo "║ ║    ███████║ ██╔████╔██║ ██████╔╝  ╚███╔╝  ███████╗    ██║       ║ ║"
    echo "║ ║    ██╔══██║ ██║╚██╔╝██║ ██╔══██╗  ██╔██╗  ╚════██║    ██║       ║ ║"
    echo "║ ║    ██║  ██║ ██║ ╚═╝ ██║ ██████╔╝ ██╔╝ ██╗ ███████║    ██║       ║ ║"
    echo "║ ║    ╚═╝  ╚═╝ ╚═╝     ╚═╝ ╚═════╝  ╚═╝  ╚═╝ ╚══════╝    ╚═╝       ║ ║"
    echo "║ ║                                                                 ║ ║"
    echo "║ ║                      Config Installer v1.0                      ║ ║"
    echo "║ ║                                                                 ║ ║"
    echo "║ ╚═════════════════════════════════════════════════════════════════╝ ║"
    echo "╚═════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "${CYAN}${BOLD}  ✦ Hyprland Config Installer ✦${RESET}"
    echo -e "${DIM}  ─────────────────────────────${RESET}"
    echo ""
}

print_step() {
    echo -e "${GREEN}${BOLD}  ▸ ${1}${RESET}"
}

print_info() {
    echo -e "${CYAN}    ℹ ${1}${RESET}"
}

print_success() {
    echo -e "${GREEN}${BOLD}    ✔ ${1}${RESET}"
}

print_warning() {
    echo -e "${YELLOW}    ⚠ ${1}${RESET}"
}

print_progress() {
    local width=30
    local percent=$1
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    printf "\r    ["
    printf "%0.s█" $(seq 1 $filled 2>/dev/null) || true
    printf "%0.s░" $(seq 1 $empty 2>/dev/null) || true
    printf "] %3d%%" $percent
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
    
    print_step "Checking system..."
    sleep 0.5
    
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
            print_warning "No AUR helper found. Installing yay..."
            print_info "Cloning yay..."
            
            cd /tmp
            git clone https://aur.archlinux.org/yay.git 2>/dev/null
            cd yay
            makepkg -si --noconfirm 2>/dev/null || print_warning "Could not install yay automatically"
            cd ~
            
            if command -v yay &> /dev/null; then
                AUR_HELPER="yay"
                AUR_INSTALL="yay -S --noconfirm"
                print_success "yay installed"
            else
                print_warning "yay installation failed. AUR packages won't be installed."
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
        print_warning "Unknown package manager. Install dependencies manually."
        PKG_MGR="unknown"
    fi
    
    print_info "Package manager: $PKG_MGR"
    [ -n "$AUR_HELPER" ] && print_info "AUR helper: $AUR_HELPER"
    
    echo ""
    print_step "Checking dependencies..."
    echo ""
    
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
            print_warning "$dep - missing"
            MISSING_DEPS+=("$dep")
        fi
    done
    
    # Check AUR dependencies
    if [ -n "$AUR_HELPER" ]; then
        for dep in "${AUR_DEPS[@]}"; do
            if is_installed "$dep"; then
                print_success "$dep"
            else
                print_warning "$dep - missing (AUR)"
                MISSING_AUR+=("$dep")
            fi
        done
    fi
    
    echo ""
    
    # Install missing dependencies
    if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
        print_step "Installing missing dependencies..."
        echo ""
        
        for dep in "${MISSING_DEPS[@]}"; do
            print_info "Installing $dep..."
            $PKG_INSTALL "$dep" &>/dev/null && print_success "$dep" || print_warning "Could not install $dep"
        done
        
        echo ""
        print_success "Dependencies installed"
    else
        print_success "All dependencies satisfied"
    fi
    
    # Install missing AUR dependencies
    if [ ${#MISSING_AUR[@]} -gt 0 ] && [ -n "$AUR_HELPER" ]; then
        print_step "Installing AUR packages..."
        echo ""
        
        for dep in "${MISSING_AUR[@]}"; do
            print_info "Installing $dep..."
            $AUR_INSTALL "$dep" &>/dev/null && print_success "$dep" || print_warning "Could not install $dep"
        done
        
        echo ""
        print_success "AUR packages installed"
    fi
    
    echo ""
    print_step "Creating directories..."
    sleep 0.3
    
    mkdir -p "$HYPR_DIR/hyprland"
    mkdir -p "$HYPR_DIR/scheme"
    mkdir -p "$HYPR_DIR/scripts"
    mkdir -p "$AMBXST_DIR"
    
    print_success "Directories created"
    
    echo ""
    print_step "Installing configuration files..."
    echo ""
    
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
            sleep 0.05
        fi
    done
    
    # Copy module configs
    for file in "$SCRIPT_DIR"/*.lua "$SCRIPT_DIR"/*.conf; do
        if [ -f "$file" ] && [ "$(basename "$file")" != "hyprland.conf" ] && [ "$(basename "$file")" != "hyprland.lua" ] && [ "$(basename "$file")" != "variables.conf" ]; then
            cp "$file" "$HYPR_DIR/hyprland/"
            CURRENT_FILE=$((CURRENT_FILE + 1))
            print_progress $((CURRENT_FILE * 100 / TOTAL_FILES))
            sleep 0.05
        fi
    done
    
    # Copy scheme files
    for file in "$SCRIPT_DIR/scheme/"*; do
        if [ -f "$file" ]; then
            cp "$file" "$HYPR_DIR/scheme/"
            CURRENT_FILE=$((CURRENT_FILE + 1))
            print_progress $((CURRENT_FILE * 100 / TOTAL_FILES))
            sleep 0.05
        fi
    done
    
    # Copy scripts
    for file in "$SCRIPT_DIR/scripts/"*; do
        if [ -f "$file" ]; then
            cp "$file" "$HYPR_DIR/scripts/"
            chmod +x "$HYPR_DIR/scripts/$(basename "$file")"
            CURRENT_FILE=$((CURRENT_FILE + 1))
            print_progress $((CURRENT_FILE * 100 / TOTAL_FILES))
            sleep 0.05
        fi
    done
    
    # Copy ambxst configs
    for file in "$SCRIPT_DIR"/ambxst*.conf "$SCRIPT_DIR"/ambxst*.lua; do
        if [ -f "$file" ]; then
            cp "$file" "$AMBXST_DIR/"
            CURRENT_FILE=$((CURRENT_FILE + 1))
            print_progress $((CURRENT_FILE * 100 / TOTAL_FILES))
            sleep 0.05
        fi
    done 2>/dev/null || true
    
    echo ""
    echo ""
    print_success "All files installed!"
    
    echo ""
    print_step "Reloading services..."
    echo ""
    
    # Reload Hyprland
    print_info "Reloading Hyprland..."
    hyprctl reload 2>/dev/null && print_success "Hyprland reloaded" || print_warning "Could not reload Hyprland (restart manually)"
    
    # Reload ambxst
    print_info "Reloading ambxst..."
    if command -v ambxst-reload &> /dev/null; then
        ambxst-reload 2>/dev/null && print_success "ambxst reloaded" || print_warning "Could not reload ambxst"
    else
        print_warning "ambxst-reload not found (reload manually with SUPER+ALT+B)"
    fi
    
    echo ""
    print_step "Installation complete!"
    echo ""
    echo -e "${MAGENTA}${BOLD}  ═══════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}${BOLD}    ✔ Config installed to ${CYAN}$HYPR_DIR${RESET}"
    echo -e "${GREEN}${BOLD}    ✔ Hyprland and ambxst reloaded${RESET}"
    echo -e "${MAGENTA}${BOLD}  ═══════════════════════════════════════════════${RESET}"
    echo ""
}

main "$@"
