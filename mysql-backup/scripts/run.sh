#!/bin/bash
set -euo pipefail

> /tmp/backup_results
> /tmp/upload_results

BACKUP_OK=false
UPLOAD_OK=false

if /scripts/backup.sh >> /var/log/backup.log 2>&1; then
  BACKUP_OK=true
fi

if [ "$BACKUP_OK" = "true" ]; then
  /scripts/sync-local.sh >> /var/log/sync-local.log 2>&1 || true

  if /scripts/upload.sh >> /var/log/upload.log 2>&1; then
    UPLOAD_OK=true
  fi
fi

HOST="${ALERT_HOSTNAME:-${HOSTNAME:-unknown}}"
NOW=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

BACKUP_VALUE=""
if [ -s /tmp/backup_results ]; then
  while IFS='|' read -r key status size duration; do
    [ -z "$key" ] && continue
    if [ "$status" = "ok" ]; then
      BACKUP_VALUE="${BACKUP_VALUE}✅ Gotcha! ${key} — ${size} (${duration})\n"
    else
      BACKUP_VALUE="${BACKUP_VALUE}❌ Oh no! ${key} escaped!\n"
    fi
  done < /tmp/backup_results
else
  BACKUP_VALUE="❌ No Pokémon found!\n"
fi
BACKUP_VALUE="${BACKUP_VALUE%\\n}"

UPLOAD_VALUE=""
if [ -s /tmp/upload_results ]; then
  FIRST=$(head -1 /tmp/upload_results)
  if [[ "$FIRST" == "_skipped|skip" ]]; then
    UPLOAD_VALUE="⏭️ PC Storage not configured"
  else
    while IFS='|' read -r key status; do
      [ -z "$key" ] && continue
      if [ "$status" = "ok" ]; then
        UPLOAD_VALUE="${UPLOAD_VALUE}✅ ${key} → safely stored in PC!\n"
      else
        UPLOAD_VALUE="${UPLOAD_VALUE}❌ ${key} → PC connection error!\n"
      fi
    done < /tmp/upload_results
    UPLOAD_VALUE="${UPLOAD_VALUE%\\n}"
  fi
else
  UPLOAD_VALUE="⏭️ Pokémon fainted, skipping PC transfer"
fi

if [ "$BACKUP_OK" = "true" ] && [ "$UPLOAD_OK" = "true" ]; then
  TITLE="🎮 Gotcha! All databases were caught!"
  DESC="Backup adventure complete, Trainer! All data safely stored. 🏆\\nTrainer: ${HOST}"
  COLOR=3066993
  GIF_URL="${GIF_URL_SUCCESS:-}"
elif [ "$BACKUP_OK" = "true" ]; then
  TITLE="⚠️ Caught but failed to send to PC Storage!"
  DESC="The Pokéballs worked, but PC connection failed. Check your S3 config! 🔧\\nTrainer: ${HOST}"
  COLOR=15844367
  GIF_URL="${GIF_URL_WARNING:-}"
else
  TITLE="💀 Oh no! The backup fainted!"
  DESC="Your backup Pokémon couldnt be caught. Check the DB connection! 🏥\\nTrainer: ${HOST}"
  COLOR=15548997
  GIF_URL="${GIF_URL_FAILURE:-}"
fi

IMAGE_JSON=""
if [ -n "$GIF_URL" ]; then
  IMAGE_JSON=$(printf ',"image":{"url":"%s"}' "$GIF_URL")
fi

PAYLOAD=$(printf '{"embeds":[{"title":"%s","description":"%s","color":%d,"fields":[{"name":"⚾ Pokéball Throws","value":"%s","inline":false},{"name":"💻 PC Storage (S3)","value":"%s","inline":false}],"footer":{"text":"Gotta back em all! 🎮"},"timestamp":"%s"%s}]}' \
  "$TITLE" "$DESC" "$COLOR" "$BACKUP_VALUE" "$UPLOAD_VALUE" "$NOW" "$IMAGE_JSON")

/scripts/notify.sh --json "$PAYLOAD" || true

if [ "$BACKUP_OK" = "false" ] || [ "$UPLOAD_OK" = "false" ]; then
  exit 1
fi
