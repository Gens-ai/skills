# Wazuh (off-box HIDS / SIEM) — deferred upgrade

Wazuh is the highest-value detection tool: file-integrity monitoring (FIM), log analysis, rootkit/malware detection, and active alerting. It catches webshells, modified front controllers (`index.php`), cron/`authorized_keys` changes, and miner processes — exactly the 2026 incident's signatures.

## Why it's not in the base install
The **manager + indexer + dashboard want 2–4 GB RAM** and real CPU. Putting that on a small app droplet will OOM it and, worse, a **root attacker on the same box can disable the manager and wipe its data**. So:

- **Run ONE Wazuh manager on its own dedicated droplet** (≥4 GB). It is shared across all your servers.
- **Install only the light agent** on each monitored server — it ships events to the off-box manager. A compromise of a monitored box can't reach back and tamper with the manager's history.
- **Also stream the manager's `alerts.json` → the same B2 immutable bucket** for tamper-proof long-term retention.

## Sketch (when you decide to do it)
1. Stand up a `wazuh-manager` droplet (≥4 GB). Install the all-in-one (manager + indexer + dashboard) per Wazuh's official quickstart. Lock the dashboard behind the firewall / VPN, not the public internet.
2. On each monitored server: install `wazuh-agent`, point it at the manager's IP, register.
3. Enable on each agent: **FIM** on web roots (`/srv/*/`, docroots), nginx/PHP logs, **rootcheck**.
4. **Active response / alerting → Pushover** for high-severity rules (new file in a docroot, cron/`authorized_keys` change, rootcheck hit). Pushover is the out-of-band safety net — it leaves the box before an attacker can suppress anything.
5. Ship the manager's `alerts.json` → B2 (rclone, same write-only pattern).

## Honest limitation
Even with an off-box manager, a root attacker can stop the local *agent* → you lose *future* detection on that host during the compromise (but keep all *past* evidence, and the real-time Pushover alert already fired). Fully tamper-proof ongoing detection is the manager being off-box + alerts leaving instantly. That's the design above.

Until Wazuh is up, **Netdata + CrowdSec + immutable B2 log shipping** cover the bulk of detection + evidence.
