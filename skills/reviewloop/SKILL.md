---
name: reviewloop
description: >
  Use when a PR has feedback from MORE than one reviewer — any mix of bots (Greptile, CodeRabbit,
  Copilot, linters) and human teammates — and the user wants every reviewer driven to a clear state,
  not just one specific bot. Use when the user says "clear all the reviews", "address every reviewer",
  "loop until the PR is clean", or wants bot reviews re-triggered and re-checked automatically.
license: MIT
compatibility: Requires git and gh (GitHub CLI) authenticated, with the relevant review bots installed on the repo. gh >= 2.88.0 for Copilot re-request.
metadata:
  author: Biswajeet Das
  version: "1.0"
allowed-tools: Bash(gh:*) Bash(git:*)
---

# Reviewloop

Drive a PR to **all-clear** across *every* reviewer — each bot AND each human — then loop until
nothing actionable remains.

**Core principle:** A bot is a pure function you can re-invoke (re-trigger → poll → read verdict). A
human is async and uncontrollable. So **bots loop; humans get one pass and then you hand back.** Never
block the loop waiting on a person.

## When to use

- A PR has comments from several reviewers and you want them all resolved in one driven pass.
- The reviewers are a mix you can't name up front — "address whatever's on the PR."
- You want bot reviews **re-triggered** after each fix, not just read once.

**When NOT to use:** You just want a one-shot read of what's outstanding with no loop and no
re-triggering — that's a plain review-check, not this.

## The reviewer registry (the spine)

No uniform code path covers all reviewers. Each needs four things — detect it, re-trigger it, read its
verdict, know when it's done:

| Reviewer | Detect (by login) | Re-trigger | Read verdict | Done-condition |
|---|---|---|---|---|
| **Greptile** | `greptile-apps` (CI check + bot review) | comment `@greptile review` | `N/5` confidence in PR body / its review | `5/5` **and** its threads resolved **and** check `success` |
| **CodeRabbit** | `coderabbitai` | comment `@coderabbitai full review` | walkthrough + inline actionable comments (no score) | zero unresolved actionable CodeRabbit threads |
| **Copilot** | `copilot-pull-request-reviewer` / `Copilot` | `gh pr edit <PR> --add-reviewer @copilot` (gh ≥ 2.88.0) — **NOT a comment, NOT the REST reviewers API** | inline suggestions/comments | zero unresolved Copilot threads on latest head |
| **Other bot** (`__typename: Bot`) | any login, structurally a bot | **unknown — do not guess a command**; report it | read its check run / comments | its check `success` / its threads resolved |
| **Human** (`__typename: User`) | any non-bot login | `gh pr edit <PR> --add-reviewer <login>` to re-request — then **hand back** | inline + summary review (`CHANGES_REQUESTED` / `COMMENTED` / `APPROVED`) | actionable threads resolved + replied + re-review requested → **stop, do not wait** |

**Detection is structural, not an allowlist.** Classify every reviewer by GitHub's `__typename`
(`Bot` vs `User`) first; only *then* look up known bots in the table for their re-trigger command. An
unknown bot is still handled (read + report) — it is never silently skipped.

## Inputs

- **PR number** (optional): default to the PR for the current branch.
- **`--max-iterations N`** (optional, default 5): cap on the bot loop.

## The loop

### 0. Identify the PR

```bash
gh pr view --json number,headRefOid -q '{number: .number, sha: .headRefOid}'
```
Switch to the PR branch if not already on it. Capture `<PR>` and `<HEAD_SHA>`.

### 1. Enumerate reviewers (one query — the heart of the skill)

Pull verdicts, inline threads, and each author's `__typename` in a single GraphQL call:

```bash
gh api graphql -f query='
query($owner:String!,$repo:String!,$pr:Int!,$cursor:String) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$pr) {
      reviews(first:50) { nodes { author { login __typename } state submittedAt body } }
      reviewThreads(first:100, after:$cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id isResolved isOutdated
          comments(first:1) { nodes { author { login __typename } path body } }
        }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO -F pr=<PR>
```

Paginate `reviewThreads` via `endCursor` until `hasNextPage` is false. Also fetch:

