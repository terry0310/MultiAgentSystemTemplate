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

TODO / ASSIGNED / RUNNING / BLOCKED / REPORT_READY / REVIEW_PENDING / VERIFY_PENDING / DONE

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
- [ ] Mark status as `REPORT_READY`.

## Output Report

Write report to:

```text
.ai-collab/reports/TASK-XXX-EXECUTOR-REPORT.md
```

## Report Must Include

- Summary.
- Files changed.
- Diff summary.
- Commands run.
- Test results.
- Acceptance criteria status.
- Remaining risks.
- Suggested next step.


