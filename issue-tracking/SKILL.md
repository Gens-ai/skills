---
name: issue-tracking
description: Track issues as markdown files in a project's docs/issues/ dir — one file per issue, opened and closed in place. Use whenever the user says "create an issue", "log an issue", "close/resolve issue N", or asks about the status of a tracked issue.
---

# Issue tracking (docs/issues/)

A convention for tracking issues as markdown files under `docs/issues/`, one file per issue, applied consistently across projects.

## First time in a project

If `docs/issues/` doesn't exist yet, **ask before creating it** — even if `docs/` already exists for other things in the project.

## "Create an issue"

When the user says "create an issue" (or "log an issue", "add an issue for X"), it means: **add a markdown file to `docs/issues/`.** It does not mean opening a GitHub issue or any other tracker unless they say so explicitly.

**Filename:** `ISSUE-NNN-slug.md`, sequential, zero-padded to 3 digits. Find the next number:

```bash
ls docs/issues/ 2>/dev/null | grep -oE '^ISSUE-[0-9]+' | grep -oE '[0-9]+' | sort -n | tail -1
```
Increment by 1 (start at 001 if the directory is empty/new).

**Template:**

```markdown
---
id: ISSUE-NNN
title: <short title>
status: open
created: YYYY-MM-DD
---

## Summary

<what's wrong / what's being tracked>

## Details

<area affected, repro steps, relevant files — whatever's known>

## Findings

<learnings/discoveries from investigation, appended as dated entries as they emerge>
```

Keep it terse — match the level of detail in the summary/details/findings fields to what's actually known; don't pad with boilerplate sections that have nothing in them. Omit the `## Findings` section entirely if there's nothing to put in it yet — add it later when the first finding comes in.

**Status values:** `open` → `in-progress` → `resolved`, or `wontfix` for anything closed without a fix. Set `in-progress` once active investigation starts (not just on file creation). Use `blocked` instead of leaving something `open` when it's fully triaged but can't be worked right now — see "Blocking an issue" below. Use `needs-review` instead of leaving something `in-progress` once a fix is written and automated-verified but is intentionally paused for a human to confirm before calling it `resolved` — see "Needs review" below. Don't confuse the two: `blocked` means it *can't* move forward without something external; `needs-review` means it's done pending a quick human check.

## Recording findings during investigation

While researching an issue, when you reach a conclusion (root cause identified, a dead end ruled out, a workaround discovered), don't update the doc silently — ask the user (or at least propose it), e.g. "Should I add this to the issue doc?" Each entry appended to `## Findings` must be dated:

```markdown
- **YYYY-MM-DD:** <what was learned>
```

## Blocking an issue

Use `status: blocked` for an issue that's been triaged (root cause understood, or at least investigated) but can't be moved forward right now — as opposed to `open`, which means "ready to pick up." Don't leave a genuinely stuck issue as `open`: a future pass (e.g. `resolve-issue` picking "the oldest open issue") will just re-discover the same dead end. Common cases:

