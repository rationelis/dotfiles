#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bars on all monitors
if type "xrandr"; then
  for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    echo "Launching polybar on monitor: $m"
    MONITOR=$m polybar --reload main &
  done
else
  polybar --reload main &
fi

echo "Polybar launched..."
