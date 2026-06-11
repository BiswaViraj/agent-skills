# agent-skills

Portable [Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
by [Biswajeet Das](https://github.com/BiswaViraj). One `SKILL.md` source of truth, installable across
**Claude Code, GitHub Copilot CLI, Codex CLI, and Cursor** via per-harness manifests.

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

## License

MIT © Biswajeet Das
