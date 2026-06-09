---
name: dev-servers
description: Start or stop local development servers for the current project — the safe way. Frees ports / tears down stale processes first, defers to a project-specific skill if one exists, then detects the stack (Laravel Sail, Laravel, Node/npm, Docker Compose, Makefile) and starts it. Use when the user says "start local servers", "start the dev server", "spin up local", "boot up the app", "start dev", "stop the servers", "kill the dev servers", or any variation.
allowed-tools: Bash, Read
---

# Dev Servers (start / stop)

A safe, portable lifecycle for local dev servers. The value isn't a magic start command — that's inherently stack-specific — it's the **discipline**: *defer to a project skill → tear down stale processes first → detect the stack → start → report.* Skipping the teardown is the #1 cause of "port already in use" pain; deferring to a project skill means project-tuned setups always win.

## Stopping

For "stop / kill / shut down the dev servers", run the bundled teardown:

```bash
bash scripts/stop-dev
```

It stops all running Docker containers, kills Vite dev servers, and stops any system services configured in the script. Edit `scripts/stop-dev` to add the services you run locally (mysqld, postgresql, redis, …), or copy it onto your PATH as `stop-dev` for convenience.

## Starting

Always follow these steps in order.

### Step 0 — defer to a project-scoped skill

Before anything else, check for a project-specific skill in the current working directory:

```bash
cat .claude/skills/local-servers/SKILL.md 2>/dev/null
```

If it exists, **read it and follow those instructions exclusively** — ignore the steps below. A project that ships its own startup skill knows its services, ports, and gotchas better than any generic detection.

### Step 1 — stop everything first

```bash
bash scripts/stop-dev
```

Run this unconditionally before starting anything, to clear containers/processes/services that could hold ports.

### Step 2 — detect the stack

```bash
ls composer.json package.json Makefile docker-compose.yml docker-compose.yaml 2>/dev/null
grep -E '"sail"|"laravel"' composer.json 2>/dev/null | head -5
```

Also check the project's `CLAUDE.md` / `README` for the canonical dev command before assuming defaults.

### Step 3 — start the appropriate servers

Use the project's own conventions:

**Laravel Sail** (`composer.json` references `laravel/sail` + a `docker-compose.yml`):
```bash
sail up -d
# then any extra processes — many projects expose a "dev" script:
composer run dev    # often runs serve + queue + vite together
```

**Laravel without Sail:**
```bash
php artisan serve &
# start queue/vite too if the project uses them (check CLAUDE.md/README)
```

**Node / npm:**
```bash
npm run dev
```

**Makefile:**
```bash
make help 2>/dev/null || grep -E '^[a-zA-Z_-]+:' Makefile | head -20
```

### Step 4 — confirm

Report:
- what `stop-dev` stopped (if anything),
- which servers are now running and on what ports/URLs.

## Notes

- `scripts/stop-dev` stops **all** running Docker containers — intended for a dev box where containers *are* dev services. If you run non-dev containers locally, comment that block out.
- Stopping system services needs **passwordless sudo** for those units (non-interactive runs).
- Written for Linux/macOS with bash; the service-stop step assumes systemd.
