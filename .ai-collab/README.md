# AI Collaboration Template

This directory is the file-based contract for multi-agent work in this repo.
Use it to coordinate roles, agent assignments, task handoffs, review, verification,
and final delivery without relying on long chat context.

## Core Ideas

- Roles are abstract.
- Agents are replaceable.
- Any AI agent can be assigned to any role.
- Multi-agent execution should use git worktree isolation.
- All cross-agent communication must be written to files.
- Do not rely on long chat context.
- Reviewers report findings, but do not decide what gets fixed.
- Executors implement tasks, but do not decide when the job is complete.
- The orchestrator arbitrates findings and controls scope.
- The human owner has final product and risk acceptance authority.

## Known Limitation: One Job At A Time

`JOB.md`, `STATE.md`, and `BOARD.md` describe exactly one active job. Do not
start a second job while one is active; finish it, block it, or have the human
owner cancel it first. Parallelism happens at the TASK level (multiple executor
worktrees inside one job), not at the job level.

## Directory Layout

| Path | Purpose |
| --- | --- |
| `README.md` | How to use this template. |
| `ROLES.md` | Abstract responsibilities for each collaboration role. |
| `AGENT_REGISTRY.md` | Available agent capabilities, without role binding. |
| `MODELS.md` | Human-editable model config: default model, effort levels, and how the orchestrator picks model + thinking effort. |
| `ASSIGNMENT.md` | Current job role assignments and conflict rules. |
| `ONBOARDING.md` | First-contact briefing: introduce the system, ask for role assignment. |
| `INTAKE.md` | How a raw human request becomes a confirmed job. |
| `JOB.md` | Current job brief, scope, non-goals, and success criteria. |
| `STATE.md` | Current state, blockers, ownership, and timestamps. |
| `CONTEXT.md` | Tier-0 job digest: one-line task ledger, decision summaries, pointers. Read this INSTEAD of the archive when resuming or amending. |
| `MEMORY.md` | Cross-project lessons: recurring problems with proven fixes (symptom → root cause → solution → asset). Check when a symptom looks familiar; update at every retrospective. Travels with the template. |
| `BOARD.md` | Task board for cross-agent status tracking. |
| `DECISIONS.md` | Decision log and open decision requests. |
| `WORKTREES.md` | Worktree policy and active workspace registry. |
| `ORCHESTRATOR_PROMPT.md` | Prompt contract for the orchestrator. |
| `EXECUTOR_PROMPT.md` | Prompt contract for executors. |
| `REVIEWER_PROMPT.md` | Prompt contract for reviewers, including severity definitions. |
| `VERIFIER_PROMPT.md` | Prompt contract for verifiers. |
| `RUNBOOK.md` | Environment-specific tool bindings (the only tool-aware file). |
| `events.ndjson` | Append-only machine-readable event stream. |
| `templates/` | Source templates for job, task, report, review, verification, and handoff files. |
| `skills/` | User-provided custom skills any agent can discover and apply (see `skills/README.md`). |
| `tasks/` | Task contracts from orchestrator to executors. |
| `reports/` | Executor progress and completion reports. |
| `reviews/` | Reviewer findings and arbitration notes. |
| `verification/` | Verification plans, evidence, and results. |
| `handoff/` | Final handoff notes and release-ready summaries. |
| `logs/` | Local run logs that support reports or verification. |

## Standard Flow

1. Human owner provides a raw request; orchestrator runs intake per `INTAKE.md`
   (verbatim capture, provenance-tagged draft, clarifying questions, human
   confirmation, Definition of Ready gate) to produce `JOB.md`.
2. Orchestrator reads per the tiered-reading rules (see "Tiered Reading"
   below and `ORCHESTRATOR_PROMPT.md`): `STATE.md` + `CONTEXT.md` first, other
   files only when the current step needs them.
3. Orchestrator creates narrow task files in `tasks/`.
4. Executor works in an isolated git worktree when code changes are needed.
5. Executor writes a report in `reports/`.
6. Verifier records objective checks in `verification/`.
7. Reviewer writes findings in `reviews/`.
8. Orchestrator arbitrates findings and records decisions in `DECISIONS.md`.
9. Valid findings inside the task's scope become the next round of the same task (`ORCHESTRATOR_PROMPT.md` "Fix Loop"); other valid work becomes a new narrow task.
10. Orchestrator performs a close check and writes final handoff in `handoff/`.
11. Human owner accepts or rejects the final result.

