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

### [`issue-tracking`](./issue-tracking)
Track issues as one markdown file each under `docs/issues/`, opened and closed in place:

- **`ISSUE-NNN-slug.md`** — sequential, zero-padded filenames, created on "log an issue" / "create an issue".
- **Resolved in place** — closing sets `status: resolved` + a `## Resolution` section in the frontmatter; files are never archived or moved elsewhere.
- **Frontmatter as source of truth** — status queries read `status:` across the directory instead of guessing from filenames.
- **`blocked` and `needs-review` states** — triaged-but-stuck issues carry a `blocked_reason`; fixes awaiting a human check carry a `review_reason` plus concrete `## Verification` steps.

Self-contained (no external dependencies). See [its SKILL.md](./issue-tracking/SKILL.md).

### [`resolve-issue`](./resolve-issue)
The "do the work" counterpart to `issue-tracking`: pick an issue (by number, description, or oldest open), fix it, close it out.

- **Marks `in-progress` on the primary branch first**, then does the fix in an isolated git worktree (verifying the worktree's base, which Claude Code's `worktree.baseRef` can get wrong).
- **Multi-repo aware** — respects per-repo working branches documented in the project's CLAUDE.md.
- **Blocks or parks instead of forcing** — unworkable issues go `blocked`; UI-visible fixes go `needs-review` with test steps that name real records and URLs.
- **Commit rules** — invoking the skill authorizes only the doc-only status-flip commits; any commit with real code still needs explicit approval. Never pushes.

Requires `issue-tracking`. Uses Claude Code's `EnterWorktree`/`ExitWorktree` tools. See [its SKILL.md](./resolve-issue/SKILL.md).

### [`product-decisions`](./product-decisions)
One `docs/product-decisions.md` per project: a current-state register of deliberate product/behaviour calls, grouped by domain, pointed to from the project's CLAUDE.md.

- **Record** decisions as they're made in a session (edit in place, mark superseded rules) and **check** the register before changing user-facing behaviour.
- **`init`** backfills from docs *and* code via parallel research forks; accidental-looking behaviour goes to a "Needs a product call" list, not into the rules.
- **`review`** — the owner approves every entry, one multiple-choice question at a time, with a recommendation.
- **`sync`** — re-sweeps the code for drift since the last init.

Uses `issue-tracking` when a review files a fix, and Claude Code's `AskUserQuestion` tool for `review`. See [its SKILL.md](./product-decisions/SKILL.md).

## License

[MIT](./LICENSE) © 2026 Joe Kneeland
