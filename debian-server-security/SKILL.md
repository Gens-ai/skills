---
name: debian-server-security
description: Set up the standard detection + alerting + immutable-backup stack on a self-managed Debian or Ubuntu server (Netdata, CrowdSec, Backblaze B2 immutable backups & log shipping, Pushover out-of-band alerts, optional off-box Wazuh). Use when asked to harden/secure/monitor a Debian/Ubuntu VPS, add backups or off-box log retention to a server, replicate the same hardened security setup across multiple servers, or stand up monitoring/alerting on a new droplet. Captures the exact commands, configs, and gotchas (esp. rclone + write-only B2 keys) proven in production.
---

# Debian / Ubuntu Server Security Tooling

A repeatable hardening stack for a **self-managed Debian/Ubuntu VPS**: real-time metrics + anomaly alerts (Netdata), an IPS that blocks attackers (CrowdSec), **immutable off-box backups + log shipping** to Backblaze B2 (survives a root compromise), and **out-of-band Pushover alerts** (leave the box before an attacker can silence them). Optional: an off-box Wazuh HIDS/SIEM.

Proven in production during a 2026 incident response, then generalized so any server gets the same setup without rediscovering the traps.

> **Scope:** written for **Debian-family** systems (apt, systemd, ufw, `/var/log/{auth.log,syslog}`). The tools (Netdata, CrowdSec, rclone, Pushover) are cross-distro, but the scripts assume Debian/Ubuntu. On RHEL/Fedora swap `apt`→`dnf`, `ufw`→`firewalld`, the nftables bouncer, and `secure`/`messages` (or journald) log sources.

## Why this stack (the principles that matter as much as the tools)
- **Ship logs/backups OFF-box** — a root attacker can wipe local logs and disable a local agent. The only trustworthy copy is one they can't reach or delete.
- **Make it immutable** — B2 Object Lock means uploaded objects can't be deleted/overwritten for the retention window, *even with the credentials on the box*.
- **Alert out-of-band** — Pushover pushes leave the host the instant something trips, so a compromised host can't suppress the warning.
- **Least privilege on the exfil path** — the box gets a **write-only** B2 key. A stolen key can't read your backups or erase history.