## Complete Workflow

### 1. Intake And Job Setup

- Run the intake procedure in `INTAKE.md`: capture the human request verbatim,
  draft `JOB.md` with provenance tags, ask at most 5 clarifying questions,
  collect assumptions for confirmation, and pass the Definition of Ready gate.
- Fill `JOB.md` with goal, background, user-facing behavior, non-goals, acceptance criteria, forbidden scope, and required verification.
- Fill `ASSIGNMENT.md` with the role-to-agent mapping for this job only,
  including model and thinking effort per role resolved from `MODELS.md`.
- Set `STATE.md` phase to `PLANNING` and overall status to `TODO`.
- Add the first board entries in `BOARD.md`.
- Append a `job.started` event to `events.ndjson`.

### 2. Task Planning

- Orchestrator creates narrow task files from `templates/TASK_TEMPLATE.md`.
- Each task must define objective, allowed files, forbidden files, branch, worktree, acceptance criteria, required verification, and report path.
- Register planned executor branches and worktrees in `WORKTREES.md`.
- Move planned tasks to `BOARD.md` Ready.
- Append `task.created` and `task.assigned` events.

### 3. Executor Work

- Executor works only in the assigned worktree and branch.
- Executor modifies only allowed files and stops if requirements are unclear.
- Executor runs required verification or marks unrun checks as `NOT RUN` with reasons.
- Executor writes a report from `templates/EXECUTOR_REPORT_TEMPLATE.md`.
- Executor marks the task `REPORT_READY`, updates board/state, and appends `report.ready`.

### 4. Verification

- Verifier runs objective checks from the executor worktree or from the main worktree after merge, depending on the task.
- Verifier writes `verification/TASK-XXX-R<n>-VERIFY.md` (one file per round) from `templates/VERIFY_TEMPLATE.md`.
- Unexecuted checks must remain `NOT RUN`; failed checks must include relevant logs or log paths.
- Append `verification.passed`, `verification.failed`, or another specific verification event.

### 5. Review

- Orchestrator writes a review request from `templates/REVIEW_REQUEST_TEMPLATE.md`
  naming concrete focus areas.
- Reviewer reads the job, task, executor report, branch diff, and verification report if available.
- Reviewer writes findings from `templates/REVIEW_TEMPLATE.md`.
- Reviewer reports findings only; the reviewer does not command the executor and does not decide what gets fixed.
- Move the task to review or arbitration status in `BOARD.md`.

### 6. Arbitration And Fix Loop

- Orchestrator records decisions in `DECISIONS.md` for every reviewer finding.
- Valid bugs or required test gaps inside the task's scope become the next round of the same task: a `## Round <n+1>` section in the task file, on the same branch and worktree.
- Valid work outside the task's scope becomes a new narrow task, with human owner approval when it expands the job's scope.
- False positives, style-only items, out-of-scope findings, or deferred risks are recorded with reasons.
- Human owner decides product behavior, scope expansion, and risk acceptance.
- Repeat executor, verification, review, and arbitration until close criteria are met or the job is blocked, within the round limit and stop conditions of "Fix Loop" in `ORCHESTRATOR_PROMPT.md`.

### 7. Close Check

- Orchestrator verifies acceptance criteria, required verification, arbitrated findings, forbidden files, unexplained diff, scope control, and remaining risks.
- If ready, set `STATE.md` overall status to `READY_TO_CLOSE`.
- Write final handoff from `templates/FINAL_HANDOFF_TEMPLATE.md`.
- Append `close.ready` and `handoff.completed` events.

### 8. Human Acceptance And Cleanup

- Human owner accepts, rejects, or requests follow-up.
- Only human owner or orchestrator merges accepted branches.
- After merge and final verification, remove completed worktrees and delete merged branches.
- Update `STATE.md`, `BOARD.md`, `WORKTREES.md`, and final handoff.
- Append `job.done`, `job.blocked`, or another final job event.

