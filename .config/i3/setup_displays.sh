#!/bin/bash

# Display setup script for i3wm
# Detects if running on desktop (with DP-4 and DVI-D-0) or laptop and configures accordingly

# Function to check if a display output exists and is connected
check_output() {
    xrandr | grep -q "^$1 connected"
}

# Check if we're on the desktop setup (both DP-4 and DVI-D-0 available)
if check_output "DP-4" && check_output "DVI-D-0"; then
    echo "Desktop setup detected - configuring dual monitors"

    # Configure dual monitor setup for desktop
    xrandr --output DP-4 -r 144 --primary --mode 2560x1440 --pos 0x0 --rotate normal \
           --output DVI-D-0 --mode 1920x1080 --pos 2560x0 --rotate normal

    # Assign workspaces to specific outputs
    i3-msg "workspace 1 output DP-4"
    i3-msg "workspace 2 output DVI-D-0"

elif check_output "DP-4"; then
    echo "Single DP-4 monitor detected"

    # Configure single monitor on DP-4
    xrandr --output DP-4 -r 144 --primary --mode 2560x1440 --pos 0x0 --rotate normal

else
    echo "Laptop or unknown setup detected - using default display configuration"

    # Get the primary connected output (usually eDP-1 for laptops or whatever is available)
    PRIMARY_OUTPUT=$(xrandr | grep " connected primary" | cut -d' ' -f1)

    # If no primary is set, get the first connected output
    if [ -z "$PRIMARY_OUTPUT" ]; then
        PRIMARY_OUTPUT=$(xrandr | grep " connected" | head -n1 | cut -d' ' -f1)
    fi

    if [ -n "$PRIMARY_OUTPUT" ]; then
        echo "Setting up $PRIMARY_OUTPUT as primary display"
        xrandr --output "$PRIMARY_OUTPUT" --auto --primary
    fi
fi

# Turn off any disconnected outputs to avoid issues
xrandr | grep " disconnected" | cut -d' ' -f1 | while read output; do
    xrandr --output "$output" --off
done

echo "Display setup completed"
