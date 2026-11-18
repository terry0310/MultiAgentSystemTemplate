#!/usr/bin/env bash
# Pre-dispatch check for one Codex run (ORCHESTRATOR_PROMPT.md "Dispatch Rules").
#
# Read-only. Verifies that:
#   - it runs from the main worktree of the repository
#   - the task file exists
#   - the worktree is a linked worktree of this repository (not the main one),
#     is registered on the task's row in WORKTREES.md, and is on that row's branch
#   - the worktree has no uncommitted changes (an executor of a RESUMING task
#     is the exception)
#   - no row under "Active Runs" in STATE.md mentions the worktree
#   - the output file is the allowed path for the role, and neither it nor the
#     run's log exists yet (a second dispatch of the same run is refused)
#
# Usage: scripts/codex-preflight.sh <TASK-ID> <executor|reviewer> <worktree> <output-file>
#   output: <repo>/.ai-collab/logs/<TASK-ID>-R<n>-<role>[-a<k>].last.md
#   (-a<k> marks the k-th attempt of the same round after an interruption or retry)
# Exit:  0 ready to dispatch, 1 a check failed, 2 usage error.
set -uo pipefail

if [ $# -ne 4 ]; then
  echo "Usage: scripts/codex-preflight.sh <TASK-ID> <executor|reviewer> <worktree> <output-file>" >&2
  exit 2
fi
TASK="$1"; ROLE="$2"; WT_ARG="$3"; OUT_ARG="$4"
case "$ROLE" in executor|reviewer) ;; *) echo "role must be executor or reviewer" >&2; exit 2 ;; esac

ERRORS=0
fail() { echo "FAIL: $*"; ERRORS=$((ERRORS + 1)); }

# Normalize a path for comparison: absolute, forward slashes, no trailing
# slash, and case-folded on Windows (its file system ignores case).
norm() {
  local p="$1"
  if command -v cygpath >/dev/null 2>&1; then p=$(cygpath -m "$p"); fi
  p="${p//\\//}"
  p="${p%/}"
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) p=$(printf '%s' "$p" | tr '[:upper:]' '[:lower:]') ;;
  esac
  printf '%s' "$p"
}

TOP=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "FAIL: not inside a git repository"; exit 1; }
if [ "$(git rev-parse --git-dir)" != "$(git rev-parse --git-common-dir)" ]; then
  fail "run this from the main worktree, not from a linked worktree"
fi
cd "$TOP" || exit 1
TOP_N=$(norm "$TOP")

TASK_FILE=".ai-collab/tasks/$TASK.md"
[ -f "$TASK_FILE" ] || fail "task file $TASK_FILE not found"
STATUS=$(awk '/^## Status/{getline; getline; print; exit}' "$TASK_FILE" 2>/dev/null | tr -d ' \r')

# The worktree must be a linked worktree of this repository.
WT_N=$(norm "$WT_ARG")
WT_BRANCH=""
FOUND=0
while IFS= read -r line; do
  case "$line" in
    "worktree "*) CUR=$(norm "${line#worktree }"); CUR_BRANCH="" ;;
    "branch "*) CUR_BRANCH="${line#branch refs/heads/}"
      if [ "$CUR" = "$WT_N" ]; then FOUND=1; WT_BRANCH="$CUR_BRANCH"; fi ;;
  esac
done < <(git worktree list --porcelain)
[ "$WT_N" = "$TOP_N" ] && fail "the worktree is the main worktree; dispatch only into a task worktree"
[ "$FOUND" = 1 ] || fail "$WT_ARG is not a worktree of this repository (git worktree list)"

# The task's row in WORKTREES.md must name this worktree and its branch.
ROW=$(grep -E "^\|[[:space:]]*$TASK[[:space:]]*\|" .ai-collab/WORKTREES.md 2>/dev/null | head -1)
if [ -z "$ROW" ]; then
  fail "no row for $TASK in WORKTREES.md Active Worktrees"
else
  ROW_BRANCH=$(printf '%s' "$ROW" | awk -F'|' '{print $4}' | tr -d ' `')
  ROW_PATH=$(printf '%s' "$ROW" | awk -F'|' '{print $5}' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | tr -d '`')
  case "$ROW_PATH" in
    /*|[A-Za-z]:*) ROW_ABS="$ROW_PATH" ;;
    *) ROW_ABS=$(cd "$TOP" && cd "$ROW_PATH" 2>/dev/null && pwd) || ROW_ABS="$ROW_PATH" ;;
  esac
  [ "$(norm "$ROW_ABS")" = "$WT_N" ] || fail "WORKTREES.md registers $TASK at '$ROW_PATH', not at $WT_ARG"
  [ "$ROW_BRANCH" = "$WT_BRANCH" ] || fail "WORKTREES.md branch '$ROW_BRANCH' differs from the worktree's branch '$WT_BRANCH'"
fi

# Uncommitted changes.
if [ "$FOUND" = 1 ]; then
  DIRTY=$(git -C "$WT_ARG" status --short 2>/dev/null)
  if [ -n "$DIRTY" ]; then
    if [ "$ROLE" = executor ] && [ "$STATUS" = RESUMING ]; then
      echo "note: worktree has uncommitted changes; expected for a RESUMING task"
    else
      fail "worktree has uncommitted changes (commit or arbitrate them first)"
    fi
  fi
fi

# Active Runs in STATE.md.
RUNS=$(awk '/^## Active Runs/{f=1; next} /^## /{f=0} f' .ai-collab/STATE.md 2>/dev/null \
  | sed 's/<!--.*-->//' | awk '/<!--/{c=1} !c{print} /-->/{c=0}')
RUNS_N=$(printf '%s' "$RUNS" | tr '\\' '/' )
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) RUNS_N=$(printf '%s' "$RUNS_N" | tr '[:upper:]' '[:lower:]') ;; esac
if printf '%s' "$RUNS_N" | grep -qF -- "$WT_N"; then
  fail "STATE.md Active Runs already has a run in this worktree (apply Run Recovery)"
fi

# Output path and duplicate-run guard.
OUT_N=$(norm "$OUT_ARG")
re_escape() { printf '%s' "$1" | sed 's/[][\.*^$+?(){}|]/\\&/g'; }
TOP_RE=$(re_escape "$TOP_N")
TASK_RE=$(re_escape "$TASK")
PATTERN="^$TOP_RE/\.ai-collab/logs/$TASK_RE-r[0-9]+-$ROLE(-a[0-9]+)?\.last\.md$"
printf '%s' "$OUT_N" | grep -qiE -- "$PATTERN" || fail "output '$OUT_ARG' is not the allowed path for a $ROLE run"
# Codex creates the output file as soon as it starts, so any existing file
# means this run id was used before; dispatch the next attempt (-a<k>) instead.
[ -e "$OUT_ARG" ] && fail "output '$OUT_ARG' already exists (a run with this id was dispatched before)"
RUN=$(basename "$OUT_ARG"); RUN="${RUN%.last.md}"
[ -e ".ai-collab/logs/$RUN.jsonl" ] && fail "log .ai-collab/logs/$RUN.jsonl already exists (a run with this id was dispatched before)"

echo
echo "task:     $TASK (status: ${STATUS:-unknown})"
echo "role:     $ROLE"
echo "worktree: $WT_ARG (branch: ${WT_BRANCH:-unknown})"
echo "run:      $RUN"
echo "log:      $TOP/.ai-collab/logs/$RUN.jsonl"
if [ "$ERRORS" -gt 0 ]; then
  echo "codex-preflight: $ERRORS check(s) failed; do not dispatch."
  exit 1
fi
echo "codex-preflight: OK"
exit 0
