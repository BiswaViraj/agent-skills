#!/usr/bin/env bash
#
# standup - generate a paste-ready standup from your GitHub activity.
# Pure gh + git, no external deps (uses gh's built-in --jq, not the jq binary).
#
# Usage: standup.sh [--since YYYY-MM-DD] [--user @me] [--no-reviews]
#
set -euo pipefail

SINCE=""
USER_Q="@me"
INCLUDE_REVIEWS=1

while [ $# -gt 0 ]; do
  case "$1" in
    --since)
      if [ "$#" -lt 2 ] || [ -z "${2:-}" ] || [[ "${2:-}" == -* ]]; then
        echo "standup: --since requires YYYY-MM-DD" >&2
        exit 2
      fi
      SINCE="$2"
      shift 2
      ;;
    --user)
      if [ "$#" -lt 2 ] || [ -z "${2:-}" ] || [[ "${2:-}" == -* ]]; then
        echo "standup: --user requires @me or a GitHub login" >&2
        exit 2
      fi
      USER_Q="$2"
      shift 2
      ;;
    --no-reviews)  INCLUDE_REVIEWS=0; shift ;;
    -h|--help)
      echo "usage: standup.sh [--since YYYY-MM-DD] [--user @me] [--no-reviews]"
      exit 0 ;;
    *) echo "standup: unknown arg '$1'" >&2; exit 2 ;;
  esac
done

# --- preflight ---------------------------------------------------------------
command -v gh >/dev/null 2>&1 || {
  echo "standup: gh (GitHub CLI) not found - install from https://cli.github.com" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || {
  echo "standup: not authenticated - run 'gh auth login'" >&2; exit 1; }

# --- date helpers (GNU date first, then BSD/macOS fallback) ------------------
days_ago() { date -d "$1 days ago" +%Y-%m-%d 2>/dev/null || date -v-"$1"d +%Y-%m-%d; }
pretty()   { date -d "$1" "+%a %d %b" 2>/dev/null || date -j -f %Y-%m-%d "$1" "+%a %d %b"; }

# Default window: since the last working day (Mon reaches back to Fri).
if [ -z "$SINCE" ]; then
  case "$(date +%u)" in   # 1=Mon .. 7=Sun
    1) SINCE=$(days_ago 3) ;;   # Monday    -> Friday
    7) SINCE=$(days_ago 2) ;;   # Sunday    -> Friday
    *) SINCE=$(days_ago 1) ;;   # otherwise -> yesterday
  esac
fi
TODAY=$(date +%Y-%m-%d)

# --- queries -----------------------------------------------------------------
LINE_JQ='.[] | "- \(.repository.nameWithOwner)#\(.number) - \(.title)"'
search() { gh search prs --author "$USER_Q" --limit 50 --json number,title,repository --jq "$LINE_JQ" "$@" 2>/dev/null || true; }

MERGED=$(search --merged --merged-at ">=$SINCE")
OPENED=$(gh search prs --author "$USER_Q" --created ">=$SINCE" --limit 50 \
  --json number,title,repository --jq "$LINE_JQ" 2>/dev/null || true)
REVIEWED=""
if [ "$INCLUDE_REVIEWS" -eq 1 ]; then
  REVIEWED=$(gh search prs --reviewed-by "$USER_Q" --updated ">=$SINCE" --limit 50 \
    --json number,title,repository --jq "$LINE_JQ" 2>/dev/null || true)
fi

# Dedup: a PR merged in-window should not also list under Opened. "Opened" means still in flight.
if [ -n "$MERGED" ] && [ -n "$OPENED" ]; then
  MERGED_KEYS=$(printf '%s\n' "$MERGED" | sed -E 's/ - .*$//')   # "- owner/repo#num"
  OPENED=$(printf '%s\n' "$OPENED" | grep -vFf <(printf '%s\n' "$MERGED_KEYS") || true)
fi

# --- render ------------------------------------------------------------------
section() { # $1=prefix  $2=body
  [ -n "$2" ] || return 0
  printf '%s\n' "$2" | sed "s|^- |- $1 |"
}

echo "**Standup - $(pretty "$TODAY")** (since $(pretty "$SINCE"))"
echo
echo "**Done**"
if [ -z "$MERGED$OPENED$REVIEWED" ]; then
  echo "- (nothing merged, opened, or reviewed in this window)"
else
  section "✅ Merged:"   "$MERGED"
  section "🚀 Opened:"   "$OPENED"
  section "👀 Reviewed:" "$REVIEWED"
fi
echo
echo "**Today:** "
echo "**Blockers:** none"
