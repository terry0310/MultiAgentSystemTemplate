# ASSIGNMENT

This file assigns abstract roles to available agents for the current job.

## Job ID

JOB-YYYY-MM-DD-001

## How Roles Get Assigned

During intake the orchestrator:

1. Takes the human owner's one-line assignment instruction or preset name. If none is given, use `solo`.
2. Runs the availability check from `AGENT_REGISTRY.md` and fills `Agent Availability`.
3. Resolves the preset's preference order against availability and fills `Role Assignment`.
4. Resolves model and thinking effort from `MODELS.md` and fills `Model / Effort`.
5. Confirms the final assignment with the human owner before planning tasks.

## Agent Availability

Detected at intake time. Valid for this job only.

| Agent | Check command | Result | Checked at |
| --- | --- | --- | --- |
| claude | `command -v claude` | TBD |  |
| codex | `command -v codex` | TBD |  |
| gemini | `command -v gemini` | TBD |  |
| cursor-agent | `command -v cursor-agent` | TBD |  |
| ollama | `command -v ollama` | TBD |  |

## Assignment Rule

Roles are assigned for this job only.
Do not assume these assignments apply to future jobs.
Do not assume availability from a previous job.

## Role Assignment

| Role | Assigned Agent | Model / Effort | Invocation | Reason |
| --- | --- | --- | --- | --- |
| HUMAN_OWNER | Human | N/A | N/A | Final product acceptance. |
| ORCHESTRATOR | TBD | TBD | TBD | Coordinates task flow, scope, arbitration, and handoff. |
| EXECUTOR | TBD | TBD | TBD | Implements assigned task contracts. |
| REVIEWER | TBD | TBD | TBD | Reviews executor output and records findings. |
| VERIFIER | Terminal / CI | N/A | Direct commands | Objective checks. |
| SCRIBE | TBD | TBD | TBD | Maintains state, decisions, events, and handoff. |

## Assignment Constraints

- Same agent may hold multiple roles only if explicitly listed in `Role Assignment`.
- A role may be assigned to more than one agent only when task ownership is explicit.
- `REVIEWER` should not review work they implemented unless no independent reviewer is available.
- `VERIFIER` may run checks on work they implemented, but must report that overlap.
- If a role is not assigned, `ORCHESTRATOR` must ask `HUMAN_OWNER` before proceeding.
- `HUMAN_OWNER` decisions override all other role decisions.

## Conflict Rules

1. `REVIEWER` cannot directly command `EXECUTOR`.
2. `EXECUTOR` cannot close the task or job.
3. `ORCHESTRATOR` must arbitrate all reviewer findings.
4. `HUMAN_OWNER` has final product acceptance authority.
5. If task ownership conflicts, `ORCHESTRATOR` decides and records the decision.
6. If task scopes overlap on the same files, `ORCHESTRATOR` must split or reassign the tasks before execution.
7. If overlapping file changes are discovered after executor work starts, pause affected tasks and arbitrate from branch diffs.
8. If review and verification disagree, `ORCHESTRATOR` decides whether to request more evidence.
9. If scope changes, only `HUMAN_OWNER` can approve the change.
10. All accepted conflict resolutions must be recorded in `DECISIONS.md`.

## Multi-Agent Worktree Policy

- Each active executor task should use its own git worktree.
- Each task should use its own branch.
- Reviewer may use a separate review worktree if running tests or experiments.
- Verifier may use a separate verify worktree if verification generates files.
- Agents must not modify files outside their assigned worktree when a worktree is assigned.
- Agents without an assigned worktree must not modify code.
- Each worktree must be registered in `WORKTREES.md`.
- Do not share one worktree across independent executor tasks.
- Do not delete a worktree until reports, reviews, verification, and handoff are complete.
- If this directory is used outside a git repo, record worktree status as `UNAVAILABLE`.

## Handoff Policy

- Final handoff requires completed reports, review notes, and verification evidence.
- Unverified work must be listed as a risk.
- Blocked or cancelled tasks must remain visible in `BOARD.md`.
