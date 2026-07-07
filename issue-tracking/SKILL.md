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
```

Keep it terse — match the level of detail in the summary/details fields to what's actually known; don't pad with boilerplate sections that have nothing in them.

## Closing / resolving an issue

Don't move or rename the file. Update its frontmatter in place:

```yaml
status: resolved
resolved: YYYY-MM-DD
```

Add a `## Resolution` section describing the fix — the file(s) it touched and, if the fix was committed, the resolving commit hash. Resolved issues stay in place alongside open ones; never archive or move them elsewhere.

## Checking issue status

To answer "what issues are open" or "what's the status of ISSUE-NNN", read the frontmatter across `docs/issues/*.md` rather than guessing from filenames alone — `status` is the source of truth:

```bash
grep -l '^status: open' docs/issues/*.md 2>/dev/null
```
