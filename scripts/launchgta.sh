#!/usr/bin/env bash

# --- CONFIGURATION (Tailored for Intel i5-12500H) ---
# 4 P-Cores (with Hyper-Threading) = Threads 0-7
MAJOR_CORES="0-7"
# 8 E-Cores (Single Threaded) = Threads 8-15
LITTLE_CORES="8-15"
# ----------------------------------------------------

# Sanitize input: strip whitespace and Windows carriage returns (\r)
MODE=$(echo "$1" | tr -d '\r' | xargs)

if [ -z "$MODE" ]; then
    MODE="default"
fi

if [ "$MODE" != "default" ] && [ "$MODE" != "inverse" ]; then
    echo "Usage: sudo ./optimize_gta.sh [default|inverse]"
    exit 1
fi

# Pre-determine the targets outside the loop
if [ "$MODE" = "default" ]; then
    GAME_TARGET="$LITTLE_CORES"
    GAME_TXT="Default (Little Cores -> $LITTLE_CORES)"
    BRIDGE_TARGET="$MAJOR_CORES"
    BRIDGE_TXT="Default (Major Cores -> $MAJOR_CORES)"
else
    GAME_TARGET="$MAJOR_CORES"
    GAME_TXT="Inverse (Major Cores -> $MAJOR_CORES)"
    BRIDGE_TARGET="$LITTLE_CORES"
    BRIDGE_TXT="Inverse (Little Cores -> $LITTLE_CORES)"
fi

echo "=== RTX Remix CPU Affinity Watcher (Mode: $MODE) Intel i5-12500h ==="
echo "Status: Active. Monitoring processes (Press Ctrl+C to exit)..."

declare -A SEEN_PIDS

while true; do
    GAME_PIDS=$(pgrep -i "gtaiv")
    BRIDGE_PIDS=$(pgrep -i "remixbridge")

    # Process GTA IV
    if [ -n "$GAME_PIDS" ]; then
        for pid in $GAME_PIDS; do
            if [ -z "${SEEN_PIDS[$pid]}" ]; then
                # 1. Forcefully apply the target affinity across all threads
                taskset -acp $GAME_TARGET $pid > /dev/null

                # 2. Autonomous Debug: Query the OS for the actual resulting affinity list
                OS_VERIFICATION=$(taskset -cp $pid 2>/dev/null | awk -F': ' '{print $2}')

                echo "[+] Targeting GTA IV (PID: $pid) -> Requesting: $GAME_TXT"
                echo "    └── [KERNEL VERIFIED] Active Core Mask: $OS_VERIFICATION"
                echo "--------------------------------------------------------"
                SEEN_PIDS[$pid]=1
            fi
        done
    fi

    # Process RTX Remix Bridge
    if [ -n "$BRIDGE_PIDS" ]; then
        for pid in $BRIDGE_PIDS; do
            if [ -z "${SEEN_PIDS[$pid]}" ]; then
                # 1. Forcefully apply the target affinity across all threads
                taskset -acp $BRIDGE_TARGET $pid > /dev/null

                # 2. Autonomous Debug: Query the OS for the actual resulting affinity list
                OS_VERIFICATION=$(taskset -cp $pid 2>/dev/null | awk -F': ' '{print $2}')

                echo "[+] Targeting Remix Bridge (PID: $pid) -> Requesting: $BRIDGE_TXT"
                echo "    └── [KERNEL VERIFIED] Active Core Mask: $OS_VERIFICATION"
                echo "--------------------------------------------------------"
                SEEN_PIDS[$pid]=1
            fi
        done
    fi

    sleep 2
done
