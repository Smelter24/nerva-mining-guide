#!/bin/bash
# Nerva Block Found Notifier
# Monitors nervad log file and sends Telegram notification when a new block is found
#
# Usage:
#   1. Set BOT_TOKEN and CHAT_ID below
#   2. chmod +x nerva-block-notifier.sh
#   3. nohup ./nerva-block-notifier.sh &
#
# Or install as systemd service (see README.md)

BOT_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"
LOG_FILE="/root/.nerva/nerva.log"

# Validate config
if [ "$BOT_TOKEN" = "YOUR_BOT_TOKEN" ] || [ "$CHAT_ID" = "YOUR_CHAT_ID" ]; then
    echo "ERROR: Set BOT_TOKEN and CHAT_ID in this script first!"
    exit 1
fi

if [ ! -f "$LOG_FILE" ]; then
    echo "ERROR: Log file not found: $LOG_FILE"
    echo "Make sure nervad is running and logging to this path."
    exit 1
fi

# Get the last known block count on startup (skip existing blocks)
LAST_COUNT=$(grep -c "Found block" "$LOG_FILE" 2>/dev/null || echo 0)
echo "[$(date)] Monitoring nerva log at $LOG_FILE (known blocks: $LAST_COUNT)"

tail -Fn0 "$LOG_FILE" | while read line; do
    if echo "$line" | grep -q "Found block"; then
        HEIGHT=$(echo "$line" | grep -oP 'height: \K[0-9]+')
        NEW_COUNT=$(grep -c "Found block" "$LOG_FILE" 2>/dev/null || echo 0)

        # Only notify for NEW blocks (skip existing on startup)
        if [ "$NEW_COUNT" -gt "$LAST_COUNT" ]; then
            echo "[$(date)] NEW BLOCK FOUND at height $HEIGHT"
            RESPONSE=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
                -d "chat_id=${CHAT_ID}" \
                --data-urlencode "text=Nerva Block Found!
Height: ${HEIGHT}
Reward: 0.3 XNV
Time: $(date '+%H:%M:%S %d/%m/%Y')" \
                -d "parse_mode=HTML")
            
            if echo "$RESPONSE" | grep -q '"ok":true'; then
                echo "[$(date)] Telegram notification sent"
            else
                echo "[$(date)] ERROR: Telegram send failed: $RESPONSE"
            fi
            LAST_COUNT=$NEW_COUNT
        fi
    fi
done
