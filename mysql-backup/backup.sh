#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=/backups
START_TIME=$(date +%s)
RESULTS_FILE="${BACKUP_RESULTS_FILE:-/tmp/backup_results}"
> "$RESULTS_FILE"

echo "=========================================="
echo "[$(date)] BACKUP STARTED"
echo "[$(date)] Databases: $DB_NAMES"
echo "[$(date)] Server: $DB_SERVER:$DB_PORT"
echo "=========================================="

IFS=' ' read -ra DATABASES <<< "$DB_NAMES"
ERRORS=()

for DB in "${DATABASES[@]}"; do
  DB_DIR="$BACKUP_DIR/$DB"
  mkdir -p "$DB_DIR"
  FILENAME="$DB_DIR/$DB-$TIMESTAMP.sql.gz"
  TMPFILE="$FILENAME.tmp"
  DB_START=$(date +%s)
  echo "[$(date)] Backing up $DB -> $FILENAME"
  if mysqldump \
    -h "$DB_SERVER" \
    -P "$DB_PORT" \
    -u "$DB_USER" \
    -p"$DB_PASS" \
    --single-transaction \
    --routines \
    --triggers \
    "$DB" | gzip > "$TMPFILE"; then
    mv "$TMPFILE" "$FILENAME"
    SIZE=$(du -h "$FILENAME" | cut -f1)
    DURATION=$(( $(date +%s) - DB_START ))
    echo "$DB|ok|$SIZE|${DURATION}s" >> "$RESULTS_FILE"
    echo "[$(date)] Done: $FILENAME ($SIZE)"
  else
    rm -f "$TMPFILE"
    echo "$DB|fail||" >> "$RESULTS_FILE"
    echo "[$(date)] ERROR: Failed to backup $DB"
    ERRORS+=("$DB")
  fi
done

if [ "${DB_CLEANUP:-false}" = "true" ]; then
  DELETED=$(find "$BACKUP_DIR" -name "*.sql.gz" -type f -mmin "+$((CLEANUP_TIME / 60))" -print -delete 2>/dev/null | wc -l)
  echo "[$(date)] Cleaned up $DELETED old backup file(s)"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "=========================================="
if [ ${#ERRORS[@]} -eq 0 ]; then
  echo "[$(date)] BACKUP COMPLETED in ${DURATION}s - ${#DATABASES[@]} database(s)"
else
  echo "[$(date)] BACKUP COMPLETED in ${DURATION}s with ${#ERRORS[@]} error(s): ${ERRORS[*]}"
  exit 1
fi
echo "=========================================="
