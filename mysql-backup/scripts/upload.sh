#!/bin/bash
set -euo pipefail

RESULTS_FILE="${UPLOAD_RESULTS_FILE:-/tmp/upload_results}"

if [ -z "${DO_ACCESS_KEY:-}" ] || [ -z "${DO_SECRET_KEY:-}" ]; then
  echo "[$(date)] DigitalOcean Spaces not configured, skipping upload"
  echo "_skipped|skip" > "$RESULTS_FILE"
  exit 0
fi

SERVERS_FILE="${SERVERS_FILE:-/config/servers.json}"
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
no_check_bucket = true
EOF

echo "=========================================="
echo "[$(date)] UPLOAD TO DIGITALOCEAN SPACES STARTED"
echo "[$(date)] Bucket: $DO_BUCKET/$DO_PATH"
echo "=========================================="

ERRORS=()

if [ -f "$SERVERS_FILE" ]; then
  SERVER_COUNT=$(jq length "$SERVERS_FILE")
else
  SERVER_COUNT=0
fi

for SERVER_INDEX in $(seq 0 $((SERVER_COUNT - 1))); do
  SERVER_NAME=$(jq -r ".[$SERVER_INDEX].name" "$SERVERS_FILE")
  SERVER_S3_PATH=$(jq -r ".[$SERVER_INDEX].s3_path // empty" "$SERVERS_FILE")
  S3_PREFIX="${SERVER_S3_PATH:-$DO_PATH}"
  DB_COUNT=$(jq ".[$SERVER_INDEX].databases | length" "$SERVERS_FILE")

  for DB_INDEX in $(seq 0 $((DB_COUNT - 1))); do
    DB=$(jq -r ".[$SERVER_INDEX].databases[$DB_INDEX]" "$SERVERS_FILE")
    SRC="$BACKUP_DIR/$SERVER_NAME/$DB"
    DEST="spaces:$DO_BUCKET/$S3_PREFIX/$SERVER_NAME/$DB"

    echo "[$(date)] Uploading $SERVER_NAME/$DB..."
    if rclone copy "$SRC/" "$DEST/" \
      --include "*.sql.gz" \
      --ignore-checksum \
      --transfers 4; then
      echo "$SERVER_NAME/$DB|ok" >> "$RESULTS_FILE"
      echo "[$(date)] Upload done: $SERVER_NAME/$DB"
    else
      echo "$SERVER_NAME/$DB|fail" >> "$RESULTS_FILE"
      echo "[$(date)] ERROR: Upload failed for $SERVER_NAME/$DB"
      ERRORS+=("$SERVER_NAME/$DB")
    fi
  done
done

if [ "${DO_CLEANUP:-false}" = "true" ]; then
  echo "[$(date)] Cleaning up Spaces files older than ${DO_CLEANUP_DAYS:-30} days..."
  for SERVER_INDEX in $(seq 0 $((SERVER_COUNT - 1))); do
    SERVER_NAME=$(jq -r ".[$SERVER_INDEX].name" "$SERVERS_FILE")
    SERVER_S3_PATH=$(jq -r ".[$SERVER_INDEX].s3_path // empty" "$SERVERS_FILE")
    S3_PREFIX="${SERVER_S3_PATH:-$DO_PATH}"
    DB_COUNT=$(jq ".[$SERVER_INDEX].databases | length" "$SERVERS_FILE")
    for DB_INDEX in $(seq 0 $((DB_COUNT - 1))); do
      DB=$(jq -r ".[$SERVER_INDEX].databases[$DB_INDEX]" "$SERVERS_FILE")
      rclone delete "spaces:$DO_BUCKET/$S3_PREFIX/$SERVER_NAME/$DB/" \
        --min-age "${DO_CLEANUP_DAYS:-30}d" \
        --include "*.sql.gz" 2>/dev/null || true
    done
  done
  echo "[$(date)] Spaces cleanup done"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "=========================================="
if [ ${#ERRORS[@]} -eq 0 ]; then
  echo "[$(date)] UPLOAD COMPLETED in ${DURATION}s — $SERVER_COUNT server(s)"
else
  echo "[$(date)] UPLOAD COMPLETED in ${DURATION}s with ${#ERRORS[@]} error(s): ${ERRORS[*]}"
  exit 1
fi
echo "=========================================="
