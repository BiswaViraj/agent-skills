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

## Install

This repo is a marketplace. Each harness reads its own manifest at the repo root
(`.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`) — all pointing at the same `skills/` folder.

### Claude Code

```bash
claude plugin marketplace add BiswaViraj/agent-skills
claude plugin install reviewloop@agent-skills
```

Or, if you use [`@biswaviraj/cc-setup`](https://github.com/BiswaViraj/cc-setup), `reviewloop` is in the
palette — just run `npx @biswaviraj/cc-setup@latest` and pick it.

### GitHub Copilot CLI

Copilot CLI shares Claude Code's plugin/marketplace system:

```bash
copilot plugin marketplace add BiswaViraj/agent-skills
copilot plugin install reviewloop@agent-skills
```

### Codex CLI

```bash
codex plugin marketplace add BiswaViraj/agent-skills
codex plugin install reviewloop@agent-skills
```

Or drop the skill straight into a skills folder Codex scans
(`~/.agents/skills/` for personal, `<repo>/.agents/skills/` per-project):

```bash
git clone https://github.com/BiswaViraj/agent-skills /tmp/agent-skills
cp -r /tmp/agent-skills/skills/reviewloop ~/.agents/skills/reviewloop
```

### Cursor

```bash
cursor plugin marketplace add BiswaViraj/agent-skills
cursor plugin install reviewloop@agent-skills
```

## Usage

Once installed, on a branch with an open PR:

> reviewloop this PR

or "clear all the reviews", "address every reviewer", "loop until the PR is clean".

## Layout

```
agent-skills/
├─ .claude-plugin/      # Claude Code + Copilot CLI (marketplace.json + plugin.json)
├─ .codex-plugin/       # Codex CLI (plugin.json)
├─ .cursor-plugin/      # Cursor (plugin.json)
└─ skills/
   └─ reviewloop/
      ├─ SKILL.md
      └─ references/github-mechanics.md
```

Adding a skill: drop a new folder under `skills/`, it ships with the plugin. To make it separately
installable, add an entry to `.claude-plugin/marketplace.json`.

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
review automation · anthropic agent skills marketplace</sub>

## License

MIT © Biswajeet Das
