#!/bin/bash

CONFIG_FILE="/etc/wireguard/notifier.conf"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file $CONFIG_FILE not found." >&2
    exit 1
fi

#Defaults if not defined in config
WG_INTERFACE="${WG_INTERFACE:-wg0}"
TIMEOUT="${TIMEOUT:-180}"
STATE_DIR="${STATE_DIR:-/tmp/wg-state}"
CONFIGS_DIR="${CONFIGS_DIR:-/etc/wireguard/keys}"

mkdir -p "$STATE_DIR"
NOW=$(date +%s)

#send Telegram messages
send_telegram() {
    local text="$1"
    curl -s -X POST "https://api.telegram.org/bot${YOUR_BOT_TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        -d text="${text}" \
        -d parse_mode="HTML" > /dev/null
}

#process each active peer on the interface
while read -r PUBLIC_KEY PRESHARED_KEY ENDPOINT ALLOWED_IPS LATEST_HANDSHAKE TRANSFER_RX TRANSFER_TX; do
    [ -z "$PUBLIC_KEY" ] && continue

    #extract name from WG config (### begin NAME ###)
    CLIENT_NAME=$(grep -B 2 -F "$PUBLIC_KEY" "/etc/wireguard/${WG_INTERFACE}.conf" 2>/dev/null | grep -oP '### begin \K[^\s#]+' | head -n 1)

    #fallback to config files if not found in wg0.conf
    if [ -z "$CLIENT_NAME" ] && [ -d "$CONFIGS_DIR" ]; then
        for cfg in "$CONFIGS_DIR"/*.conf; do
            if [ -f "$cfg" ] && grep -q "$PUBLIC_KEY" "$cfg" 2>/dev/null; then
                CLIENT_NAME=$(basename "$cfg" .conf)
                break
            fi
        done
    fi

    #fallback to truncated public key if no name found
    [ -z "$CLIENT_NAME" ] && CLIENT_NAME="${PUBLIC_KEY:0:10}..."

    REMOTE_IP=$(echo "$ENDPOINT" | cut -d: -f1)
    PEER_FILE="${STATE_DIR}/${PUBLIC_KEY//\//_}"

    #calculate time since last handshake
    if [ "$LATEST_HANDSHAKE" -gt 0 ]; then
        DIFF=$((NOW - LATEST_HANDSHAKE))
    else
        DIFF=999999
    fi

    #determine current status
    if [ "$DIFF" -le "$TIMEOUT" ]; then
        CURRENT_STATE="ONLINE"
    else
        CURRENT_STATE="OFFLINE"
    fi

    #read previous status
    if [ -f "$PEER_FILE" ]; then
        LAST_STATE=$(cut -d' ' -f1 "$PEER_FILE")
        LAST_IP=$(cut -d' ' -f2 "$PEER_FILE")
    else
        LAST_STATE="OFFLINE"
        LAST_IP=""
    fi

    #state "Connected / IP Changed"
    if [ "$CURRENT_STATE" = "ONLINE" ]; then
        if [ "$LAST_STATE" = "OFFLINE" ] || [ -n "$REMOTE_IP" -a "$REMOTE_IP" != "$LAST_IP" ]; then
            MESSAGE="🟢 <b>WireGuard Alert</b>%0A<b>User:</b> ${CLIENT_NAME}%0A<b>Status:</b> Connected%0A<b>IP:</b> ${REMOTE_IP}"
            send_telegram "$MESSAGE"
        fi
    #state "Disconnected"
    elif [ "$CURRENT_STATE" = "OFFLINE" ] && [ "$LAST_STATE" = "ONLINE" ]; then
        MESSAGE="🔴 <b>WireGuard Alert</b>%0A<b>User:</b> ${CLIENT_NAME}%0A<b>Status:</b> Disconnected"
        send_telegram "$MESSAGE"
    fi

    #save state
    echo "${CURRENT_STATE} ${REMOTE_IP}" > "$PEER_FILE"

done < <(wg show "$WG_INTERFACE" dump | tail -n +2)