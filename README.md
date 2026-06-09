# skills

Reusable [Claude Code](https://claude.com/claude-code) skills.

## Skills

### [`debian-server-security`](./debian-server-security)
Stand up a battle-tested detection + alerting + immutable-backup stack on a self-managed **Debian/Ubuntu** VPS:

- **Netdata** — real-time metrics + anomaly alerts (dashboard bound to localhost).
- **CrowdSec** — behavioral IPS with a firewall bouncer + community blocklist.
- **Backblaze B2** — immutable (Object Lock) **off-box backups + hourly log shipping**, via a **write-only** key so a stolen credential can't read or erase history.
- **Pushover** — out-of-band alerts that leave the box before an attacker can silence them.
- **Wazuh** — optional off-box HIDS/SIEM (design notes included).

It bakes in the gotchas that cost real time — especially the rclone + write-only-B2 trap (use the S3 backend, `no_check_bucket`/`no_head`, `--no-check-dest`) — plus the restore-key-off-box rule and WAL-safe DB dumps. See [its SKILL.md](./debian-server-security/SKILL.md).

> Scope: written for Debian-family systems (apt, systemd, ufw). The tools are cross-distro; the scripts assume Debian/Ubuntu.

### [`dev-servers`](./dev-servers)
Start or stop local dev servers the safe way. The value is the **lifecycle discipline**, not a magic start command:

- **Defer to a project skill** — if the repo ships its own `local-servers` skill, that wins.
- **Tear down first** — a bundled `stop-dev` frees ports (stops Docker containers, kills Vite, stops configured system services) before starting, killing the usual "port already in use" pain.
- **Detect the stack** — Laravel Sail, Laravel, Node/npm, or Makefile — then start it and report ports.

Self-contained (no external dependencies). See [its SKILL.md](./dev-servers/SKILL.md).

## License

[MIT](./LICENSE) © 2026 Joe Kneeland
