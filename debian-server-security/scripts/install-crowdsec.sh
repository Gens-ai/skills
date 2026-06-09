#!/usr/bin/env bash
# CrowdSec: behavioral IPS (modern fail2ban). Engine + iptables firewall bouncer + community blocklist.
# Auto-detects running services (nginx/sshd/mariadb/...) and installs matching collections. Run as root.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# 1) repo + engine (idempotent)
if ! command -v cscli >/dev/null 2>&1; then
  curl -s https://install.crowdsec.net | sh
  apt-get install -y crowdsec
else
  echo "crowdsec already installed: $(cscli version 2>/dev/null | head -1)"
fi
systemctl enable --now crowdsec >/dev/null 2>&1 || true

# 2) make sure the common web collection is present (others auto-detected by 'cscli setup' at install)
cscli collections install crowdsecurity/nginx 2>/dev/null || true
cscli collections install crowdsecurity/sshd  2>/dev/null || true

# 3) firewall bouncer (iptables flavor; coexists with ufw on Ubuntu 24.04)
if ! systemctl list-unit-files | grep -q crowdsec-firewall-bouncer; then
  apt-get install -y crowdsec-firewall-bouncer-iptables
fi
systemctl enable --now crowdsec-firewall-bouncer >/dev/null 2>&1 || true

systemctl restart crowdsec
sleep 3
echo "=== status ==="
echo "engine:  $(systemctl is-active crowdsec)"
echo "bouncer: $(systemctl is-active crowdsec-firewall-bouncer)"
echo "=== collections ==="; cscli collections list 2>/dev/null | grep crowdsecurity || true
echo "=== bouncers (expect 1, valid) ==="; cscli bouncers list 2>/dev/null
echo "=== CAPI / community blocklist ==="; cscli capi status 2>&1 | tail -3 || echo "(register: cscli capi register && systemctl restart crowdsec)"
echo "=== acquisition (are logs flowing? run again in a minute if empty) ==="; cscli metrics 2>/dev/null | grep -iE "Source|nginx|sshd" | head -8 || true
