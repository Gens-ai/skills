#!/usr/bin/env bash
# Idempotent swapfile. Cheap OOM insurance for small droplets. Run as root.
# Usage: install-swap.sh [SIZE]   (default 2G)
set -euo pipefail
SIZE="${1:-2G}"

if swapon --show | grep -q .; then
  echo "swap already present:"; swapon --show; exit 0
fi

echo "creating ${SIZE} swapfile..."
fallocate -l "$SIZE" /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count="$(( ${SIZE%G} * 1024 ))"
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
sysctl -p /etc/sysctl.d/99-swappiness.conf >/dev/null

echo "--- result ---"; swapon --show; free -h
