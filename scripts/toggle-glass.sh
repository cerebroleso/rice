#!/usr/bin/env bash
# Toggle between stock_niri and glass_niri configs into .config/niri

# Resolve repository root path (parent of scripts/)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$REPO_ROOT/.config/niri"
STOCK_DIR="$REPO_ROOT/stock_niri"
GLASS_DIR="$REPO_ROOT/glass_niri"

# Backup active noctalia.kdl to preserve user's dynamic palette
if [ -f "$CONFIG_DIR/noctalia.kdl" ]; then
    cp "$CONFIG_DIR/noctalia.kdl" "$CONFIG_DIR/noctalia.kdl.tmp"
fi

# Detect active mode by checking if config.kdl in the active dir contains "liquid-glass"
if grep -q "liquid-glass" "$CONFIG_DIR/config.kdl" || grep -q "liquid-glass" "$CONFIG_DIR/window_rules.kdl"; then
    echo "Switching active config to standard (stock_niri)..."
    cp -rf "$STOCK_DIR/"* "$CONFIG_DIR/"
    notify_msg="Switched to Stock (No Glass)"
else
    echo "Switching active config to Liquid Glass (glass_niri)..."
    cp -rf "$GLASS_DIR/"* "$CONFIG_DIR/"
    notify_msg="Switched to Liquid Glass"
fi

# Restore dynamic noctalia.kdl if it was backed up
if [ -f "$CONFIG_DIR/noctalia.kdl.tmp" ]; then
    mv "$CONFIG_DIR/noctalia.kdl.tmp" "$CONFIG_DIR/noctalia.kdl"
fi

niri msg action load-config-file 2>/dev/null
notify-send -e -a 'Niri' -i 'folder-code' 'Niri Config' "$notify_msg"