## State Persistence

The `.ai-collab/` files are the shared memory of every agent. Chat context is
disposable; anything not written to a file and committed does not exist.

- State files (`STATE.md`, `BOARD.md`, `WORKTREES.md`, `JOB.md`) always hold
  real current values. When no job is active, `STATE.md` says `NO ACTIVE JOB`.
- Write ahead: update state files before performing the action they describe,
  so an interruption at any moment loses at most one step.
- Commit `.ai-collab/` at every phase transition, after every arbitration, and
  before any handoff or idle period. Suggested message: `collab: JOB-XXX enter <PHASE>`.
- Every new session starts with the Session Recovery procedure in
  `ORCHESTRATOR_PROMPT.md`: read `STATE.md`, replay recent events, reconcile
  declared state against `git status` / `git worktree list`, then resume from
  `Next Expected Action`. When files and repository disagree, the repository wins.
- Executor progress survives interruption inside its worktree: WIP commits stay
  on the task branch and uncommitted changes stay on disk. To continue an
  interrupted task, the orchestrator applies the stale task rule, sets the task
  status to `RESUMING`, and re-dispatches it; the new executor session follows
  the Resume Procedure in `EXECUTOR_PROMPT.md`.

## Tiered Reading (Token Discipline)

The archive (`tasks/`, `reports/`, `reviews/`, `verification/`, full
`DECISIONS.md`) grows with every task; re-reading it on every session start
or acceptance-phase request burns tokens without adding information. The
protocol therefore separates COMPRESSED state from DETAILED records:

- Tier 0 (always read, small and bounded): `STATE.md`, `CONTEXT.md`, the last
  ~10 lines of `events.ndjson`. These answer: where are we, what happened,
  what's next, where does detail live.
- Tier 1 (read when acting): the ACTIVE task file and its report / review /
  verification files; the RUNBOOK section for the step at hand.
- Tier 2 (read on demand only): everything else, opened only when Tier 0/1
  explicitly points there — arbitration against a named finding, close check,
  or rebuilding a lost digest.

Tiered reading controls what ENTERS the context. The second half of token
discipline is that whatever enters the context is re-read (and re-billed,
at cached rates) on EVERY subsequent model turn — per-turn cost grows with
context length, session total with length × turns. Hence:

- Prefer several short sessions over one long one. End a session at a phase
  boundary once state is committed; the next session recovers from Tier 0.
  "Chat context is disposable" is a cost rule as much as a safety rule.
- Batch independent operations into one turn — every extra round trip
  re-reads the whole history.
- Push bulk file exploration and searches to a subagent; only its
  conclusions enter the main context (binding per `RUNBOOK.md`).
- Treat large evidence (screenshots, long diffs, logs) as read-once:
  summarize into the report/digest, keep the path, never re-open it.
- When continuing a long session, compact the conversation at phase
  boundaries (binding per `RUNBOOK.md`).

Rules that make this work:

- `CONTEXT.md` is updated at every phase transition, in the same commit as
  `STATE.md`. A stale digest is treated as a state bug.
- Files of DONE tasks are never re-read wholesale. Their one-line ledger entry
  in `CONTEXT.md` is the authoritative summary; open the underlying file only
  when a current finding or amendment names it.
- New requirements or bugs raised at acceptance follow the Amendment fast path
  in `INTAKE.md`: digest + the `JOB.md` acceptance-criteria section, not a
  full re-intake, and not a full archive read.
- Detail files stay self-sufficient (Contract Files rule below); the digest
  holds conclusions and pointers, never copies of content.

## Custom Skills

