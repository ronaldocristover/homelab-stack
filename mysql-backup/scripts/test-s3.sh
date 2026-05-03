#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "S3 / DigitalOcean Spaces connectivity test"
echo "=========================================="

# ── Validate required vars ───────────────────────────────────────────────────
MISSING=()
for VAR in DO_ACCESS_KEY DO_SECRET_KEY DO_ENDPOINT DO_REGION DO_BUCKET DO_PATH; do
  [ -z "${!VAR:-}" ] && MISSING+=("$VAR")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "ERROR: missing required env vars: ${MISSING[*]}"
  exit 1
fi

echo "  Endpoint : $DO_ENDPOINT"
echo "  Region   : $DO_REGION"
echo "  Bucket   : $DO_BUCKET"
echo "  Path     : $DO_PATH"
echo ""

# ── Write rclone config ───────────────────────────────────────────────────────
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

# ── 1. Bucket reachability ────────────────────────────────────────────────────
echo "[1/3] Checking bucket access..."
if   rclone ls "spaces:$DO_BUCKET" --max-depth 1 2>&1 | head -5; then
  echo "PASS: bucket is reachable"
else
  echo "FAIL: cannot list bucket — check DO_ENDPOINT/DO_BUCKET/credentials"
  exit 1
fi

echo ""

# ── 2. Write test ─────────────────────────────────────────────────────────────
TEST_KEY="$DO_PATH/.s3-test-$(date +%s)"
TEST_FILE="/tmp/s3_test_file"
echo "s3-write-test" > "$TEST_FILE"

echo "[2/3] Writing test object: $DO_BUCKET/$TEST_KEY ..."
if rclone copyto "$TEST_FILE" "spaces:$DO_BUCKET/$TEST_KEY" 2>&1; then
  echo "PASS: write succeeded"
else
  echo "FAIL: write failed — check bucket permissions"
  rm -f "$TEST_FILE"
  exit 1
fi

echo ""

# ── 3. Delete test ────────────────────────────────────────────────────────────
echo "[3/3] Deleting test object..."
if rclone deletefile "spaces:$DO_BUCKET/$TEST_KEY" 2>&1; then
  echo "PASS: delete succeeded"
else
  echo "WARN: delete failed — test object left at $DO_BUCKET/$TEST_KEY"
fi

rm -f "$TEST_FILE"

echo ""
echo "=========================================="
echo "ALL CHECKS PASSED — S3 upload should work"
echo "=========================================="
