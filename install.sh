#!/usr/bin/env bash

# ==============================================================================
#  🚀 NixOS Modular Dotfiles & Rice Installer (with Try-Catch Error Handling)
# ==============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for pretty status output
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

# Track failed steps
WARNINGS=()

# ------------------------------------------------------------------------------
#  Try-Catch Helper Function
# ------------------------------------------------------------------------------
try_catch() {
    local task_name="$1"
    shift
    local cmd=("$@")

    echo -ne "  ${CYAN}•${RESET} $task_name ... "

    # Execute command, capture output and error
    local output
    if output=$("${cmd[@]}" 2>&1); then
        echo -e "${GREEN}[✓ SUCCESS]${RESET}"
        return 0
    else
        local exit_code=$?
        echo -e "${YELLOW}[⚠ EXCEPTION CAUGHT]${RESET} (exit code: $exit_code)"
        if [ -n "$output" ]; then
            echo -e "    ${YELLOW}↳ Detail:${RESET} $(echo "$output" | head -n 2)"
        fi
        WARNINGS+=("$task_name (Code: $exit_code)")
        return "$exit_code"
    fi
}

# ------------------------------------------------------------------------------
#  Safe Symlink Helper Function
# ------------------------------------------------------------------------------
try_symlink() {
    local src="$1"
    local dest="$2"
    local desc="$3"

    if [ ! -e "$src" ]; then
        echo -e "  ${YELLOW}[⚠ SKIP]${RESET} $desc: source not found ($src)"
        return 0
    fi

    # Backup if dest exists and is a regular file/dir (not a symlink)
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "${dest}.bak.$(date +%s)" 2>/dev/null || true
    fi

    mkdir -p "$(dirname "$dest")" 2>/dev/null || true
    rm -f "$dest" 2>/dev/null || true

    if ln -snf "$src" "$dest" 2>/dev/null; then
        echo -e "  ${GREEN}[✓]${RESET} $desc"
    else
        echo -e "  ${RED}[✗]${RESET} Failed to link $desc"
        WARNINGS+=("Symlink: $desc")
    fi
}

echo -e "${BLUE}========================================================${RESET}"
echo -e "    ${CYAN}🚀 NixOS Modular Dotfiles & Rice Installer 🚀${RESET}      "
echo -e "${BLUE}========================================================${RESET}\n"

# 1. Host Profile Selection
HOST="$1"
if [ -z "$HOST" ]; then
    echo "Select target machine profile:"
    echo "  1) Laptop (Tuxedo RGB, battery management, hybrid GPU)"
    echo "  2) Desktop (Standard desktop GPU, high performance)"
    read -rp "Enter choice [1 or 2] (default: 1): " CHOICE
    case "$CHOICE" in
        2|desktop|Desktop)
            HOST="desktop"
            ;;
        *)
            HOST="laptop"
            ;;
    esac
fi

echo -e "\n📦 Selected Profile: ${BLUE}$HOST${RESET}\n"

# 2. Hardware Configuration Detection / Generation
echo -e "${CYAN}--- [1/4] Hardware Configuration ---${RESET}"
HW_CONFIG="$DOTFILES_DIR/hosts/$HOST/hardware-configuration.nix"

if [ ! -f "$HW_CONFIG" ] || grep -q "Placeholder" "$HW_CONFIG" 2>/dev/null; then
    try_catch "Detecting and generating local hardware configuration" bash -c "
        if [ -f '/etc/nixos/hardware-configuration.nix' ]; then
            cp '/etc/nixos/hardware-configuration.nix' '$HW_CONFIG'
        else
            sudo nixos-generate-config --show-hardware-config > '$HW_CONFIG'
        fi
    "
else
    echo -e "  ${GREEN}[✓]${RESET} Existing hardware configuration found for $HOST"
fi

# 3. Scaffold Directories
echo -e "\n${CYAN}--- [2/4] Directory Scaffolding ---${RESET}"
try_catch "Scaffolding configuration directories" mkdir -p \
    "$HOME/.config" \
    "$HOME/.local/bin" \
    "$HOME/.local/state/noctalia" \
    "$HOME/.config/Antigravity IDE/User" \
    "$HOME/.config/Code - OSS/User" \
    "$HOME/.config/Code/User"

# 4. Safe Symlinking of Dotfiles
echo -e "\n${CYAN}--- [3/4] Linking User Configurations ---${RESET}"

# Core config directories
for folder in niri noctalia kitty gtk-3.0 gtk-4.0 qt5ct qt6ct micro; do
    if [ -d "$DOTFILES_DIR/.config/$folder" ]; then
        try_symlink "$DOTFILES_DIR/.config/$folder" "$HOME/.config/$folder" "~/.config/$folder"
    fi
done

# Shell files
try_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc" "~/.zshrc"
try_symlink "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh" "~/.p10k.zsh"

# Noctalia state & Default MIME Associations
try_symlink "$DOTFILES_DIR/.config/noctalia/settings.toml" "$HOME/.local/state/noctalia/settings.toml" "~/.local/state/noctalia/settings.toml"
try_symlink "$DOTFILES_DIR/.config/mimeapps.list" "$HOME/.config/mimeapps.list" "~/.config/mimeapps.list"

# IDE settings and keybindings
for ide in "Antigravity IDE" "Code - OSS" "Code"; do
    if [ -d "$DOTFILES_DIR/.config/$ide/User" ]; then
        [ -f "$DOTFILES_DIR/.config/$ide/User/settings.json" ] && \
            try_symlink "$DOTFILES_DIR/.config/$ide/User/settings.json" "$HOME/.config/$ide/User/settings.json" "$ide settings.json"
        [ -f "$DOTFILES_DIR/.config/$ide/User/keybindings.json" ] && \
            try_symlink "$DOTFILES_DIR/.config/$ide/User/keybindings.json" "$HOME/.config/$ide/User/keybindings.json" "$ide keybindings.json"
    fi
done

# 5. Git Staging & NixOS Rebuild
echo -e "\n${CYAN}--- [4/4] System Deployment (Flake: #$HOST) ---${RESET}"

if [ -d "$DOTFILES_DIR/.git" ]; then
    try_catch "Staging untracked files for Flake evaluator" git -C "$DOTFILES_DIR" add -A
fi

echo -e "\n  ${BLUE}❄️ Applying NixOS rebuild...${RESET}"
if sudo nixos-rebuild switch --flake "$DOTFILES_DIR#$HOST"; then
    echo -e "\n${GREEN}========================================================${RESET}"
    echo -e "    ${GREEN}🎉 System Successfully Deployed and Switched! 🎉${RESET}   "
    echo -e "${GREEN}========================================================${RESET}"
else
    echo -e "\n${RED}========================================================${RESET}"
    echo -e "    ${RED}✗ NixOS Rebuild Encountered an Error.${RESET}             "
    echo -e "${RED}========================================================${RESET}"
    WARNINGS+=("NixOS Rebuild Switch")
fi

# Summary of caught warnings
if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}⚠️  Notice: The following exceptions were logged during installation:${RESET}"
    for warn in "${WARNINGS[@]}"; do
        echo -e "  - $warn"
    done
fi

echo -e "\nAll done! You can now log into your session or reboot.\n"
