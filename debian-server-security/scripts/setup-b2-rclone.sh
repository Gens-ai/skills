#!/usr/bin/env bash
# Install rclone + write the CORRECT rclone.conf for a Backblaze B2 WRITE-ONLY key.
# Uses the S3 backend (NOT native b2) so a write-only key works — see SKILL.md gotchas.
#
# Provide the key via env or args (create them per reference/backblaze-b2-setup.md):
#   B2_KEY_ID=...  B2_APP_KEY=...  B2_ENDPOINT=s3.us-east-005.backblazeb2.com  setup-b2-rclone.sh
# Run as root. The remote is named 'b2'.
set -euo pipefail
B2_KEY_ID="${B2_KEY_ID:-${1:-}}"
B2_APP_KEY="${B2_APP_KEY:-${2:-}}"
B2_ENDPOINT="${B2_ENDPOINT:-${3:-}}"   # e.g. s3.us-east-005.backblazeb2.com
: "${B2_KEY_ID:?need B2_KEY_ID}"; : "${B2_APP_KEY:?need B2_APP_KEY}"; : "${B2_ENDPOINT:?need B2_ENDPOINT (s3.<region>.backblazeb2.com)}"
REGION="$(echo "$B2_ENDPOINT" | sed -E 's/^s3\.([^.]+)\..*/\1/')"

command -v rclone >/dev/null 2>&1 || { echo "installing rclone..."; curl -s https://rclone.org/install.sh | bash; }

mkdir -p /root/.config/rclone
cat > /root/.config/rclone/rclone.conf <<EOF
[b2]
type = s3
provider = Other
access_key_id = ${B2_KEY_ID}
secret_access_key = ${B2_APP_KEY}
endpoint = ${B2_ENDPOINT}
region = ${REGION}
no_check_bucket = true
no_head = true
EOF
chmod 700 /root/.config/rclone; chmod 600 /root/.config/rclone/rclone.conf
echo "wrote /root/.config/rclone/rclone.conf (region=${REGION})"

# Smoke test: write-only key should be able to PutObject. (lsd works because the key has listBuckets.)
BUCKET="$(grep -E '^B2_BUCKET=' /etc/server-security/config 2>/dev/null | cut -d'"' -f2 | sed 's/^b2://')"
if [ -n "$BUCKET" ]; then
  echo "smoke-test upload to ${BUCKET}/_verify/ ..."
  echo "rclone write-only test $(date -u +%FT%TZ)" > /tmp/b2-verify.txt
  if rclone copy /tmp/b2-verify.txt "b2:${BUCKET}/_verify/" --no-check-dest -v 2>&1 | tail -3; then
    echo ">>> PutObject OK. Verify in the B2 web console that _verify/b2-verify.txt exists AND shows an Object Lock date."
    echo ">>> (Can't verify here — write-only key can't list/read. A delete attempt SHOULD 401: that's correct.)"
  fi
  rm -f /tmp/b2-verify.txt
else
  echo "NOTE: set B2_BUCKET in /etc/server-security/config, then test: rclone copy <file> b2:<bucket>/_verify/ --no-check-dest"
fi
