# GitHub Actions plumbing for ciloop

Verified `gh run` commands the loop relies on. All flags confirmed against `gh` CLI.

## Find the latest run for the current branch HEAD

```bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
HEAD_SHA=$(git rev-parse HEAD)

gh run list --branch "$BRANCH" --limit 10 \
  --json databaseId,headSha,status,conclusion,workflowName,event \
  --jq "[.[] | select(.headSha==\"$HEAD_SHA\")] | sort_by(.databaseId) | last"
```

Selecting by `headSha` is what keeps you off a **stale run** — after you push, the old run is still in
the list; only the one matching the current local HEAD is the one to evaluate.

- `status`: `queued` · `in_progress` · `completed`
- `conclusion` (when completed): `success` · `failure` · `cancelled` · `skipped` · `timed_out`

If `status != completed`, wait for it before judging (see watch, below).

## List the failing jobs and steps

```bash
gh run view <run-id> --json jobs \
  --jq '.jobs[] | select(.conclusion=="failure")
        | {name, steps: [.steps[] | select(.conclusion=="failure") | .name]}'
```

`jobs[]` each have `name`, `status`, `conclusion`, and `steps[]` (`name`, `number`, `conclusion`).

## Read the real error

```bash
gh run view <run-id> --log-failed          # logs for only the failed steps
gh run view <run-id> --log                  # full log if you need surrounding context
gh run view <run-id> --job <job-id> --log   # one job's full log
```

Find the **causing line** (the actual `error TS2345: ...`, `✕ test name`, `Error: ...`), not just the
job name. That line is what you reproduce locally.

## Map a failing job to its local command

```bash
cat .github/workflows/*.y*ml
```

Find the job whose `name:` (or job key) matches the failed job, then the failed step's `run:` value —
that exact command is what you run locally to reproduce (`pnpm lint`, `pnpm typecheck`, `pnpm test x`,
etc.). If the step uses a composite/marketplace `uses:` action with no visible `run:`, fall back to the
obvious local command for the job's purpose; if you can't reproduce it locally, classify it hand-back.

## Watch the re-run after pushing

```bash
# re-resolve the run id for the NEW HEAD first (see "find the latest run" above)
gh run watch <new-run-id> --exit-status    # blocks until done; non-zero exit if it failed
```

`--exit-status` makes it scriptable: `gh run watch <id> --exit-status && echo green || echo still-red`.

## Quick "is CI green for HEAD?" check

```bash
gh run view <run-id> --json status,conclusion --jq 'select(.status=="completed") | .conclusion'
```

Empty output → still running. `success` → green. Anything else → re-enter the loop.
