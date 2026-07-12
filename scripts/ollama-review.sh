#!/usr/bin/env bash
# Tier-2 adapter: run the REVIEWER role with a local text-only model via Ollama.
#
# Gathers the review inputs (role contract, review request, job, task,
# executor report, verification, branch diff), sends them to the model in one
# call, post-processes the output (strips thinking blocks and terminal
# control characters), and writes it to the standard review path.
#
# Usage:
#   scripts/ollama-review.sh TASK-001 [model] [base-branch]
#
# Options (env vars):
#   OLLAMA_REVIEW_MODEL   default model when $2 is not given (qwen2.5-coder)
#   DIFF_REPO             path to the repo holding the task branch, when it is
#                         NOT this repo (e.g. an external project repo whose
#                         worktrees carry the agent/TASK-XXX branches). The
#                         .ai-collab contract files are still read from THIS
#                         repo; only the diff comes from DIFF_REPO.
#   DIFF_BRANCH           override the branch to diff (default agent/TASK-XXX)
#
# Reliability: before the real call, the model is warmed up with a one-token
# prompt (large local models fail to load under memory pressure; a warm-up +
# one retry absorbs the common llama-server timeout).
#
# The output is a DRAFT by protocol: the orchestrator must check that it
# follows templates/REVIEW_TEMPLATE.md before treating it as a review.
set -euo pipefail

TASK="${1:?Usage: ollama-review.sh TASK-XXX [model] [base-branch]}"
MODEL="${2:-${OLLAMA_REVIEW_MODEL:-qwen2.5-coder}}"

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

DIFF_REPO="${DIFF_REPO:-$ROOT}"
BRANCH="${DIFF_BRANCH:-agent/${TASK}}"

if [ -n "${3:-}" ]; then
  BASE="$3"
elif git -C "$DIFF_REPO" show-ref --verify --quiet refs/heads/main; then
  BASE="main"
elif git -C "$DIFF_REPO" show-ref --verify --quiet refs/heads/master; then
  BASE="master"
else
  echo "error: cannot detect base branch in ${DIFF_REPO}; pass it as the third argument" >&2
  exit 1
fi

OUT=".ai-collab/reviews/${TASK}-REVIEW.md"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

command -v ollama >/dev/null || { echo "error: ollama not found on PATH" >&2; exit 1; }
[ -f ".ai-collab/tasks/${TASK}.md" ] || { echo "error: .ai-collab/tasks/${TASK}.md not found" >&2; exit 1; }
git -C "$DIFF_REPO" show-ref --verify --quiet "refs/heads/${BRANCH}" \
  || { echo "error: branch ${BRANCH} not found in ${DIFF_REPO}" >&2; exit 1; }

# Warm-up: force the model into memory before the real (large) request.
# Large models fail to load under memory pressure; retry once after a pause.
warmup() { echo "Reply with the single word: ready" | ollama run "$MODEL" --hidethinking >/dev/null 2>&1; }
echo "Warming up ${MODEL}..." >&2
if ! warmup; then
  echo "warm-up failed; retrying in 15s (free some RAM if this persists)" >&2
  sleep 15
  warmup || { echo "error: model ${MODEL} failed to load twice; check available RAM (see MODELS.md notes)" >&2; exit 1; }
fi

section() { printf '\n\n===== %s =====\n\n' "$1"; }
optional_cat() { [ -f "$1" ] && cat "$1" || echo "(file not present: $1)"; }

{
  cat .ai-collab/REVIEWER_PROMPT.md
  section "REVIEW REQUEST"
  optional_cat ".ai-collab/reviews/${TASK}-REVIEW-REQUEST.md"
  section "JOB"
  cat .ai-collab/JOB.md
  section "TASK CONTRACT"
  cat ".ai-collab/tasks/${TASK}.md"
  section "EXECUTOR REPORT"
  optional_cat ".ai-collab/reports/${TASK}-EXECUTOR-REPORT.md"
  section "VERIFICATION"
  optional_cat ".ai-collab/verification/${TASK}-VERIFY.md"
  section "DIFF ${BASE}..${BRANCH}"
  git -C "$DIFF_REPO" diff "${BASE}..${BRANCH}"
  section "OUTPUT FORMAT (follow exactly)"
  cat .ai-collab/templates/REVIEW_TEMPLATE.md
  section "INSTRUCTION"
  echo "Write the completed review document for ${TASK} now, following the"
  echo "output format above and the severity definitions in the role contract."
  echo "Output ONLY the Markdown review document, nothing else."
} | ollama run "$MODEL" --hidethinking > "$TMP"

# Post-process into the real output path only after a successful run:
# - strip ANSI/terminal control sequences (spinner residue)
# - strip any <think>...</think> block that slipped past --hidethinking
# - drop leading blank lines
python - "$TMP" "$OUT" <<'PYEOF'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8", errors="replace").read()
text = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", text)          # CSI sequences
text = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f]", "", text)     # other control chars
text = re.sub(r"<think>.*?</think>", "", text, flags=re.S)
text = text.lstrip("\n")
open(dst, "w", encoding="utf-8", newline="\n").write(text)
PYEOF

echo "Review draft written to ${OUT} (model: ${MODEL}, diff repo: ${DIFF_REPO})"
echo "Orchestrator: verify it follows the template before accepting it."
