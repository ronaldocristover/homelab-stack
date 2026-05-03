#!/bin/bash
set -euo pipefail

SERVERS_FILE="${SERVERS_FILE:-/config/servers.json}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=/backups-hdd
START_TIME=$(date +%s)
RESULTS_FILE="${BACKUP_RESULTS_FILE:-/tmp/backup_results}"
> "$RESULTS_FILE"

if [ ! -f "$SERVERS_FILE" ]; then
  echo "[$(date)] ERROR: Servers file not found: $SERVERS_FILE"
  echo "_no_servers|fail||" >> "$RESULTS_FILE"
  exit 1
fi

SERVER_COUNT=$(jq length "$SERVERS_FILE")

echo "=========================================="
echo "[$(date)] BACKUP STARTED"
echo "[$(date)] Servers: $SERVER_COUNT"
echo "=========================================="

ERRORS=()

for SERVER_INDEX in $(seq 0 $((SERVER_COUNT - 1))); do
  SERVER_NAME=$(jq -r ".[$SERVER_INDEX].name" "$SERVERS_FILE")
  SERVER_HOST=$(jq -r ".[$SERVER_INDEX].host" "$SERVERS_FILE")
  SERVER_PORT=$(jq -r ".[$SERVER_INDEX].port // 3306" "$SERVERS_FILE")
  SERVER_USER=$(jq -r ".[$SERVER_INDEX].user" "$SERVERS_FILE")
  SERVER_PASS=$(jq -r ".[$SERVER_INDEX].pass" "$SERVERS_FILE")

  DB_COUNT=$(jq ".[$SERVER_INDEX].databases | length" "$SERVERS_FILE")
  echo "[$(date)] ── Server: $SERVER_NAME ($SERVER_HOST:$SERVER_PORT) — $DB_COUNT database(s)"

  for DB_INDEX in $(seq 0 $((DB_COUNT - 1))); do
    DB=$(jq -r ".[$SERVER_INDEX].databases[$DB_INDEX]" "$SERVERS_FILE")
    DB_DIR="$BACKUP_DIR/$SERVER_NAME/$DB"
    mkdir -p "$DB_DIR"
    FILENAME="$DB_DIR/$DB-$TIMESTAMP.sql.gz"
    TMPFILE="$FILENAME.tmp"
    DB_START=$(date +%s)

    echo "[$(date)] Backing up $SERVER_NAME/$DB -> $FILENAME"
    if mysqldump \
      -h "$SERVER_HOST" \
      -P "$SERVER_PORT" \
      -u "$SERVER_USER" \
      -p"$SERVER_PASS" \
      --single-transaction \
      --routines \
      --triggers \
      "$DB" | gzip > "$TMPFILE"; then
      mv "$TMPFILE" "$FILENAME"
      SIZE=$(du -h "$FILENAME" | cut -f1)
      DURATION=$(( $(date +%s) - DB_START ))
      echo "$SERVER_NAME/$DB|ok|$SIZE|${DURATION}s" >> "$RESULTS_FILE"
      echo "[$(date)] Done: $FILENAME ($SIZE)"
    else
      rm -f "$TMPFILE"
      echo "$SERVER_NAME/$DB|fail||" >> "$RESULTS_FILE"
      echo "[$(date)] ERROR: Failed to backup $SERVER_NAME/$DB"
      ERRORS+=("$SERVER_NAME/$DB")
    fi
  done
done

if [ "${DB_CLEANUP:-false}" = "true" ]; then
  DELETED=$(find "$BACKUP_DIR" -name "*.sql.gz" -type f -mmin "+$((CLEANUP_TIME / 60))" -print -delete 2>/dev/null | wc -l)
  echo "[$(date)] Cleaned up $DELETED old backup file(s)"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "=========================================="
if [ ${#ERRORS[@]} -eq 0 ]; then
  TOTAL_DBS=$(find "$BACKUP_DIR" -name "*.sql.gz" -newer "$RESULTS_FILE" 2>/dev/null | wc -l)
  echo "[$(date)] BACKUP COMPLETED in ${DURATION}s — $SERVER_COUNT server(s)"
else
  echo "[$(date)] BACKUP COMPLETED in ${DURATION}s with ${#ERRORS[@]} error(s): ${ERRORS[*]}"
  exit 1
fi
echo "=========================================="
