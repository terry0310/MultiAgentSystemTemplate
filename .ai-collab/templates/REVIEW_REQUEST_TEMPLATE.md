# TASK-XXX Review Request

## Task

TASK-XXX

## Job

JOB-YYYY-MM-DD-001

## Requested By

ORCHESTRATOR

## Requested At

YYYY-MM-DD HH:mm

## Assigned Reviewer

See `.ai-collab/ASSIGNMENT.md`.

## Inputs To Review

- `.ai-collab/JOB.md` (especially Original Request and Forbidden Scope)
- `.ai-collab/tasks/TASK-XXX.md`
- `.ai-collab/reports/TASK-XXX-EXECUTOR-REPORT.md`
- `.ai-collab/verification/TASK-XXX-VERIFY.md` (if available)
- Diff: `git diff main..agent/TASK-XXX`

## Review Focus

[Task-specific risk areas the orchestrator wants examined. Examples:
error handling on the new endpoint, migration rollback path, boundary
conditions on the parser. Keep this concrete; "review everything" wastes
the reviewer.]

## Known Concerns

[Anything the executor report flagged as a remaining risk, or the
orchestrator already suspects. The reviewer confirms or refutes with
evidence.]

## Out Of Scope For This Review

- [Areas that must NOT generate findings, e.g. pre-existing code the task
  did not touch, style preferences, planned follow-up tasks.]

## Output

Write findings using `.ai-collab/templates/REVIEW_TEMPLATE.md` to:

```text
.ai-collab/reviews/TASK-XXX-REVIEW.md
```

Follow `.ai-collab/REVIEWER_PROMPT.md`, including severity definitions.
Reviewer reports findings only; arbitration belongs to the orchestrator.
