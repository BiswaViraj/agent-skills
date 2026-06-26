---
name: standup
description: >
  Use when the user wants a daily standup update written for them — "what did I do yesterday",
  "write my standup", "summarize my work since Friday", "what did I ship this week". Pulls the user's
  own merged/opened/reviewed PRs across the org and renders a paste-ready Done / Today / Blockers block.
license: MIT
compatibility: Requires git and gh (GitHub CLI) authenticated. Works on macOS and Linux.
metadata:
  author: BiswaViraj
  version: "1.0"
allowed-tools: Bash(gh:*) Bash(git:*) Bash(./standup.sh:*)
---

# Standup

Generate a paste-ready standup from your GitHub activity — no manual recall of what you shipped.

**Core principle:** Only "Done" can come from git, so that's all the script claims. It auto-fills
*Done* from your PRs and leaves *Today* / *Blockers* as stubs for you to finish. Honest by construction.

## When to use

- "Write my standup", "what did I do since yesterday/Friday", "what did I ship this week".
- Before a daily scrum / async standup post.

## How to run

The skill ships a script — run it and show the output. It takes no setup:

```bash
./standup.sh                    # since last working day (Mon reaches back to Fri)
./standup.sh --since 2026-06-09 # explicit start date
./standup.sh --no-reviews       # drop the "Reviewed" section
./standup.sh --user somelogin   # someone else's activity (default: @me)
```

`@me` resolves to the **active `gh` account** — so run it on the account whose org work you want
(e.g. switch with `gh auth switch` first if you have multiple).

## What it produces

```markdown
**Standup — Thu 11 Jun** (since Wed 10 Jun)

**Done**
- ✅ Merged: owner/repo#5877 — chore(env): rename the connection URI
- 🚀 Opened: owner/repo#5881 — feat: verify JWT inbound and forward bearer
- 👀 Reviewed: owner/repo#5879 — feat: JWT verification in property service

**Today:**
**Blockers:** none
```

- **Merged / Opened / Reviewed** come from `gh search prs` org-wide (`--author @me`, `--reviewed-by @me`).
- A PR merged in the window lists under *Merged* only — *Opened* means **still in flight** (deduped).
- Fill in *Today* and *Blockers* yourself before posting.

## Notes & limits

- **Window:** defaults to the last working day. Monday reaches back to Friday so weekend-adjacent work
  isn't dropped. Override with `--since YYYY-MM-DD`.
- **Reviewed is approximate:** GitHub filters reviewed PRs by *last-updated*, not exact review time, so
  a long-running PR you reviewed earlier can occasionally appear. Use `--no-reviews` if it's noisy.
- **Out of scope (by design):** Slack posting, clipboard, raw commits, Linear — kept out so the skill
  stays pure `gh`/`git` and portable across every harness.
