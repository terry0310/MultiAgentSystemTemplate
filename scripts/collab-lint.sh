#!/usr/bin/env bash
# Consistency lint for .ai-collab bookkeeping files.
#
# Catches the failure modes that manual string-editing produced in practice:
#   - a task row left behind in its old BOARD.md section after a move
#   - malformed table rows (wrong cell count for the section's header)
#   - corrupt / non-JSON lines or missing required fields in events.ndjson
#   - STATE.md phase or overall status outside the allowed value lists
#
# Usage: scripts/collab-lint.sh        (run from anywhere inside the repo)
# Exit:  0 clean (warnings allowed), 1 on any error.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

ERRORS=0
err()  { echo "ERROR: $*"; ERRORS=$((ERRORS + 1)); }
warn() { echo "warn:  $*"; }

# ---------- BOARD.md ----------
BOARD=".ai-collab/BOARD.md"
if [ -f "$BOARD" ]; then
  # section + first-cell task id for every data row (skip header/separator)
  awk '
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
  ' "$BOARD" | sort -u > /tmp/collab-lint-board.$$

  # duplicate: same task id in more than one section
  cut -f1 /tmp/collab-lint-board.$$ | sort | uniq -d | while read -r dup; do
    secs=$(grep "^${dup}	" /tmp/collab-lint-board.$$ | cut -f2 | paste -sd ", " -)
    echo "ERROR: BOARD.md: ${dup} appears in multiple sections: ${secs}"
  done
  DUPS=$(cut -f1 /tmp/collab-lint-board.$$ | sort | uniq -d | wc -l)
  ERRORS=$((ERRORS + DUPS))
  rm -f /tmp/collab-lint-board.$$

  # malformed rows: pipe count differs from the section header's pipe count
  awk '
    /^## /  { header = "" ; next }
    /^\|/ {
      n = gsub(/\|/, "|")
      if ($0 ~ /^\| *-/) next
      if (header == "") { header = n; next }
      if (n != header)
        printf "ERROR: BOARD.md line %d: %d cells but section header has %d\n", NR, n-1, header-1
    }
  ' "$BOARD" | tee /tmp/collab-lint-rows.$$
  ERRORS=$((ERRORS + $(wc -l < /tmp/collab-lint-rows.$$)))
  rm -f /tmp/collab-lint-rows.$$

  # leftover placeholder rows (all-empty first cell) — template residue
  grep -n '^| *|' "$BOARD" | while read -r line; do
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
    const lines = fs.readFileSync(process.argv[1], "utf8").split(/\r?\n/);
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
