#!/bin/bash
set -euo pipefail

RESULTS_FILE="${UPLOAD_RESULTS_FILE:-/tmp/upload_results}"

if [ -z "${DO_ACCESS_KEY:-}" ] || [ -z "${DO_SECRET_KEY:-}" ]; then
  echo "[$(date)] DigitalOcean Spaces not configured, skipping upload"
  echo "_skipped|skip" > "$RESULTS_FILE"
  exit 0
fi

> "$RESULTS_FILE"

BACKUP_DIR=/backups
START_TIME=$(date +%s)

mkdir -p /root/.config/rclone
cat > /root/.config/rclone/rclone.conf <<EOF
[spaces]
type = s3
provider = DigitalOcean
access_key_id = ${DO_ACCESS_KEY}
secret_access_key = ${DO_SECRET_KEY}
endpoint = ${DO_ENDPOINT}
region = ${DO_REGION}
EOF

echo "=========================================="
echo "[$(date)] UPLOAD TO DIGITALOCEAN SPACES STARTED"
echo "[$(date)] Bucket: $DO_BUCKET/$DO_PATH"
echo "=========================================="

IFS=' ' read -ra DATABASES <<< "$DB_NAMES"
ERRORS=()

for DB in "${DATABASES[@]}"; do
  echo "[$(date)] Uploading $DB..."
  if rclone copy "$BACKUP_DIR/$DB/" "spaces:$DO_BUCKET/$DO_PATH/$DB/" \
    --include "*.sql.gz" \
    --checksum \
    --transfers 4; then
    echo "$DB|ok" >> "$RESULTS_FILE"
    echo "[$(date)] Upload done: $DB"
  else
    echo "$DB|fail" >> "$RESULTS_FILE"
    echo "[$(date)] ERROR: Upload failed for $DB"
    ERRORS+=("$DB")
  fi
done

if [ "${DO_CLEANUP:-false}" = "true" ]; then
  echo "[$(date)] Cleaning up Spaces files older than ${DO_CLEANUP_DAYS:-30} days..."
  for DB in "${DATABASES[@]}"; do
    rclone delete "spaces:$DO_BUCKET/$DO_PATH/$DB/" \
      --min-age "${DO_CLEANUP_DAYS:-30}d" \
      --include "*.sql.gz" 2>/dev/null || true
  done
  echo "[$(date)] Spaces cleanup done"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "=========================================="
if [ ${#ERRORS[@]} -eq 0 ]; then
  echo "[$(date)] UPLOAD COMPLETED in ${DURATION}s - ${#DATABASES[@]} database(s)"
else
  echo "[$(date)] UPLOAD COMPLETED in ${DURATION}s with ${#ERRORS[@]} error(s): ${ERRORS[*]}"
  exit 1
fi
echo "=========================================="
