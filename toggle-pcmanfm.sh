#!/bin/bash
# Toggle pcmanfm/pcmanfm-qt desktop manager to show/hide files on the desktop

CONFIG_FILE="$HOME/.config/pcmanfm-qt/default/settings.conf"

# Determine binary (prefer pcmanfm-qt)
if command -v pcmanfm-qt >/dev/null 2>&1; then
    FM_BIN="pcmanfm-qt"
elif command -v pcmanfm >/dev/null 2>&1; then
    FM_BIN="pcmanfm"
else
    echo "Error: Neither pcmanfm-qt nor pcmanfm found." >&2
    exit 1
fi

if pgrep -f "$FM_BIN --desktop" > /dev/null; then
    echo "Hiding desktop files..."
    pkill -f "$FM_BIN --desktop"
    notify-send -e -a 'Niri' -i 'user-desktop' 'Desktop Files' 'Hidden'
    
    # Wait briefly for pcmanfm-qt to exit and write its config
    sleep 0.5
    
    # Restore transparent background color
    if [ -f "$CONFIG_FILE" ]; then
        sed -i 's/^BgColor=#000000$/BgColor=#00000000/' "$CONFIG_FILE"
    fi
else
    # Ensure transparent background color is configured before starting
    if [ -f "$CONFIG_FILE" ]; then
        sed -i 's/^BgColor=#000000$/BgColor=#00000000/' "$CONFIG_FILE"
    fi

    echo "Showing desktop files..."
    nohup "$FM_BIN" --desktop >/dev/null 2>&1 &
    notify-send -e -a 'Niri' -i 'user-desktop' 'Desktop Files' 'Shown'
fi
