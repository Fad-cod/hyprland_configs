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
    echo "    ╔═══════════════════════════════════════════════════════╗"
    echo "    ║                                                       ║"
    echo "    ║     █████╗ ███╗   ███╗ █████╗ ███████╗ ██████╗ ███╗   ║"
    echo "    ║    ██╔══██╗████╗ ████║██╔══██╗██╔════╝██╔═══██╗████╗  ║"
    echo "    ║    ███████║██╔████╔██║███████║█████╗  ██║   ██║██╔██╗ ║"
    echo "    ║    ██╔══██║██║╚██╔╝██║██╔══██║██╔══╝  ██║   ██║██║╚██╗║"
    echo "    ║    ██║  ██║██║ ╚═╝ ██║██║  ██║███████╗╚██████╔╝██║ ╚██║"
    echo "    ║    ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝║"
    echo "    ║                                                       ║"
    echo "    ║               Config Installer v1.0                   ║"
    echo "    ║                                                       ║"
    echo "    ╚═══════════════════════════════════════════════════════╝"
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

# Main installation
main() {
    print_logo
    
    print_step "Checking dependencies..."
    sleep 0.5
    
    # Check for required tools
    if ! command -v curl &> /dev/null; then
        print_warning "curl not found. Installing..."
        if command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm curl
        elif command -v apt &> /dev/null; then
            sudo apt install -y curl
        fi
    fi
    print_success "curl found"
    
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
    print_step "Installation complete!"
    echo ""
    echo -e "${MAGENTA}${BOLD}  ═══════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}${BOLD}    ✔ Config installed to ${CYAN}$HYPR_DIR${RESET}"
    echo -e "${DIM}    Restart Hyprland to apply changes${RESET}"
    echo -e "${MAGENTA}${BOLD}  ═══════════════════════════════════════════════${RESET}"
    echo ""
}

main "$@"