- **Bot summaries / scores** (Greptile score, CodeRabbit walkthrough) — issue comments and PR body:
  ```bash
  gh pr view <PR> --json body -q .body
  gh api repos/{owner}/{repo}/issues/<PR>/comments
  ```
- **CI-based bots** (Greptile and others run as checks):
  ```bash
  gh api repos/{owner}/{repo}/commits/<HEAD_SHA>/check-runs --jq '.check_runs[] | {name, status, conclusion}'
  ```

Now build the work list: for each reviewer present, classify (known bot / unknown bot / human) and
collect its **unresolved** threads (`isResolved == false`) and verdict.

### 2. Check the exit condition

Stop the loop when **all** hold:
- Every **bot** reviewer is at its done-condition (table) and its checks are `success`.
- Zero unresolved actionable threads from **any** reviewer (bot or human).
- The human pass (step 6) has been completed once this run.

Or when **max iterations** is hit (report remaining state).

### 3. Fix actionable comments

For each unresolved thread, across all reviewers:
1. Read the file and understand the comment in context.
2. Decide actionable (code change) vs informational / false positive.
3. If actionable, make the fix. If not, note why — you'll still resolve/reply.

Treat human comments with the same rigor as bot comments; do not down-prioritize them.

### 4. Resolve threads

Resolve every thread you've addressed (and informational ones), batching with GraphQL aliases. For the
exact `resolveReviewThread` mutation and thread-fetch pagination, see
[references/github-mechanics.md](references/github-mechanics.md). For human threads, prefer a brief
reply explaining the fix *before* resolving.

### 5. Commit, push, re-trigger bots

```bash
git add -A
git commit -m "address review feedback (reviewloop iteration N)"
git push
sleep 5
```

Then re-trigger **each bot reviewer** by its registry command — but only if it isn't already running
(guard on `check-runs` status / its last comment timestamp first; see
[references/github-mechanics.md](references/github-mechanics.md)):

```bash
# Greptile (only if its check isn't already PENDING/IN_PROGRESS)
gh pr comment <PR> --body "@greptile review"
# CodeRabbit
gh pr comment <PR> --body "@coderabbitai full review"
# Copilot
gh pr edit <PR> --add-reviewer @copilot
```

For an **unknown bot**, do not invent a command — log "no known re-trigger for <login>; left as-is"
and carry its current verdict forward.

### 6. Handle humans — ONE pass, then hand back

For each human reviewer with outstanding feedback:
1. Fix their actionable comments (step 3) and reply + resolve threads (step 4).
2. Re-request their review: `gh pr edit <PR> --add-reviewer <login>`.
3. **Do not poll or wait for them.** Record them as "waiting on @<login>" and continue.

The loop's job for humans ends at "addressed + re-requested." Blocking on a person is out of scope.

### 7. Poll bot completion, then loop

Poll each re-triggered bot's check run / review to a terminal state (the check-run polling loop is in
[references/github-mechanics.md](references/github-mechanics.md)). When all bots are terminal, go back
to **step 1**.

## Common mistakes

| Mistake | Fix |
|---|---|
| Re-triggering Copilot with a comment (`@copilot review`) | Copilot has no comment command — use `gh pr edit <PR> --add-reviewer @copilot`. |
| Filtering reviewers by a hardcoded name list | Detect bot-ness by `__typename == "Bot"`; the name list is only for *re-trigger lookup*. |
| Skipping an unrecognized bot | Read and report it; only its *re-trigger* is unknown, not its feedback. |
| Blocking the loop until a human approves | Humans get one pass; hand back and report. |
| Spamming `@coderabbitai full review` every iteration | One full review per push is enough; guard on whether it's already running. |
| Resolving a human thread with no reply | Reply with the fix first, then resolve — humans read the thread. |

## Report

```
Reviewloop complete.
  PR:             #5876
  Iterations:     3
  Bots cleared:   greptile-apps (5/5), coderabbitai (0 open), Copilot (0 open)
  Humans:         re-requested @neeraj-lightwork-ai (was CHANGES_REQUESTED)
  Resolved:       11 threads
  Remaining:      0 bot / waiting on 1 human
```

If stopped at max iterations, list remaining unresolved threads per reviewer and suggest next steps.
