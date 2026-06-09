#!/usr/bin/env bash
# Netdata: real-time metrics + anomaly alerts, dashboard bound to localhost, Pushover alerting.
# Reads PUSHOVER_TOKEN / PUSHOVER_USER from /etc/server-security/config. Run as root.
set -euo pipefail
CONFIG=/etc/server-security/config
[ -f "$CONFIG" ] || { echo "ERROR: $CONFIG missing. Copy templates/server-security.config.example and fill it in."; exit 1; }
# shellcheck disable=SC1090
source "$CONFIG"
: "${PUSHOVER_TOKEN:?set PUSHOVER_TOKEN in $CONFIG}"
: "${PUSHOVER_USER:?set PUSHOVER_USER in $CONFIG}"

# 1) install (idempotent)
if command -v netdata >/dev/null 2>&1; then
  echo "netdata already installed: $(netdata -v 2>/dev/null | head -1)"
else
  wget -qO /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh
  sh /tmp/netdata-kickstart.sh --dont-wait --disable-telemetry --stable-channel --non-interactive
fi

# 2) bind dashboard to localhost only (defense-in-depth on top of ufw)
cat > /etc/netdata/netdata.conf <<'EOF'
[web]
    bind to = 127.0.0.1
EOF

# 3) Pushover notifications
STOCK=/usr/lib/netdata/conf.d/health_alarm_notify.conf
DEST=/etc/netdata/health_alarm_notify.conf
[ -f "$DEST" ] || cp "$STOCK" "$DEST"
sed -i \
  -e "s|^SEND_PUSHOVER=.*|SEND_PUSHOVER=\"YES\"|" \
  -e "s|^PUSHOVER_APP_TOKEN=.*|PUSHOVER_APP_TOKEN=\"${PUSHOVER_TOKEN}\"|" \
  -e "s|^DEFAULT_RECIPIENT_PUSHOVER=.*|DEFAULT_RECIPIENT_PUSHOVER=\"${PUSHOVER_USER}\"|" \
  "$DEST"
chown root:netdata "$DEST"; chmod 640 "$DEST"

systemctl restart netdata
sleep 3
echo "=== netdata active: $(systemctl is-active netdata) ==="
echo "=== listening (expect 127.0.0.1:19999 ONLY) ==="
ss -tlnp | grep 19999 || echo "(19999 not listening yet — check 'journalctl -u netdata')"

echo "=== sending Pushover test alert (expect 3 phone notifications) ==="
/usr/libexec/netdata/plugins.d/alarm-notify.sh test 2>&1 | grep -iE "sent pushover|fail" || true
echo "Done. View dashboard via SSH tunnel: ssh -L 19999:localhost:19999 root@SERVER  then http://localhost:19999"
