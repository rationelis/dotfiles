#!/bin/bash

# Simple update checker
count=$(checkupdates 2>/dev/null | wc -l)

if command -v yay >/dev/null 2>&1; then
    aur_count=$(yay -Qum 2>/dev/null | wc -l)
    count=$((count + aur_count))
fi

if [[ $count -eq 0 ]]; then
    echo " ✅"
else
    echo " $count updates available"
fi