- **`external-dependency`** — needs something only outside the repo can provide (credentials, access, a decision from a third party).
- **`needs-decision`** — needs a product/scope decision before any fix would be well-defined (the issue as filed is a question, or covers ground a decision hasn't settled yet).
- **`needs-verification`** — investigation found the code already appears correct; needs a live/human retest to confirm before it's either resolved or reopened as a real bug.

Set frontmatter in place (don't move or rename the file):

```yaml
status: blocked
blocked_reason: external-dependency   # or needs-decision, needs-verification, or a short freeform reason
blocked_since: YYYY-MM-DD
```

Append a dated `## Findings` entry explaining what's blocking it and what would unblock it, same as any other finding.

**Unblocking:** once the dependency lands, the decision is made, or the retest happens, revert to `status: open` (drop `blocked_reason`/`blocked_since`) and proceed normally, or straight to `resolved` if the retest confirms it's already fixed.

A large, fully-specced issue that just needs a dedicated session isn't `blocked` — it's still `open` and workable, just big. Reserve `blocked` for issues that cannot move forward at all right now.

## Needs review

Use `status: needs-review` for an issue whose fix is written and passes whatever automated checks apply (tests, lint, build) but is intentionally paused before a human confirms it — typically because the change is UI-visible or otherwise hard to trust from code-reading and a test run alone. This is different from `blocked`: a `needs-review` issue isn't stuck, it's *done pending a quick check* — anyone (including the filer) can close it out in minutes once that check happens. Common cases:

- **`manual-ui-test`** — the fix touches visible UI; needs a click-through in the real app before committing (matches a "don't commit frontend changes until manually tested" project convention, if one exists).
- **`two-person-test`** — the scenario needs two accounts/sessions interacting live (e.g. two users in different roles on separate logins) to actually exercise the fix.
- **`live-integration-required`** — depends on a real third-party integration (payment processor, external API) that's impractical to fully exercise outside a live/staging run.

Set frontmatter in place (don't move or rename the file):

```yaml
status: needs-review
review_reason: manual-ui-test   # or: two-person-test, live-integration-required, or a short freeform reason
```

Append a dated `## Verification` section (create it if it doesn't exist) with concrete, phased steps for whoever picks this back up to actually test it — written once, right when the fix lands, so the steps don't need to be rediscovered later. Note where the fix currently lives (e.g. a worktree path, or "committed on `<branch>`, not yet merged") so resuming doesn't require re-deriving that either:

```markdown
- **YYYY-MM-DD:** <what to click through, as numbered/phased steps>. Fix lives in `<worktree path or branch>`, not yet committed/merged.
```

**Closing out a `needs-review` issue:** once a human confirms the behavior (or reports it's broken), either resolve it directly (commit if not already, merge, flip to `resolved` per "Closing / resolving an issue" below, and note in the `## Resolution` entry that it was manually verified) or, if the check reveals a real problem, revert to `in-progress` with a dated `## Findings` entry on what broke.

## Closing / resolving an issue

**Order matters: commit the fix first, then update the ticket.** Follow the user's normal git workflow for the commit itself (this skill doesn't change commit-approval rules — never commit without the user's explicit go-ahead in that turn); once the fix is committed, update the doc referencing that commit.

Don't move or rename the file. Update its frontmatter in place:

```yaml
status: resolved
resolved: YYYY-MM-DD
```

Add a `## Resolution` section describing the fix — the file(s) it touched and the resolving commit hash (so the fix and the ticket cross-reference each other), dated:

```markdown
- **YYYY-MM-DD:** <fix description> — commit `<hash>`
```

Resolved issues stay in place alongside open ones; never archive or move them elsewhere.

## Checking issue status

To answer "what issues are open" or "what's the status of ISSUE-NNN", read the frontmatter across `docs/issues/*.md` rather than guessing from filenames alone — `status` is the source of truth:

```bash
grep -l '^status: open' docs/issues/*.md 2>/dev/null
```

To see what's blocked, and why (e.g. everything waiting on an external party vs. everything waiting on a product decision):

```bash
grep -l '^status: blocked' docs/issues/*.md 2>/dev/null
grep -l '^blocked_reason: needs-decision' docs/issues/*.md 2>/dev/null
```

To see what's done-pending-a-human-check, and why:

```bash
grep -l '^status: needs-review' docs/issues/*.md 2>/dev/null
grep -l '^review_reason: manual-ui-test' docs/issues/*.md 2>/dev/null
```

### Presenting the list

When showing unresolved issues (or "refresh the list"), always use **one markdown table per status**, in this order: Needs review, In progress, Blocked, Open. Each table gets a `### <Status> (<count>)` heading and a `---` rule before the next one — bold labels alone render as one continuous table in the terminal. Columns: `#` / `Type` (Bug, Flaky test, Feature, Infra) / `Title` (shortened, plain English). On a refresh, put a short "changed since last list" note above the tables (resolved, status moves, new issues).
