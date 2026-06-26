# GitHub mechanics for reviewloop

Shared `gh` plumbing the loop reuses across reviewers. Keeps `SKILL.md` focused on the registry and
the loop; the mechanical bits live here.

## Fetch unresolved review threads (paginated)

```bash
gh api graphql -f query='
query($owner:String!,$repo:String!,$pr:Int!,$cursor:String) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$pr) {
      reviewThreads(first:100, after:$cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          comments(first:1) { nodes { author { login __typename } path body } }
        }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO -F pr=PR_NUMBER
```

If `pageInfo.hasNextPage` is true, repeat with `-F cursor=END_CURSOR` until it's false. Filter to
`isResolved == false` to get the work list; read `comments.nodes[0].author.__typename` to classify the
thread's reviewer as `Bot` vs `User`.

## Batch-resolve addressed threads

GitHub has no bulk endpoint, but you can alias multiple mutations into one request:

```bash
gh api graphql -f query='
mutation {
  t1: resolveReviewThread(input: {threadId: "THREAD_ID_1"}) { thread { isResolved } }
  t2: resolveReviewThread(input: {threadId: "THREAD_ID_2"}) { thread { isResolved } }
}'
```

For a human thread, reply *before* resolving so the reviewer sees how it was handled:

```bash
gh api graphql -f query='
mutation { addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: "THREAD_ID", body: "Fixed in <sha> — added the guard clause."}) { comment { id } } }'
```

## Poll a bot check run to a terminal state

Bots that run as CI (Greptile and others) surface as check runs on the head commit. Poll until the
named check reaches a terminal `conclusion`:

```bash
HEAD_SHA=$(gh pr view <PR> --json headRefOid -q .headRefOid)

while true; do
  CHECK=$(gh api "repos/{owner}/{repo}/commits/$HEAD_SHA/check-runs" \
    --jq '.check_runs[] | select(.name | test("greptile"; "i"))' 2>/dev/null)

  if [ -z "$CHECK" ]; then
    echo "Waiting for check to appear..."; sleep 5; continue
  fi

  STATUS=$(echo "$CHECK" | jq -r '.status // "completed"')
  CONCLUSION=$(echo "$CHECK" | jq -r '.conclusion // "pending"')

  if [ "$STATUS" = "completed" ]; then
    echo "Check completed: $CONCLUSION"; break
  fi

  echo "Waiting... (status: $STATUS)"; sleep 10
done
```

Swap the `test("greptile"; "i")` filter for whichever bot's check name you're waiting on.

## Guard: is the bot already running?

Don't re-trigger a bot that's mid-review — you'll just queue duplicate runs. Check before posting the
trigger:

```bash
STATE=$(gh pr checks <PR> --json name,state \
  | jq -r '.[] | select(.name | test("greptile"; "i")) | .state')

if [ "$STATE" != "PENDING" ] && [ "$STATE" != "IN_PROGRESS" ]; then
  gh pr comment <PR> --body "@greptile review"
fi
```

For comment-driven bots (CodeRabbit), apply the same idea by checking the timestamp of the bot's last
comment versus your last push before re-posting `@coderabbitai full review`.
