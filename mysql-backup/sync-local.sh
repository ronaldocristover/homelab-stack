#!/bin/bash
set -euo pipefail

if [ "${LOCAL_BACKUP_ENABLED:-false}" != "true" ]; then
  echo "[$(date)] Local HDD backup not enabled, skipping"
  exit 0
fi

LOCAL_DIR=/backups-hdd
BACKUP_DIR=/backups
START_TIME=$(date +%s)

echo "=========================================="
echo "[$(date)] LOCAL HDD SYNC STARTED"
echo "[$(date)] Destination: $LOCAL_DIR"
echo "=========================================="

IFS=' ' read -ra DATABASES <<< "$DB_NAMES"
ERRORS=()

for DB in "${DATABASES[@]}"; do
  mkdir -p "$LOCAL_DIR/$DB"
  echo "[$(date)] Syncing $DB -> $LOCAL_DIR/$DB/"
  if rsync -a "$BACKUP_DIR/$DB/" "$LOCAL_DIR/$DB/"; then
    SIZE=$(du -sh "$LOCAL_DIR/$DB" | cut -f1)
    echo "[$(date)] Sync done: $DB ($SIZE)"
  else
    echo "[$(date)] ERROR: Sync failed for $DB"
    ERRORS+=("$DB")
  fi
done

if [ "${LOCAL_CLEANUP:-false}" = "true" ]; then
  DELETED=$(find "$LOCAL_DIR" -name "*.sql.gz" -type f -mmin "+$((LOCAL_CLEANUP_DAYS * 1440))" -print -delete 2>/dev/null | wc -l)
  echo "[$(date)] Cleaned up $DELETED old file(s) from local HDD"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "=========================================="
if [ ${#ERRORS[@]} -eq 0 ]; then
  echo "[$(date)] LOCAL SYNC COMPLETED in ${DURATION}s - ${#DATABASES[@]} database(s)"
else
  echo "[$(date)] LOCAL SYNC COMPLETED in ${DURATION}s with ${#ERRORS[@]} error(s): ${ERRORS[*]}"
  exit 1
fi
echo "=========================================="