`skills/` holds user-provided skills: named, reusable instruction packages in
the Agent Skills format (`skills/<name>/SKILL.md`). The orchestrator scans
them during planning and lists applicable ones in each task contract under
`Relevant Skills`; the assigned agent reads and follows every listed skill.
Format, discovery, and precedence rules live in `skills/README.md`.
Tool-native triggering (for example Claude Code's `.claude/skills/`) is an
environment binding and is defined in `RUNBOOK.md`.

## Contract Files

Every task, report, review, verification note, decision, and handoff should stand
alone. Include enough context that another agent can continue from the file alone.

Recommended filename format:

```text
YYYYMMDD-HHMM-<short-name>.md
```

## Status Values

Use the status values defined by the file that owns the workflow stage:

| File | Status values |
| --- | --- |
| `STATE.md` phase | `INTAKE`, `PLANNING`, `EXECUTION`, `REVIEW`, `ARBITRATION`, `VERIFICATION`, `CLOSE_CHECK`, `DONE`, `BLOCKED` |
| `STATE.md` overall | `TODO`, `RUNNING`, `BLOCKED`, `NEEDS_REVIEW`, `NEEDS_FIX`, `READY_TO_CLOSE`, `DONE` |
| `tasks/*.md` | `TODO`, `ASSIGNED`, `RUNNING`, `RESUMING`, `BLOCKED`, `REPORT_READY`, `REVIEW_PENDING`, `VERIFY_PENDING`, `DONE` |
| `WORKTREES.md` | `TODO`, `CREATED`, `RUNNING`, `BLOCKED`, `REPORT_READY`, `REVIEW_PENDING`, `VERIFY_PENDING`, `MERGED`, `CLEANED_UP`, `CANCELLED`, `UNAVAILABLE` |
| `reports/*.md` | `REPORT_READY`, `BLOCKED`, `NEEDS_CLARIFICATION` |
| `reviews/*.md` | `REVIEW_READY`, `BLOCKED`; recommended outcome `PASS`, `NEEDS_ARBITRATION`, or `BLOCKED` |
| `verification/*.md` | `PASS`, `FAIL`, `PARTIAL`, `BLOCKED`, `NOT RUN` |
| `handoff/*.md` | `DONE`, `PARTIALLY_DONE`, `BLOCKED`, `CANCELLED` |

## Event Log

Append one JSON object per line to `events.ndjson`. Do not add Markdown, comments,
blank explanatory blocks, or trailing commas.

Required event fields:

```json
{"ts":"2026-07-02T00:00:00Z","type":"job.created","actor":"ORCHESTRATOR","summary":"Job created"}
```

Timestamps use ISO 8601 with an explicit offset (`2026-07-04T15:30:00+08:00`)
or `Z`. Stay consistent within a job.

### Concurrency Rule

`events.ndjson` is append-only, but concurrent appends to the same file from
multiple agents can interleave and corrupt lines. Therefore:

- Only agents operating in the MAIN worktree (orchestrator, scribe, reviewer,
  verifier) append to the main worktree's `events.ndjson` directly.
- Executors append to `.ai-collab/events.ndjson` inside their OWN worktree and
  commit it on their task branch. Each worktree is a separate checkout, so
  there is no file contention. `.gitattributes` sets `merge=union` for
  `*.ndjson`, so merging the task branch combines both event streams.
- Events are append-only history: never rewrite, reorder, or dedupe past lines,
  including after a union merge.

Recommended event types:

- `job.created`
- `intake.started`
- `intake.questions`
- `intake.confirmed`
- `job.started`
- `job.updated`
- `job.blocked`
- `job.done`
- `assignment.updated`
- `task.created`
- `task.assigned`
- `task.started`
- `task.blocked`
- `worktree.created`
- `files.modified`
- `test.started`
- `test.passed`
- `test.failed`
- `report.ready`
- `review.started`
- `review.ready`
- `arbitration.started`
- `finding.accepted`
- `finding.rejected`
- `verification.started`
- `verification.passed`
- `verification.failed`
- `decision.recorded`
- `state.reconciled`
- `close_check.started`
- `close.ready`
- `handoff.completed`
- `agent.dispatched`
- `agent.exited`
- `agent.retry`
- `agent.denied`
- `loop.limit_reached`

## Conflict Handling

When files, decisions, or task ownership conflict, follow `ASSIGNMENT.md`.
If the conflict cannot be resolved there, escalate to `HUMAN_OWNER` and record the
outcome in `DECISIONS.md`.

## Final Handoff

The final handoff must include:

- Scope completed
- Scope not completed
- Verification evidence
- Known risks
- Modified files or worktrees
- Required human follow-up
