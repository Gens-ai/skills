---
name: product-decisions
description: Keep one centralized register of product decisions per project at docs/product-decisions.md — the current-state "what the product does and why", grouped by domain, pointed to from the project's CLAUDE.md. Use whenever a product/behaviour call gets made or confirmed in a session ("let's go with X", "members should get the receipt", "no free trial"), when someone asks "did we decide…" / "why does it work this way", before changing user-facing behaviour, or to bootstrap the file in a project that lacks it (`/product-decisions init`, which backfills from docs AND code).
---

# Product decisions (docs/product-decisions.md)

Every project keeps **one** file, `docs/product-decisions.md`, as the single reference for
product decisions: behaviour and policy calls a product owner made — defaults, limits,
who-pays rules, what's gated, privacy posture, naming — *not* technical conventions
(those belong in CLAUDE.md / style guides / architecture docs).

The file reads as **current state**, grouped by domain, never as a chronological log.
Long rationale lives in the linked PRD/issue/commit; the register stays skimmable.

## Modes

| Invocation | What it does |
|---|---|
| `/product-decisions` or `check <topic>` | Look up what's decided about a topic; answer from the file, cite the entry. |
| `/product-decisions record <decision>` | Add or update an entry (also triggered implicitly — see "Recording"). |
| `/product-decisions init` | Bootstrap the file in a project that lacks it, backfilled from docs **and** code. |
| `/product-decisions review` | Interactive audit: one entry per multiple-choice question with a recommendation; the user approves, edits or drops each. Slow by design. `review all` walks everything. |
| `/product-decisions sync` | Re-sweep the code for drift since the last init/sync; refresh "Needs a product call". |

## First time in a project

If `docs/product-decisions.md` doesn't exist and a product call comes up, say so in one line
and offer `init`. Don't create the file ad hoc with a single entry — the value is in the
backfill. If the user just wants the one decision captured now, create the file from
`templates/product-decisions.md`, add the entry, and note that `init` is still pending at the
top under a `> **Not yet backfilled** — run /product-decisions init` callout.

## The file format

Start from `templates/product-decisions.md` (sibling of this file). Rules it encodes:

- **Header** explains how to use the file (current-state, edit in place, check before changing
  behaviour, where accidental behaviour goes). Keep it; don't let it drift per project.
- **Domain sections**, project-appropriate (e.g. Platform & positioning · Pricing & plans ·
  Payments · Roles & permissions · Accounts & auth · Privacy & safety · <core domains> ·
  Notifications · Settings defaults · Naming & voice). Order: positioning/pricing first,
  core domains in the middle, naming last.
- **Entry shape** — one bullet each:
  ```
  - **<Rule in one sentence.>** <Optional one-line qualifier.>
    **Why:** <reason, only if one was actually stated>. <YYYY-MM-DD if known>.
    **Source:** `<doc path>` §x | `<path:line>` when the decision exists only as code.
  ```
  Bold the rule. No "we", no hedging. If there's no recorded why, omit **Why** — don't invent one.
- **Superseding:** edit the entry in place and append
  `*(supersedes: <old rule>, <date>)*`. Never silently delete history.
- **Review state:** the header carries `**Last full review:** <date | never>`. Any entry
  added or materially changed after that date is prefixed `⟲ ` (`- ⟲ **Rule…**`) until the
  user approves it in a `review`. `grep -c '^- ⟲'` is the unreviewed count. A file with
  `never` is treated as entirely unreviewed, so `init` doesn't need to tag every line.
- **Settings defaults** section is a one-paragraph roll-up; each default's detail lives in
  its domain section.
- **`## Needs a product call`** (near the end) — code behaviour that *contradicts* a recorded
  decision or *looks accidental*. Two sub-lists, in that order. These are **not** rules; do
  not promote them until someone decides. Each item cites `path:line`.
- **`## Open questions`** (last) — product calls that are needed but not yet made, each with a
  source. Decide → record above → delete here.

## Recording (every session, every project)

A product decision was made when the user picks a behaviour, confirms a default, rejects an
option, or resolves an "it could go either way" — including in passing while fixing a bug
("yeah, the member should get the receipt"). When that happens:

