# skills

Reusable [Claude Code](https://claude.com/claude-code) skills.

A *skill* is a folder with a `SKILL.md` (a YAML frontmatter `name` + `description`, then a playbook) plus any supporting scripts/templates. Claude Code auto-loads a skill when a request matches its description, and you can invoke one explicitly with `/<skill-name>`.

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

## Installing a skill

Skills live in `~/.claude/skills/` (user scope) or `<project>/.claude/skills/` (project scope). Copy or symlink the skill folder there:

```bash
git clone https://github.com/Gens-ai/skills.git
cp -r skills/debian-server-security ~/.claude/skills/
# or symlink: ln -s "$PWD/skills/debian-server-security" ~/.claude/skills/
```

Claude Code picks it up on the next session.

## License

[MIT](./LICENSE) © 2026 Joe Kneeland
