---
name: resolve-issue
description: End-to-end workflow for actually fixing a tracked issue from docs/issues/ — picks (or is given) one, marks it in-progress on the primary branch, does the fix in an isolated git worktree, merges it back, and closes out the ticket. Builds on the issue-tracking skill's file convention. Triggers on "/resolve-issue", "/resolve-issue NNN", "/resolve-issue <description>", "work the next open issue", or "resolve issue NNN".
---

# Resolve an issue (docs/issues/)

This is the "do the work" counterpart to the `issue-tracking` skill (which just covers the file convention — creating, updating, closing). Use both together: this skill defers to `issue-tracking` for exact frontmatter/template/status rules and only adds the workflow around actually fixing something.

## 1. Determine which issue to work

- Argument is a bare number or `ISSUE-NNN` → use that issue directly. Fail clearly if it doesn't exist. If it's `status: blocked`, show the `blocked_reason`/Findings before proceeding — the user may be explicitly unblocking it now (e.g. supplying the missing credential themselves), so don't refuse, just make sure they're doing it knowingly.
- Argument is free text → match it against issue titles/summaries under `docs/issues/`. If more than one issue is a plausible match, list the candidates and ask which one before proceeding.
- No argument → list every issue whose frontmatter `status` is `open` (skip `in-progress`, `resolved`, `wontfix`, `blocked`, `needs-review`), and pick the oldest by `created` date (lowest `ISSUE-NNN` as a tiebreak). State which one you picked and why in one line, then proceed — don't block on a question for this pick alone, the user can redirect if it's wrong.
- No open issues at all (only `in-progress`/`resolved`/`wontfix`/`blocked`/`needs-review` remain) → say so, and mention how many are `blocked` (and on what) and how many are `needs-review` (waiting on a human check), so the user knows what's piling up on each side — then stop.
- If it's `status: needs-review`, show the `review_reason`/`## Verification` steps before proceeding — the user may be doing that check right now, so don't refuse, just make sure they know what was already implemented and tested versus what still needs their eyes.

## 2. Figure out repo structure

- Check the project's CLAUDE.md (root, and any nested repo's own CLAUDE.md) for a documented multi-repo layout — a table or section naming separate repos/paths and each one's real working branch. Some projects keep several git repos under one working directory (e.g. a docs/planning repo with independent backend/frontend repos nested inside), and "the primary branch" is often NOT literally `main` for all of them — it might be `staging`, `develop`, etc. per repo, by team convention.
- If nothing is documented, treat the project as a single repo, and treat whatever branch is currently checked out as its primary branch.
- Identify every repo an issue actually touches from its Details/Findings and a quick look at the relevant code, before creating any worktree — a fix can span more than one repo (e.g. a full-stack change).

## 3. Mark the issue in-progress — on the primary branch, before creating any worktree

- Edit the issue file's frontmatter: `status: open` → `status: in-progress`.
- Do this on the primary branch identified in step 2, before entering any worktree, so the tracking doc reflects reality immediately no matter how long the fix takes.
- Commit just this one-line change right away, following that repo's own commit message/attribution conventions (its CLAUDE.md, or the user's global CLAUDE.md). This is a small, safe, non-destructive change — invoking this skill is itself the user's authorization for it; no separate per-commit confirmation needed for this specific step.

## 4. Open an isolated worktree per affected repo

- Use the `EnterWorktree` tool, run from inside the specific repo directory being worked on (root, or a nested repo directory) so it creates the worktree for the right one. Give it a descriptive `name` (e.g. `issue-109-remove-guest-communication`).
- `EnterWorktree` only lets you create *one new* worktree while not already inside another. If the issue spans multiple nested repos: either exit back out first (`ExitWorktree`, `action: "keep"`) before creating the next repo's worktree, or create the additional repo's worktree directly with `git worktree add` and attach the session to it with `EnterWorktree(path: ...)`.
- The worktree branches off a ref per the `worktree.baseRef` setting (`fresh` = latest fetched ref from `origin/<default-branch>`, `head` = current local HEAD). **`fresh`'s "default branch" is the remote's configured default (often `main`), which is not necessarily this repo's actual primary/working branch from step 2** (e.g. a repo whose team works on `staging` while `origin/HEAD` still points at `main`) — don't trust it blindly.
- **Always verify after creating the worktree:** compare `git log -1 --oneline` inside it against the primary branch's tip (`git rev-parse <primary-branch>`). If they don't match, the worktree branched from the wrong base — fix it immediately with `git reset --hard <primary-branch>` (safe as long as nothing's been committed in the worktree yet, which it hasn't at this point in the flow). Only proceed to step 5 once the base is confirmed correct.

## 5. Do the fix