## ⚠️ Read first — RAM constraint drives the plan
Small droplets are RAM-bound. Check before installing anything:
```
ssh root@SERVER 'free -h; nproc; df -h /; swapon --show || echo "(no swap)"'
```
- **Always add swap first** (`scripts/install-swap.sh`) — cheap OOM insurance.
- **Netdata (~150 MB) + CrowdSec (~100 MB)** fit on ~1–2 GB boxes.
- **On-box Wazuh wants 2–4 GB** and a real CPU — do NOT put the Wazuh *manager* on a small box. Run the manager on its **own droplet** and only the light agent on each server (also more tamper-resistant: a root attacker on a monitored box can't reach back and wipe the manager). See `reference/wazuh-notes.md`.

## Order of work
1. **Swap** — `scripts/install-swap.sh` (2 GB default).
2. **Per-server config** — copy `templates/server-security.config.example` → `/etc/server-security/config` (chmod 600), fill in Pushover + B2 bucket. NEVER commit this anywhere.
3. **Netdata** — `scripts/install-netdata.sh` (binds dashboard to 127.0.0.1 only, wires Pushover, sends a test alert).
4. **CrowdSec** — `scripts/install-crowdsec.sh` (engine + iptables firewall bouncer + community blocklist; auto-detects nginx/sshd/mariadb/etc.).
5. **B2 plumbing** — create the bucket + write-only key (one-time, web UI — `reference/backblaze-b2-setup.md`), then `scripts/setup-b2-rclone.sh` on the box.
6. **Backups** — customize the `do_backup()` block in `scripts/b2-backup.sh` for this server's data, deploy it.
7. **Log shipping** — `scripts/b2-ship-logs.sh` (nginx/auth/syslog/CrowdSec; standard paths, usually no edits).
8. **Schedule** — install `templates/cron-server-security` → `/etc/cron.d/server-security`.
9. **(Optional) Wazuh agent** — once a manager droplet exists.

All scripts are idempotent and safe to re-run. Run them as root on the target box. Copy each up with `scp scripts/X root@SERVER:/tmp/ && ssh root@SERVER 'bash /tmp/X'`, or paste inline.

## Verify (do this every time)
- `systemctl is-active netdata crowdsec crowdsec-firewall-bouncer cron`
- Netdata bound to localhost only: `ss -tlnp | grep 19999` → must show `127.0.0.1:19999`, never `0.0.0.0`.
- ufw allows only what you need: `ufw status` → typically 22/80/443.
- CrowdSec parsing logs: `cscli metrics | grep -i nginx` (lines read & parsed) and `cscli bouncers list` (bouncer present + valid).
- Pushover works: `/usr/libexec/netdata/plugins.d/alarm-notify.sh test` → you get 3 phone notifications.
- First backup + log ship ran: `/usr/local/sbin/b2-backup.sh && /usr/local/sbin/b2-ship-logs.sh` (exit 0).
- **B2 objects landed** — the box key is write-only and CAN'T list/read, so verify in the **B2 web console** (Browse Files): a dated bundle under `<prefix>/backups/…` and files under `<prefix>/logs/…`, and the object shows an **Object Lock retention date**. If the lock date is missing, the bucket's default retention wasn't set — fix that.

## 🔑 Gotchas (the expensive lessons — don't relearn them)
- **rclone + write-only B2 key → use the S3 backend, NOT native `b2`.** Native `b2` calls `b2_create_bucket` on upload and does a HEAD-for-download, both of which a write-only key 401s on — even though the `PutObject` itself would succeed. The S3 backend with the right flags avoids all of it. `setup-b2-rclone.sh` writes the correct config:
  - `type = s3`, `provider = Other`, `endpoint = s3.<region>.backblazeb2.com`, `region = <region>`
  - `no_check_bucket = true` (skip bucket existence/creation calls)
  - `no_head = true` (skip the post-upload read-back the write-only key can't do)
  - and run uploads with **`--no-check-dest`**.
- **The box key must be Write-Only** (caps: `listBuckets` + `writeFiles`; NO `deleteFiles`). Verified behavior: list/read/delete all 401. That's correct — it's the point.
- **Object Lock provides the real immutability**, independent of the key. Default retention (e.g. 90 days, Governance) on the bucket → every uploaded object inherits the lock. Governance defeats the box-compromise threat; Compliance also defeats account-credential compromise but locks *you* out of deletes for the window too.
- **Restore needs a DIFFERENT key, kept OFF the box.** Write-only can't restore. Make a **Read-Only** B2 key and keep it only on your workstation / password manager — never in a server cron or `.env`. If the box is owned, the attacker still can't read your backups.
- **Use unique, dated object names** (the scripts do). Object Lock blocks overwrites, so re-uploading the same path fails. Dated paths also give point-in-time history.
- **Consistent DB dumps:** MariaDB/MySQL `--single-transaction`; SQLite `sqlite3 .backup` (WAL-safe), not a raw `cp`.
- **Netdata:** `health_alarm_notify.conf` holds the Pushover token → `chmod 640 root:netdata`. Bind to `127.0.0.1` in `netdata.conf` as defense-in-depth even though ufw blocks 19999.
- **CrowdSec firewall bouncer** (iptables flavor) coexists fine with ufw on Ubuntu 24.04. It registers as a local bouncer; confirm with `cscli bouncers list`.
- **Pushover creds** are reusable across all your servers (one app token + your user key). If migrating off an old box, grab them before it's destroyed.

## Multi-server layout (B2)
Two sane options for N servers — pick one and be consistent:
- **One shared bucket, per-server prefix** (default here): bucket `your-org-logs-n-backup`, each server writes under `<hostname>/…` via `B2_PREFIX`. One bucket to manage; one Object Lock policy. Each server still gets its **own** write-only key (so revoking one server doesn't touch others).
- **One bucket per server**: stronger blast-radius isolation, more buckets/keys to manage. Use if servers belong to different trust domains.
Either way: **one write-only key per server** (never share a key across boxes), and **one read-only restore key total**, off-box.

## Files in this skill
- `scripts/install-swap.sh` — idempotent 2 GB swapfile + swappiness=10.
- `scripts/install-netdata.sh` — Netdata + localhost bind + Pushover + test alert.
- `scripts/install-crowdsec.sh` — CrowdSec engine + firewall bouncer + collections + CAPI.
- `scripts/setup-b2-rclone.sh` — installs rclone, writes the correct S3/write-only `rclone.conf`.
- `scripts/b2-backup.sh` — nightly backup; **edit the `do_backup()` block** per server (helpers provided for mysql/postgres/sqlite/files/dirs).
- `scripts/b2-ship-logs.sh` — hourly immutable log snapshot (nginx/auth/syslog/CrowdSec).
- `templates/server-security.config.example` — per-server `/etc/server-security/config`.
- `templates/cron-server-security` — `/etc/cron.d/server-security` schedule.
- `reference/backblaze-b2-setup.md` — one-time bucket + key creation (web UI).
- `reference/wazuh-notes.md` — off-box Wazuh design (deferred upgrade).
