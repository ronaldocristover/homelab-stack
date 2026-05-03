#!/bin/bash
set -euo pipefail

WEBHOOK_URL="${ALERT_WEBHOOK_URL:-}"
if [ -z "$WEBHOOK_URL" ]; then
  exit 0
fi

if [ "${1:-}" = "--json" ]; then
  PAYLOAD="${2:-}"
else
  STATUS="${1:-}"
  MESSAGE="${2:-}"
  HOST="${ALERT_HOSTNAME:-${HOSTNAME:-unknown}}"
  TEXT="[MySQL Backup] ${HOST}: ${STATUS} - ${MESSAGE}"
  PAYLOAD="{\"content\":\"${TEXT}\",\"text\":\"${TEXT}\"}"
fi

curl -s -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  || true
