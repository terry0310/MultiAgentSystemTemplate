# TASK-XXX: [Title]

## Assigned Role

EXECUTOR

## Assigned Agent

See `.ai-collab/ASSIGNMENT.md`.

## Model / Effort

<!-- Effort level and resolved model for this task, chosen per the selection
     rules in .ai-collab/MODELS.md, e.g. "STANDARD - sonnet / MEDIUM".
     Write "Per ASSIGNMENT.md" to use the role-level default. -->

Per ASSIGNMENT.md

## Status

TODO / ASSIGNED / RUNNING / RESUMING / BLOCKED / REPORT_READY / REVIEW_PENDING / VERIFY_PENDING / DONE

## Round

<!-- Current round. Later rounds are appended as "## Round N" sections at the
     end of this file, with the accepted findings as acceptance criteria. -->

1

## Max Rounds

<!-- Standard workflow only. UI tasks use the per-defect repair limit and checkpoints below. -->

3

## Workflow

Standard (default). For an approved UI task, select `UI` and fill the following before dispatch:

- Grant UD-ID, baseline revision, and design writer if any:
- Target platforms and inputs; required and optional platforms; human-only checks:
- State and transition inventory and interaction matrix (path):
- Repair limit per defect (default 3) and checkpoint interval (default 3 rounds):
- Verification commands, T1 (every round) and T2 (checkpoints and close):
- Tier for the current round (T1 or T2):
- Defect ledger (update at each arbitration and fix dispatch):

| Defect ID | Parent / finding | Severity | Platform, precondition, input and expected next action | Repair count | Round / status / evidence | Regression test | UD-ID |
| --- | --- | --- | --- | --- | --- | --- | --- |

List `ux-autopilot` and the relevant design skills in the appropriate dispatch contracts. See [UI policy](../UI-POLICY.md).

## Branch

agent/TASK-XXX

## Worktree

../project.TASK-XXX

## Objective

[One clear objective for this task.]

## Background

[Only necessary context. Keep this short.]

## Allowed Files

- [path/to/allowed/file]

## Forbidden Files

- [path/to/forbidden/file]
- [path/to/forbidden/directory]

## Relevant Skills

<!-- Skills from .ai-collab/skills/ the assigned agent must read and follow.
     Write "None" if no skill applies. -->

- None

## Sandbox / Permissions

<!-- Profile from RUNBOOK.md "Agent Permission Profiles". Changing it needs
     human owner approval. -->

- Executor sandbox: workspace-write
- Network: off
- Extra writable paths: none
- Host-only verification (run by VERIFIER from the orchestrator's terminal): none

## Requirements

- Do only this task.
- Do not expand scope.
- Do not perform unrelated refactors.
- Do not modify forbidden files.
- Do not delete tests.
- Do not weaken validation.
- Do not switch branches.
- Do not merge.
- Do not rebase.
- Stop and report if requirements are unclear.
- If the sandbox denies an action, record it and do not work around it.
- Use only the skills listed under Relevant Skills.

## Acceptance Criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Required Verification

```bash
[command 1]
[command 2]
```

## Checklist

- [ ] Read task file.
- [ ] Read skills listed under Relevant Skills.
- [ ] Confirm current branch.
- [ ] Inspect allowed files.
- [ ] Make minimal change.
- [ ] Run required verification.
- [ ] Check git status.
- [ ] Check git diff --stat.
- [ ] Write executor report.
- [ ] Update event log.
- [ ] Set the report status to `REPORT_READY`.

## Output Report

Write the report inside your worktree to:

```text
.ai-collab/reports/TASK-XXX-R1-EXECUTOR-REPORT.md
```

Later rounds use `R2`, `R3`, and so on.

## Report Must Include

- Summary.
- Files changed.
- Diff summary.
- Commands run.
- Test results.
- Acceptance criteria status.
- Remaining risks.
- Suggested next step.


