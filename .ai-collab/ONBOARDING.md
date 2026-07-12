# ONBOARDING

This file defines the briefing an agent presents when a human first engages
with this repository. Its purpose: the human should never have to read the
protocol files to start working — the agent explains the system and asks the
two questions that matter.

## When To Show The Briefing

Show the FULL briefing when all of these are true:

- `STATE.md` says `NO ACTIVE JOB` (or the last job is `DONE`).
- The human has not yet stated a work request (they greeted you, asked what
  this is, or just opened a session).

Show a SHORT version (2-3 lines + the role question folded into intake
confirmation) when the human's first message already contains a work request —
do not block a ready request with ceremony; proceed to `INTAKE.md` directly.

If a job IS active, skip onboarding entirely and follow Session Recovery in
`ORCHESTRATOR_PROMPT.md` instead.

## Before Presenting

1. Read `STATE.md` to confirm no active job.
2. Run the availability check from `AGENT_REGISTRY.md`
   (`command -v claude codex gemini cursor-agent ollama`) so the briefing can
   show what is actually usable on this machine.

## The Briefing

Present the following, translated into the human's language, adapted freely in
wording but not in substance. Keep it compact — aim for one screen.

---

**This repository uses a multi-agent collaboration protocol.** Instead of one
AI doing everything, work is split across roles with separated powers:

| Role | Does | Cannot |
| --- | --- | --- |
| You (Human Owner) | Set direction, accept the final result and risk | — |
| Orchestrator | Clarify the request, split narrow tasks, arbitrate reviews, control scope | Close without evidence |
| Executor | Implement one task in an isolated git worktree | Define "done", merge |
| Reviewer | Find real bugs with evidence | Decide what gets fixed |
| Verifier | Run tests/build; only observed results count | Mark unrun checks as passed |

Every round follows the same loop:
**goal → constraints → diff → tests → review → arbitration → close.**

**How we start:** you describe what you want in plain language. I will capture
it verbatim, draft a job with acceptance criteria, ask at most 5 clarifying
questions, and get your confirmation before any task starts. All progress is
saved to files and committed, so an interrupted session resumes where it left
off.

**Agents detected on this machine:** [list the availability check results,
e.g. "claude ✓, codex ✓, ollama ✓, gemini ✗, cursor-agent ✗"]

**Models:** defaults and effort levels come from `.ai-collab/MODELS.md`; I
pick the model and thinking effort per task from that file, and you can edit
it anytime or override me per job ("用 opus 跑這個").

**Two questions:**

1. **How should I assign roles?** Pick a preset or say it in one sentence:
   - `solo` — I handle all roles with subagents (default; just press on)
   - `standard` — reviewer uses a different model family for independent review
   - `offline` — local models only for model work
   - or custom, e.g. "executor 用 codex, reviewer 用 ollama"
2. **What would you like to build or fix?**

---

## After The Human Answers

- Record the chosen assignment and proceed to `INTAKE.md` Step 1 with their
  request.
- If they only answered one question, proceed with what you have: a request
  with no assignment means preset `solo`; an assignment with no request means
  wait for the request.
- Do not repeat the briefing later in the session, and do not show it again
  on recovery — recovered sessions go straight to work.
