---
name: ciloop
description: >
  Use when CI is failing on a branch/PR and the user wants it driven back to green — "fix the failing
  CI", "CI is red, sort it out", "make the checks pass", "loop until CI is green". Pulls the real error
  from the failing GitHub Actions logs, reproduces it locally, fixes the confident failures, pushes once,
  and re-watches until green. The red-CI twin of reviewloop.
license: MIT
compatibility: Requires git and gh (GitHub CLI) authenticated, on a repo using GitHub Actions. Reproduces failures with the repo's own local commands.
metadata:
  author: BiswaViraj
  version: "1.0"
allowed-tools: Bash(gh:*) Bash(git:*)
---

# Ciloop

Drive a failing CI run to **green**. Pull the real error from the logs, reproduce it **locally**, fix
the failures you're confident about, push **once**, and confirm — looping until green.

**Core principle:** CI is slow and costs minutes, so don't use it as your edit-test loop. **Reproduce
the failure locally, fix until local is green, then push once.** And don't flail: fix what you can
diagnose with confidence; for failures you can't (flaky, infra, secrets, ambiguous logic), **stop and
hand back** rather than guess. Loop the fixable; hand back the judgment calls.

## When to use

- A push/PR has red checks and you want them green without babysitting each run.
- "Fix the failing CI", "make the checks pass", "CI is red, loop until it's clean".

**When NOT to use:** You only want to *read* why CI failed without fixing → just `gh run view --log-failed`.
The failures are all infra/deploy/flaky (nothing to fix in code) → ciloop will just hand those back.

## Classify every failure first

| Category | Examples | Action |
|---|---|---|
| **Confident-fix** | lint, format/prettier, type errors (tsc), clear test/assertion failures, missing import, obvious compile error | reproduce locally → fix → loop |
| **Hand-back** | flaky/non-deterministic tests, infra/network timeouts, missing secrets/credentials, deploy/release steps, ambiguous logic failures you can't pin down | **don't touch** — record the real error + why, report at the end |

A step that **can't run locally** (needs live services, secrets, a built artifact) is hand-back, not a
guess. Never push a speculative fix for something you couldn't reproduce.

## Inputs

- **branch / PR** (optional): default = current branch.
- **`--max-iterations N`** (optional, default 5): cap on the fix→push→watch loop.

## The loop

### 0. Find the red run

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
HEAD_SHA=$(git rev-parse HEAD)
gh run list --branch "$BRANCH" --limit 5 \
  --json databaseId,headSha,status,conclusion,workflowName
```

Pick the most recent run **for `HEAD_SHA`**. If it's `success` → report "already green" and stop. If
still `in_progress` → wait (`gh run watch`). See [references/gh-ci.md](references/gh-ci.md).

### 1. Pull the real failures

```bash
gh run view <run-id> --json jobs \
  --jq '.jobs[] | select(.conclusion=="failure") | {name, steps: [.steps[] | select(.conclusion=="failure") | .name]}'
gh run view <run-id> --log-failed
```

Read the **actual error** from `--log-failed` — not just "job X failed". Find the line that caused it.

### 2. Classify each failing job (table above)

Split into **fix** and **hand-back**. If there are zero fixable failures, skip to the report.

### 3. Reproduce + fix locally

For each fixable job, map it to its local command by reading the workflow that ran it:

```bash
# find the failed step's exact command
cat .github/workflows/*.y*ml   # locate the failing job → its `run:` step
```

Run that exact command locally (e.g. `pnpm lint`, `pnpm typecheck`, `pnpm test <file>`), read the
error in context, **fix the root cause**, and re-run the command until it passes locally. Repeat per
fixable job. (If the YAML is a composite/opaque action, fall back to the obvious local command for the
job's purpose — but if you can't reproduce it, treat it as hand-back.)

### 4. Push once

Only after every fixable job is **green locally**:

```bash
git add -A
git commit -m "fix CI: <what failed> (ciloop iteration N)"
git push
```

One push per iteration — not one per fix.

### 5. Confirm the re-run

```bash
git rev-parse HEAD   # new sha — watch THIS run, not the stale one
gh run watch <new-run-id> --exit-status
```

Guard against acting on a stale run: only evaluate the run whose `headSha` matches the new local HEAD.

### 6. Exit conditions

- New run is **green** → done.
- Still red **with fixable failures** → back to step 1, until **--max-iterations**.
- Only **hand-back** failures remain → stop and report (don't burn iterations on what you won't fix).

## Common mistakes

| Mistake | Fix |
|---|---|
| Using CI as the edit-test loop (push every fix) | Reproduce locally, fix to local-green, push once. |
| Pushing a fix you couldn't reproduce locally | If it won't run locally, it's hand-back — don't guess. |
| Reading "job failed" but not the actual error | Always `--log-failed` and find the causing line. |
| Watching the old run after pushing | Re-resolve the run id for the new HEAD sha before watching. |
| Looping forever on a flaky/infra failure | Classify it hand-back; stop and report instead. |
| "Fixing" a flaky test by rerunning until it passes | That's hand-back — report it; don't mask flakiness. |

## Report

```
Ciloop complete.
  Branch:      eng-522-migrate-the-voice_service
  Iterations:  2
  Fixed:       lint (3 files), typecheck (1 error), unit test auth.spec.ts
  Handed back: e2e job — flaky (timeout on external service), not a code issue
  Final CI:    green ✅
```

If stopped at max iterations or on hand-back failures, list each remaining failure with its real error
and a suggested next step.
