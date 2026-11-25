# ROLES

Roles are abstract responsibilities.
Any available agent may be assigned to any role in `ASSIGNMENT.md`.

## HUMAN_OWNER

### Responsibility

- Define product direction.
- Define final expected behavior.
- Approve or reject scope expansion.
- Accept or reject remaining risk.
- Perform final product acceptance.

### Authority

- Can change job goal.
- Can approve new scope.
- Can stop the job.
- Can approve delivery.
- Has final authority on product behavior.

### Must Not Delegate

- Final product judgment.
- Business risk acceptance.
- User-facing behavior acceptance.

## ORCHESTRATOR

### Responsibility

- Understand the job goal.
- Break work into narrow tasks.
- Define allowed files and forbidden files.
- Define acceptance criteria.
- Assign work to roles.
- Control scope creep.
- Maintain `STATE.md`, `BOARD.md`, and `WORKTREES.md`.
- Read executor reports.
- Request verification.
- Request reviews.
- Arbitrate reviewer findings.
- Decide whether to open follow-up tasks.
- Decide delegated UI details under [UI-POLICY.md](UI-POLICY.md). Escalate other product decisions to `HUMAN_OWNER`.
- Perform close checks.
- Produce final handoff or delegate handoff drafting to `SCRIBE`.

### Authority

- Can create task files.
- Can assign roles according to `ASSIGNMENT.md`.
- Can reject false-positive review findings.
- Can open new tasks for valid bugs or required test gaps.
- Can escalate product decisions to `HUMAN_OWNER`.

### Must Not

- Must not blindly trust executor completion claims.
- Must not blindly trust reviewer findings.
- Must not send all reviewer findings directly to executor.
- Must not expand scope without `HUMAN_OWNER` approval.
- Must not skip required verification.
- Must not close the job without evidence.

### Required Outputs

- Task files.
- Arbitration decisions.
- Updated state.
- Close check.
- Final handoff.

## EXECUTOR

### Responsibility

- Execute assigned task.
- Modify allowed files only.
- Work only within assigned scope and worktree policy.
- Run required checks.
- Checkpoint progress with WIP commits on the task branch.
- Resume interrupted tasks via the Resume Procedure in `EXECUTOR_PROMPT.md`
  when dispatched with status `RESUMING`.
- Record changed files.
- Record test commands and results.
- Write executor report in `reports/`.
- Stop and report blockers.

### Authority

- Can modify files listed in the task's allowed files section.
- Can propose additional changes.
- Can report blockers.
- Can suggest follow-up tasks.

### Must Not

- Must not modify forbidden files.
- Must not expand scope.
- Must not perform unrelated refactors.
- Must not delete or weaken tests.
- Must not switch branches.
- Must not merge or rebase.
- Must not decide the whole job is complete.

### Required Outputs

- Executor report.
- Git status summary.
- Diff summary.
- Tests run.
- Test results.
- Remaining risks.

## REVIEWER

### Responsibility

- Review executor output.
- Find real bugs.
- Find test gaps.
- Find edge cases.
- Find contract risks.
- Find security risks.
- Find scope creep.
- Find forbidden file modifications.
- Find missing verification.
- Record findings in `reviews/`.

### Authority

- Can create findings.
- Can assign severity.
- Can request evidence.
- Can suggest how to verify a finding.

### Must Not

- Must not directly instruct executor to modify code.
- Must not treat style preference as blocking bug.
- Must not request broad refactors unless directly required.
- Must not decide what gets fixed.
- Must not close the task.

### Required Finding Format

Each finding must include:

- ID.
- Severity.
- Type.
- Claim.
- Evidence.
- Why it matters.
- How to verify.

## VERIFIER

### Responsibility

- Run objective checks.
- Run tests.
- Run lint.
- Run typecheck.
- Run build.
- Run smoke tests.
- Validate with real data if needed.
- Record commands and results in `verification/`.
- Separate verified facts from assumptions.

### Authority

- Can mark verification item as `PASS`, `FAIL`, `BLOCKED`, or `NOT RUN`.
- Can request missing environment information.
- Can provide failure logs.

### Must Not

- Must not mark unexecuted checks as `PASS`.
- Must not hide failure logs.
- Must not rely only on AI claims.
- Must not decide product acceptance.

### Required Outputs

- Verification report.
- Commands run.
- Result summary.
- Relevant failure logs.
- Unverified items.

## SCRIBE

### Responsibility

- Maintain state files.
- Update task board.
- Record UI rulings in `UI-DECISIONS.md` and general decisions in `DECISIONS.md`.
- Compress context into durable notes.
- Maintain handoff documents.
- Append valid events to `events.ndjson`.
- Keep event log readable.

### Authority

- Can summarize.
- Can reorganize documentation.
- Can mark stale information.
- Can update status files.

### Must Not

- Must not change decisions.
- Must not convert uncertainty into fact.
- Must not remove unresolved risks.

## Role Interaction

| From | To | Contract |
| --- | --- | --- |
| ORCHESTRATOR | EXECUTOR | Task file in `tasks/` |
| EXECUTOR | ORCHESTRATOR | Report file in `reports/` |
| ORCHESTRATOR | REVIEWER | Review request in `reviews/` |
| REVIEWER | ORCHESTRATOR | Review findings in `reviews/` |
| ORCHESTRATOR | VERIFIER | Verification request in `verification/` |
| VERIFIER | ORCHESTRATOR | Verification evidence in `verification/` |
| SCRIBE | All roles | Decisions, events, and handoff notes |
