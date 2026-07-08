#!/bin/bash
# Toggle between stock_niri and glass_niri configs into .config/niri

# Resolve repository root path
REPO_ROOT="$(dirname "$(readlink -f "$0")")"
CONFIG_DIR="$REPO_ROOT/.config/niri"
STOCK_DIR="$REPO_ROOT/stock_niri"
GLASS_DIR="$REPO_ROOT/glass_niri"

# Detect active mode by checking if config.kdl in the active dir contains "liquid-glass"
if grep -q "liquid-glass" "$CONFIG_DIR/config.kdl" || grep -q "liquid-glass" "$CONFIG_DIR/window_rules.kdl"; then
    echo "Switching active config to standard (stock_niri)..."
    cp -rf "$STOCK_DIR/"* "$CONFIG_DIR/"
    niri msg action load-config-file 2>/dev/null
    notify-send -e -a 'Niri' -i 'preferences-desktop' 'Niri Config' 'Switched to Stock (No Glass)'
else
    echo "Switching active config to Liquid Glass (glass_niri)..."
    cp -rf "$GLASS_DIR/"* "$CONFIG_DIR/"
    niri msg action load-config-file 2>/dev/null
    notify-send -e -a 'Niri' -i 'preferences-desktop' 'Niri Config' 'Switched to Liquid Glass'
fi
