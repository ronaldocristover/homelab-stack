#!/bin/bash
set -euo pipefail

ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
  while IFS='=' read -r key value; do
    [[ "$key" =~ ^#|^[[:space:]]*$ ]] && continue
    export "$key"="$value"
  done < "$ENV_FILE"
fi

WEBHOOK_URL="${ALERT_WEBHOOK_URL:-}"
if [ -z "$WEBHOOK_URL" ]; then
  echo "ERROR: ALERT_WEBHOOK_URL is not set in .env"
  exit 1
fi

HOSTNAME="${ALERT_HOSTNAME:-${HOSTNAME:-$(hostname 2>/dev/null || echo unknown)}}"
TEXT="[MySQL Backup] ${HOSTNAME}: TEST - notification test at $(date)"

echo "Sending test notification to webhook..."
HTTP_STATUS=$(curl -s -o /tmp/notify_response.txt -w "%{http_code}" \
  -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{\"content\": \"${TEXT}\", \"text\": \"${TEXT}\"}")

RESPONSE=$(cat /tmp/notify_response.txt)

if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
  echo "OK (HTTP $HTTP_STATUS)"
else
  echo "FAILED (HTTP $HTTP_STATUS): $RESPONSE"
  exit 1
fi
