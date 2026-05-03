#!/bin/bash
set -euo pipefail

if [ "${LOCAL_BACKUP_ENABLED:-false}" != "true" ]; then
  echo "[$(date)] Local HDD backup not enabled, skipping"
  exit 0
fi

SERVERS_FILE="${SERVERS_FILE:-/config/servers.json}"
BACKUP_DIR=/backups-hdd
START_TIME=$(date +%s)

echo "=========================================="
echo "[$(date)] LOCAL HDD SYNC STARTED"
echo "[$(date)] Destination: $LOCAL_DIR"
echo "=========================================="

ERRORS=()

if [ -f "$SERVERS_FILE" ]; then
  SERVER_COUNT=$(jq length "$SERVERS_FILE")
else
  SERVER_COUNT=0
fi

for SERVER_INDEX in $(seq 0 $((SERVER_COUNT - 1))); do
  SERVER_NAME=$(jq -r ".[$SERVER_INDEX].name" "$SERVERS_FILE")
  DB_COUNT=$(jq ".[$SERVER_INDEX].databases | length" "$SERVERS_FILE")

  for DB_INDEX in $(seq 0 $((DB_COUNT - 1))); do
    DB=$(jq -r ".[$SERVER_INDEX].databases[$DB_INDEX]" "$SERVERS_FILE")
    mkdir -p "$LOCAL_DIR/$SERVER_NAME/$DB"

    echo "[$(date)] Syncing $SERVER_NAME/$DB -> $LOCAL_DIR/$SERVER_NAME/$DB/"
    if rsync -a "$BACKUP_DIR/$SERVER_NAME/$DB/" "$LOCAL_DIR/$SERVER_NAME/$DB/"; then
      SIZE=$(du -sh "$LOCAL_DIR/$SERVER_NAME/$DB" | cut -f1)
      echo "[$(date)] Sync done: $SERVER_NAME/$DB ($SIZE)"
    else
      echo "[$(date)] ERROR: Sync failed for $SERVER_NAME/$DB"
      ERRORS+=("$SERVER_NAME/$DB")
    fi
  done
done

if [ "${LOCAL_CLEANUP:-false}" = "true" ]; then
  DELETED=$(find "$LOCAL_DIR" -name "*.sql.gz" -type f -mmin "+$((LOCAL_CLEANUP_DAYS * 1440))" -print -delete 2>/dev/null | wc -l)
  echo "[$(date)] Cleaned up $DELETED old file(s) from local HDD"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "=========================================="
if [ ${#ERRORS[@]} -eq 0 ]; then
  echo "[$(date)] LOCAL SYNC COMPLETED in ${DURATION}s — $SERVER_COUNT server(s)"
else
  echo "[$(date)] LOCAL SYNC COMPLETED in ${DURATION}s with ${#ERRORS[@]} error(s): ${ERRORS[*]}"
  exit 1
fi
echo "=========================================="
