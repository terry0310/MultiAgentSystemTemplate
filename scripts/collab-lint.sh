#!/usr/bin/env bash
# Consistency lint for .ai-collab bookkeeping files.
#
# Catches the failure modes that manual string-editing produced in practice:
#   - a task row left behind in its old BOARD.md section after a move
#   - malformed table rows (wrong cell count for the section's header)
#   - corrupt / non-JSON lines or missing required fields in events.ndjson
#   - STATE.md phase or overall status outside the allowed value lists
#
# Usage: scripts/collab-lint.sh [folder] (default: git rev-parse --show-toplevel)
# Exit:  0 clean (warnings allowed), 1 on any error.
set -euo pipefail

ROOT="${1:-$(git rev-parse --show-toplevel)}"
cd "$ROOT"

ERRORS=0
err()  { echo "ERROR: $*"; ERRORS=$((ERRORS + 1)); }
warn() { echo "warn:  $*"; }

# ---------- BOARD.md ----------
BOARD=".ai-collab/BOARD.md"
if [ -f "$BOARD" ]; then
  # section + first-cell task id for every data row (skip header/separator)
  BOARD_TASKS=$(awk '
    /^## /   { section = substr($0, 4); next }
    /^\| *-/ { next }                       # separator row
    /^\| Task \|/ || /^\| Job \|/ { next }  # header row
    /^\|/ {
      line = $0
      gsub(/^\| */, "", line); gsub(/ *\|.*$/, "", line)
      if (line ~ /^TASK-[0-9]+/) {
        id = line
        sub(/ .*/, "", id)                  # "TASK-004 (+FIX-001)" -> TASK-004
        print id "\t" section
      }
    }
  ' "$BOARD" | sort -u)

  # duplicate: same task id in more than one section
  DUPS=$(printf '%s\n' "$BOARD_TASKS" | cut -f1 | sort | uniq -d)
  if [ -n "$DUPS" ]; then
    printf '%s\n' "$DUPS" | while read -r dup; do
      secs=$(printf '%s\n' "$BOARD_TASKS" | awk -F '\t' -v id="$dup" '$1 == id {print $2}' | paste -sd ", " -)
      echo "ERROR: BOARD.md: ${dup} appears in multiple sections: ${secs}"
    done
    ERRORS=$((ERRORS + $(printf '%s\n' "$DUPS" | wc -l)))
  fi

  # malformed rows: pipe count differs from the section header's pipe count
  ROW_ERRORS=$(awk '
    /^## /  { header = "" ; next }
    /^\|/ {
      n = gsub(/\|/, "|")
      if ($0 ~ /^\| *-/) next
      if (header == "") { header = n; next }
      if (n != header)
        printf "ERROR: BOARD.md line %d: %d cells but section header has %d\n", NR, n-1, header-1
    }
  ' "$BOARD")
  if [ -n "$ROW_ERRORS" ]; then
    printf '%s\n' "$ROW_ERRORS"
    ERRORS=$((ERRORS + $(printf '%s\n' "$ROW_ERRORS" | wc -l)))
  fi

  # leftover placeholder rows (all-empty first cell) — template residue
  awk '/^\| *\|/ {printf "%d:%s\n", NR, $0}' "$BOARD" | while read -r line; do
    warn "BOARD.md placeholder row (template residue?): ${line}"
  done
else
  warn "$BOARD not found"
fi

# ---------- events.ndjson ----------
EVENTS=".ai-collab/events.ndjson"
if [ -f "$EVENTS" ]; then
  BAD=$(node -e '
    const fs = require("fs");
    const lines = fs.readFileSync(process.argv[1], "utf8").replace(/^\uFEFF/, "").split(/\r?\n/);
    let bad = 0;
    lines.forEach((line, i) => {
      if (!line.trim()) return;
      try {
        const o = JSON.parse(line);
        for (const f of ["ts", "type", "actor", "summary"])
          if (!(f in o)) { console.log(`ERROR: events.ndjson line ${i + 1}: missing field "${f}"`); bad++; }
      } catch (e) {
        console.log(`ERROR: events.ndjson line ${i + 1}: not valid JSON`); bad++;
      }
    });
    process.stdout.write("COUNT:" + bad);
  ' "$EVENTS")
  echo "${BAD%COUNT:*}"
  ERRORS=$((ERRORS + ${BAD##*COUNT:}))
else
  warn "$EVENTS not found"
fi

# ---------- STATE.md ----------
STATE=".ai-collab/STATE.md"
if [ -f "$STATE" ]; then
  PHASE=$(awk '/^## Current Phase/{getline; getline; print; exit}' "$STATE" | tr -d ' \r')
  STATUS=$(awk '/^## Overall Status/{getline; getline; print; exit}' "$STATE" | tr -d ' \r')
  case "$PHASE" in
    INTAKE|PLANNING|EXECUTION|REVIEW|ARBITRATION|VERIFICATION|CLOSE_CHECK|DONE|BLOCKED) ;;
    *) err "STATE.md: invalid phase '$PHASE'" ;;
  esac
  case "$STATUS" in
    TODO|RUNNING|BLOCKED|NEEDS_REVIEW|NEEDS_FIX|READY_TO_CLOSE|DONE) ;;
    *) err "STATE.md: invalid overall status '$STATUS'" ;;
  esac
else
  err "$STATE not found"
fi

echo
if [ "$ERRORS" -gt 0 ]; then
  echo "collab-lint: $ERRORS error(s)."
  exit 1
fi
echo "collab-lint: clean."
