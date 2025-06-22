#!/usr/bin/env bash

updates_file="/tmp/polybar_updates_shared"

echo "Updating package count..."
count=$(checkupdates 2>/dev/null | wc -l)
if command -v yay >/dev/null 2>&1; then
    count=$((count + $(yay -Qum 2>/dev/null | wc -l)))
fi

if [[ $count -eq 0 ]]; then
    echo " ✅" > $updates_file
else
    echo " $count updates available" > $updates_file
fi
