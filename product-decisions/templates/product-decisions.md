# Product decisions

The single reference for **what the product does and why** — behaviour and policy
calls a product owner made, not technical conventions (those live in `CLAUDE.md` and
the architecture/style docs).

**How to use this file**

- Organised by domain, not by date. It reads as *current state*: if an entry is here
  and not marked superseded, it is the rule.
- Each entry: the rule in one sentence, **Why** when one is recorded, date when known,
  and a **Source** — a doc link, or a `path:line` when the decision exists only as
  code. Keep entries short; argue in the source, not here.
- When a decision changes, edit the entry in place and append
  `*(supersedes: <old rule>, <date>)*` — don't delete history silently.
- Before changing product behaviour, check here first. If the behaviour you're about
  to change is listed, it was deliberate — raise it rather than "fixing" it.
- Code behaviour that *might* be a decision but looks accidental or contradicts an
  entry here goes in [Needs a product call](#needs-a-product-call), not in the body.
  Don't promote it to a rule until someone decides.
- Entries prefixed `⟲` were added or changed since the last review and are awaiting the
  owner's approval (`/product-decisions review`).

**Last full review:** never

---

## Platform & positioning

- **<Rule.>** **Why:** <reason>. <YYYY-MM-DD>. **Source:** `<path>`

## Pricing & plans

## Payments & billing

## Roles & permissions

## Accounts, auth & API

## Privacy & safety

## <Core domain A>

## <Core domain B>

## Notifications & digests

## Settings defaults

<One-paragraph roll-up of defaults; detail lives in each domain section.>

## Naming & voice

---

## Needs a product call

Behaviour found in code that either contradicts a decision above or looks accidental.
Each needs a decision — then either fix the code or promote the behaviour to a rule
above and delete it here.

**Contradicts a recorded decision**

- <behaviour> (`path:line`) — contradicts "<rule>".

**Looks accidental**

- <behaviour> (`path:line`).

## Open questions

Product calls that are needed but not yet made. Decide, record above, delete here.

- <question> — `<source>`