1. Check the file for an existing entry on that topic (grep the rule's nouns).
2. Update in place (with the supersedes note) or add a new bullet in the right domain,
   prefixed `⟲ ` unless the user just stated the rule verbatim in this conversation (then
   it's already approved). Include the date and the best available source (issue, PR,
   PRD, or the `path:line` that now implements it).
3. If it resolves an item in **Needs a product call** or **Open questions**, delete it there.
4. Mention in one line that you recorded it. Don't ask permission for the edit itself — it's
   a doc change — but follow the project's commit-approval rules before committing.

Don't record: technical conventions, implementation choices with no user-visible effect,
things already in CLAUDE.md, or decisions the user explicitly called tentative (put those in
**Open questions** instead).

## Checking (before changing behaviour)

Before changing anything user-facing, grep the file for the area. If the behaviour is listed
it was deliberate — raise it ("this is a recorded decision: … — still want to change it?")
instead of "fixing" it. If it's under **Needs a product call**, surface that and get the call
before touching it.

## `init` — bootstrapping with a full backfill

Goal: the file starts *complete*, not empty. Two passes, then write once.

**Pass 1 — docs sweep (one fork, research-only).** PRDs, critiques, planning docs, issues
marked wontfix/blocked/"by design", ADR-ish files, README/CLAUDE.md business rules,
anything named `*decision*`, grep for `decided|deliberately|intentionally|wontfix|by design`.
Report: grouped list of (rule, why, date, source) + a separate list of OPEN questions.

**Pass 2 — code sweep (3–5 parallel forks by domain, research-only).** This is where most
undocumented decisions live. Give each fork its domain's file list and these questions:
defaults, limits/min/max, who-can-do-what, what's gated, what emails go to whom and when,
retention/expiry windows, fallbacks the user sees, scheduled jobs and their cadence, what
happens at a quota. Each item: one-sentence rule, why if a comment says, `path:line`.
Tell them to **flag "(looks accidental)"** for behaviour that seems unintended, and to flag
anything contradicting a Pass-1 decision. Typical splits: money/plans · users/roles/privacy/
auth/comms · core domain A · core domain B/settings/scheduling/integrations.

**Write.** Merge into the template. Accidental/contradicting findings go to **Needs a product
call**, never into the body. Verify every cited path exists (e.g. `find . -name <file>`) — forks
sometimes shorten paths. Then:

- Add the pointer to the project's `CLAUDE.md` (see below).
- If the project has a work-tracker index (TODO.md "where we track work", README), add a row.
- Report to the user: counts per section, and the top 2–3 **Needs a product call** items —
  those are usually live bugs masquerading as behaviour.
- Offer to commit (per the project's commit rules). Then suggest `/product-decisions review`
  — an `init` is a draft until the owner has approved it.

## CLAUDE.md pointer (standard text)

Add once, near the project's business-rules/architecture section:

```markdown
> **Product decisions:** [`docs/product-decisions.md`](docs/product-decisions.md) is the
> single current-state register of deliberate product/behaviour calls, with the why and a
> link to each source. **Read it before changing any user-facing behaviour** — if the
> behaviour is listed, it was chosen on purpose; raise it instead of "fixing" it. When a
> product call gets made in a session, record it there (edit in place, mark the old rule
> superseded). Bootstrap, audit or re-sweep with the `product-decisions` skill
> (`init` / `review` / `sync`).
```

## `review` — the user approves every entry

An interactive audit so the register reflects what the owner actually wants, not what the
code or a past doc happened to say. **One entry per question, multiple choice, with a
recommendation.** It is slow by design — a full first pass on a mature project is 100–200
questions. Never batch entries into a list for a single "ok"; that produces rubber-stamps,
and thoroughness matters more than speed here.

**Scope.** Default = entries prefixed `⟲ ` plus everything under **Needs a product call**
and **Open questions**; if `Last full review` is `never`, scope is the whole file. `review
all` forces the whole file. Say up front how many entries are in scope and that it's one at
a time; the user can say `stop` or `skip section` at any point — record progress by
leaving `⟲ ` on whatever wasn't reached (tag the remaining entries if this is a first pass).

**Per entry — one `AskUserQuestion` call.** The question shows the full entry (rule, why,
date, source) and the section/position (`Payments & fees · 7 of 14 · 63/152 overall`).
Form your own view first: does the rule match the code and the user's known intent, is the
why real, is the wording right? Then offer options with your pick **first and marked
"(Recommended)"**, and a one-line reason for the pick in the question text:

- Standard entry — options: **Approve** · **Edit wording** (describe the change in the
  option description; the user refines via "Other") · **Drop — not a decision** · **Move to
  Open questions**. If you think the *why* is missing or wrong, make "Approve, add why: …"
  the recommended option with the proposed why spelled out.
- **Needs a product call** item — options: **Fix the code** (state the intended rule you'd
  record) · **Keep — promote to a rule** (state the rule wording) · **Later**. Recommend
  based on: contradicts a recorded decision → fix; security/correctness → fix; defensible
  pre-launch → keep as rule; genuinely needs design → move to Open questions.
- **Open question** — options are 2–3 concrete candidate rules (worded ready to record),
  plus **Later**. Recommend one and say why in a sentence. Don't offer "decide" as an
  abstract option — do the thinking and put the wording in front of the user.

Use the option `description` for the consequence ("files ISSUE, leaves entry listed until
fixed"), not for restating the label. Never use `multiSelect`.

**Apply the answer immediately**, before asking the next question:

- Approve — strip `⟲ `.
- Edit — replace the rule text; keep source/date; add today's date and
  `*(supersedes: <old>, <date>)*` if the meaning changed, not for copy-edits. Strip `⟲ `.
- Drop — delete the entry. If it described live code behaviour, the next question asks
  whether that's "not a decision" (just delete) or "wrong behaviour" (delete + file an
  issue via `issue-tracking`, and list it under **Needs a product call** until fixed).
- Move to Open questions — rewrite as a question with source, delete from the body.
- Fix the code — file the issue via `issue-tracking` now (cite `path:line` and the intended
  rule), record the intended rule in its domain section dated today with a note that code
  lags until the issue lands, and leave the item listed with the issue number.
- Keep — rewrite as a rule in the right section, dated today; delete from Needs a call.
- Candidate rule chosen — record it in its domain section dated today; file an issue if it
  needs code; delete the open question.
- "Other" free text — treat as an edit or a new rule; confirm the resulting wording in one
  line before moving on.

Between questions, output at most one line ("Recorded. Next:") — the question is the
conversation.

**Finish.** Set `**Last full review:** <today>` when the scope was the whole file (not for a
delta review — leave the date alone). Report counts: approved / edited / dropped / moved /
rules added / issues filed, and the 2–3 issues to work first. Offer to commit.

## `sync` — catching code drift

Run `init`'s Pass 2 only (code sweep), diff against the current file, and report: new
behaviour not recorded, recorded rules the code no longer matches, and **Needs a product
call** items that have since been fixed or decided. Add new entries with the `⟲ ` prefix so
the next `review` picks them up; don't rewrite sections that didn't change. Suggest a
`review` afterwards if anything was added.
