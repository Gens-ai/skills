#!/usr/bin/env bash
# Hourly: snapshot security/access logs -> immutable B2 (tamper window <=1h).
# nginx, auth, syslog, CrowdSec. Standard Ubuntu paths — usually no edits needed.
# Reads B2_BUCKET / B2_PREFIX / PUSHOVER_* from /etc/server-security/config.
set -euo pipefail
source /etc/server-security/config
: "${B2_BUCKET:?}"
PREFIX="${B2_PREFIX:-$(hostname -s)}"

HOST="$(hostname -s)"
HOUR_PATH="$(date -u +%Y/%m/%d/%H)"
WORK="$(mktemp -d /tmp/b2logs.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

pushover() {
  curl -s --max-time 15 \
    --form-string "token=${PUSHOVER_TOKEN:-}" --form-string "user=${PUSHOVER_USER:-}" \
    --form-string "title=$1" --form-string "message=$2" --form-string "priority=1" \
    https://api.pushover.net/1/messages.json >/dev/null 2>&1 || true
}

# Edit this list if the server logs elsewhere.
LOGS=(/var/log/nginx/access.log /var/log/nginx/error.log /var/log/auth.log /var/log/syslog)
for f in "${LOGS[@]}"; do
  [ -f "$f" ] || continue
  cp "$f" "$WORK/$(echo "$f" | sed 's#^/var/log/##; s#/#_#g')" 2>/dev/null || true
done

# CrowdSec state, if present
if command -v cscli >/dev/null 2>&1; then
  cscli decisions list -o json > "$WORK/crowdsec_decisions.json" 2>/dev/null || true
  cscli alerts    list -o json > "$WORK/crowdsec_alerts.json"    2>/dev/null || true
fi

shopt -s nullglob
files=("$WORK"/*); [ ${#files[@]} -gt 0 ] || exit 0
gzip "$WORK"/* 2>/dev/null || true
if ! rclone copy "$WORK/" "${B2_BUCKET}/${PREFIX}/logs/${HOUR_PATH}/" --no-check-dest 2>&1; then
  pushover "B2 LOG SHIP FAILED on ${HOST}" "rclone upload of ${PREFIX}/logs/${HOUR_PATH} failed"
  exit 1
fi
echo "$(date -u +%FT%TZ) OK ${PREFIX}/logs/${HOUR_PATH}/ (${#files[@]} files)"
