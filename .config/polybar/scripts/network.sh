#!/bin/bash

ACTIVE_CONNECTION=$(nmcli -t -f TYPE,STATE connection show --active | grep ":activated" | head -1)

if [ -z "$ACTIVE_CONNECTION" ]; then
    echo "❌ No Connection"
    exit 0
fi

CONNECTION_TYPE=$(echo "$ACTIVE_CONNECTION" | cut -d: -f1)

case "$CONNECTION_TYPE" in
    "802-11-wireless"|"wireless")
        SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
        if [ -n "$SSID" ]; then
            echo "📶 $SSID"
        else
            echo "📶 WiFi"
        fi
        ;;
    "802-3-ethernet"|"ethernet")
        echo "🔌 Ethernet"
        ;;
    *)
        echo "🌐 Connected"
        ;;
esac