- Read the issue's Summary/Details/Findings in full before touching code — don't skip straight to a grep-and-edit.
- Follow the project's own engineering conventions (its CLAUDE.md rules — impact analysis, lint/test commands, code style, anything it calls out as mandatory).
- If you learn something worth recording mid-investigation (root cause, a dead end, a workaround, or — importantly — that the issue as filed conflates two unrelated things and only part of it should change), append a dated Finding to the issue doc as you go, per the `issue-tracking` skill.
- **If investigation shows the issue can't actually be moved forward right now** — it needs something only outside the repo can provide, it needs a product/scope decision that hasn't been made, or the code already looks correct and it just needs a live/human retest — don't force a fix or leave it silently `open` for a future run to re-hit the same wall. Mark it `status: blocked` with a `blocked_reason` and a dated Finding explaining why, per `issue-tracking`'s "Blocking an issue" section, and commit that update on the primary branch (same low-risk, pre-authorized pattern as step 3). Then:
  - If this issue was auto-picked (no argument was given in step 1), go back to step 1's no-argument logic and pick the next-oldest still-`open` issue, continuing the same run — don't stop and ask each time this happens, since re-litigating the pick was already covered by step 1's "don't block" rule. Note every issue blocked this way in the final report (step 6).
  - If the user explicitly named this issue (by number or description), stop here and report why it's blocked instead of substituting a different one — they asked for this specific issue.
- Run the project's relevant tests/lint before considering the fix done.

## 6. Bring the work back and close out

- Committing the fix is never pre-authorized by invoking this skill — unlike step 3's one-line status flip, this is real code. Follow the project's own git commit-approval rules (its CLAUDE.md or the user's global instructions; if none say otherwise, never commit without the user's explicit go-ahead in the current turn). Ask directly and briefly (e.g. "Shall I commit?") rather than assuming.
- **Decide whether this fix needs a human check before it can honestly be called `resolved`** — the change is UI-visible, the project has a standing convention against committing untested frontend/UI changes, the scenario needs a live integration or a two-person/two-session test, or you simply can't verify the actual behavior from code + automated tests alone. If so:
  - Get the commit go-ahead as above (this can still happen now — committing and merging into the primary branch is a *local* checkpoint, distinct from calling the issue `resolved`), then merge the worktree branch onto the primary branch from step 2 (local merge, never a push).
  - Update the issue file per `issue-tracking`'s "Needs review" section: `status: needs-review`, a `review_reason`, and a dated `## Verification` entry with concrete phased steps to test — don't just say "test it," spell out what to click through and what to expect, and note the resolving commit hash(es) so there's nothing left to re-derive.
  - **Every step must point at a specific, real thing, never a description for the user to go find.** Before writing the steps, look up actual data (query the dev DB, grep seed fixtures, check existing records) for a concrete example that's already in the state the step needs, and name it directly — a specific user/email, record ID, or similar — plus the exact URL to reach it when the app's route structure makes that possible (check the frontend's route constants/router for the real path, don't guess it). "open an order that's awaiting approval" is not acceptable; "open order 1042 (https://app.test/orders/1042) — already `pending_approval`, placed by alice@example.com" is. If no existing record fits, say so and give the exact action that creates one (e.g. a seeder or factory command, with real IDs filled in) rather than telling the user to "create one that meets X" themselves.
  - Don't drive the browser yourself for this check unless the user explicitly asks you to — hand back the phased steps and wait, per the project's own manual-testing conventions if any exist.
  - **Load the project's manual-testing skill (if it has one) before writing the first section**, and follow it — in particular, if it provides a way to switch the user's logged-in account (e.g. a dev-login script), run it yourself at the start of each section rather than telling the user to log in or to run the command.
  - If auto-picked (no argument in step 1), continue to the next-oldest `open` issue rather than stopping, same as a `blocked` issue — note every issue left `needs-review` in the final report.
- **Otherwise** (fix is confidently verifiable from tests/lint/build alone, or the user directly confirmed it already):
  - Commit the fix in the worktree, following the repo's commit conventions.
  - Merge (or rebase — whichever keeps that repo's history clean) the worktree branch onto the primary branch from step 2. This is a local merge into a local branch, never a push to any remote — pushing always needs its own separate, explicit ask in the current turn, regardless of anything authorized above.
  - Update the issue file: `status: resolved`, `resolved: <date>`, and a `## Resolution` section naming the file(s) touched and the resolving commit hash(es), per `issue-tracking`'s closing convention (fix committed first, then the ticket updated to reference it).
- Exit each worktree with `ExitWorktree` — `action: "remove"` once its branch is fully merged in, `action: "keep"` if anything was left unmerged (including a `needs-review` issue's worktree, if you chose not to merge it yet) or the user wants to keep working in it.
- Report a short summary: which issue, what changed, which repo(s)/files, test/lint results, and the final commit(s). If step 5 blocked or step 6 left anything `needs-review` along the way, list those too (issue number + `blocked_reason`/`review_reason`) so the user sees what's waiting on them, not just the one issue that's now fully `resolved`.

## Notes

- Assumes `docs/issues/` already exists and follows `issue-tracking`'s conventions. If it doesn't exist yet, that skill's own "ask before creating it" rule still applies — don't start one on this skill's authority alone.
- Never push to a remote as part of this flow. Only the doc-only status-flip commits are pre-authorized by invoking the command (step 3's `open`→`in-progress`, and step 5's `blocked` marker) — any commit that includes real code (step 6, whether it ends in `resolved` or `needs-review`) still needs the user's explicit go-ahead in the turn it happens, per that repo's own commit-approval rules.
- If step 1's or step 2's picks are genuinely ambiguous — ties in the "oldest open" heuristic, or an issue that plausibly maps to repos in more than one way — ask rather than guessing. Everything else in this flow is designed to proceed without interrupting.
