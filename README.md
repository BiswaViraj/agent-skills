# agent-skills

> **Write a skill once, run it in every coding agent.** Portable `SKILL.md` skills for Claude Code, GitHub Copilot CLI, Codex, and Cursor — from one source of truth.

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Agent Skills](https://img.shields.io/badge/spec-Agent%20Skills-7C3AED.svg)
![Claude Code](https://img.shields.io/badge/Claude%20Code-✓-D97757.svg)
![Copilot CLI](https://img.shields.io/badge/Copilot%20CLI-✓-24292e.svg)
![Codex](https://img.shields.io/badge/Codex-✓-10A37F.svg)
![Cursor](https://img.shields.io/badge/Cursor-✓-000000.svg)

Portable [Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
by [Biswajeet Das](https://github.com/BiswaViraj). One `SKILL.md` source of truth, installable across
**Claude Code, GitHub Copilot CLI, Codex CLI, and Cursor** via per-harness manifests — because skills
are an [open standard](https://agentskills.io), not a single-vendor format.

## Skills

| Skill | What it does |
|---|---|
| **[reviewloop](skills/reviewloop/SKILL.md)** | Drives a PR to *all-clear* across **every** reviewer — Greptile, CodeRabbit, Copilot, other bots, and human teammates. Bots get re-triggered and re-checked in a loop; humans get one pass (addressed + re-requested) then it hands back. The reviewer-agnostic answer to "clear all the reviews on this PR." |
| **[ciloop](skills/ciloop/SKILL.md)** | Drives a *failing CI run back to green*. Pulls the real error from the GitHub Actions logs, **reproduces it locally** (so it's not burning CI minutes per attempt), fixes the failures it's confident about, pushes once, and re-watches — looping until green. Hands back flaky/infra failures instead of flailing. The red-CI twin of reviewloop. |
| **[standup](skills/standup/SKILL.md)** | Generates a paste-ready daily standup from your GitHub activity — merged, opened, and reviewed PRs across the whole org — rendered as a *Done / Today / Blockers* block. Weekday-aware window (Monday reaches back to Friday). No more "what did I do yesterday?" |

Install them **individually** (`reviewloop`, `ciloop`, `standup`) or grab the **`everything`** bundle.

## Install

This repo is a marketplace. **Claude Code and Copilot CLI** read `.claude-plugin/marketplace.json`,
which exposes each skill as its own plugin (`reviewloop`, `standup`) plus an `everything` bundle.
**Codex and Cursor** read their own manifest and install the whole collection.

### Claude Code

```bash
claude plugin marketplace add BiswaViraj/agent-skills
claude plugin install reviewloop@agent-skills   # just reviewloop
claude plugin install ciloop@agent-skills       # just ciloop
claude plugin install standup@agent-skills      # just standup
claude plugin install everything@agent-skills   # all three
```

Or, with [`@biswaviraj/cc-setup`](https://github.com/BiswaViraj/cc-setup), both skills are in the
palette — run `npx @biswaviraj/cc-setup@latest` and pick what you want.

### GitHub Copilot CLI

Copilot CLI shares Claude Code's plugin/marketplace system — same per-skill installs:

```bash
copilot plugin marketplace add BiswaViraj/agent-skills
copilot plugin install reviewloop@agent-skills   # or standup@ / everything@
```

### Codex CLI

Installs the whole collection:

```bash
codex plugin marketplace add BiswaViraj/agent-skills
codex plugin install everything@agent-skills
```

Or drop a single skill straight into a folder Codex scans
(`~/.agents/skills/` for personal, `<repo>/.agents/skills/` per-project):

```bash
git clone https://github.com/BiswaViraj/agent-skills /tmp/agent-skills
cp -r /tmp/agent-skills/skills/standup ~/.agents/skills/standup
```

### Cursor

```bash
cursor plugin marketplace add BiswaViraj/agent-skills
cursor plugin install everything@agent-skills
```

## Usage

**reviewloop** — on a branch with an open PR:

> reviewloop this PR

or "clear all the reviews", "address every reviewer", "loop until the PR is clean".

**ciloop** — when CI is red:

> ciloop

or "fix the failing CI", "make the checks pass", "loop until CI is green".

**standup** — anytime:

> write my standup

or "what did I do since Friday", "what did I ship this week".

## Layout

```
agent-skills/
├─ .claude-plugin/      # Claude Code + Copilot CLI — marketplace.json (per-skill plugins + bundle)
├─ .codex-plugin/       # Codex CLI (plugin.json)
├─ .cursor-plugin/      # Cursor (plugin.json)
└─ skills/
   ├─ reviewloop/
   │  ├─ SKILL.md
   │  └─ references/github-mechanics.md
   ├─ ciloop/
   │  ├─ SKILL.md
   │  └─ references/gh-ci.md
   └─ standup/
      ├─ SKILL.md
      └─ standup.sh
```

Adding a skill: drop a new folder under `skills/`, then add a plugin entry to
`.claude-plugin/marketplace.json` with `"skills": ["./skills/<name>"]` to make it separately
installable (and append it to the `everything` bundle's `skills` array).

## Related

**The harnesses** these skills run in: [Claude Code](https://code.claude.com/docs/en/skills) ·
[GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli) ·
[Codex CLI](https://developers.openai.com/codex/skills) · [Cursor](https://cursor.com)

**The review bots** `reviewloop` drives: [Greptile](https://greptile.com) ·
[CodeRabbit](https://coderabbit.ai) · [GitHub Copilot code review](https://docs.github.com/copilot/using-github-copilot/code-review)

**The standard:** [Agent Skills](https://agentskills.io) — the open `SKILL.md` spec adopted across
30+ agents.

**See also:** [`@biswaviraj/cc-setup`](https://github.com/BiswaViraj/cc-setup) — one command to load
your plugins + MCP servers (including these skills) into any project.

<sub>Keywords: claude code skills · agent skills · SKILL.md · github copilot cli plugins · codex cli
skills · cursor skills · automated pr review · greptile / coderabbit / copilot review loop · ai code
review automation · auto-fix failing CI · github actions fix loop · automated standup generator ·
anthropic agent skills marketplace</sub>

## License

MIT © Biswajeet Das
