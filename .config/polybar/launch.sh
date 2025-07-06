#!/usr/bin/env bash

killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

echo "Updating package count..."
~/.config/polybar/scripts/updates.sh

sleep 1

if command -v xrandr >/dev/null 2>&1; then
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
        echo "Launching polybar on monitor: $m"
        MONITOR=$m polybar --reload main &
    done
else
    polybar --reload main &
fi

echo "Polybar launched..."
