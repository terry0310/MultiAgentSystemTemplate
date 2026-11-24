# TASK-XXX Review Request

## Task

TASK-XXX

## Job

JOB-YYYY-MM-DD-001

## Round

1

## Commit Range

- Worktree: `<absolute path of the task worktree>`
- Branch: `agent/TASK-XXX`
- Base: `<commit>` (the task's base, or the head of the previous round)
- Head: `<commit>`
- Command: `git diff <base>..<head>`

## Requested By

ORCHESTRATOR

## Requested At

YYYY-MM-DD HH:mm

## Assigned Reviewer

See `.ai-collab/ASSIGNMENT.md`.

## Inputs To Review

<!-- Use absolute paths: the reviewer runs in the task worktree, while the job
     and task files are current only in the main worktree. -->

- `<repo>/.ai-collab/JOB.md` (especially Original Request and Forbidden Scope)
- `<repo>/.ai-collab/tasks/TASK-XXX.md` (including every `## Round` section)
- `<worktree>/.ai-collab/reports/TASK-XXX-R1-EXECUTOR-REPORT.md`
- `<repo>/.ai-collab/verification/TASK-XXX-R1-VERIFY.md` (if available)
- Diff: the Commit Range above

## Review Focus

[Task-specific risk areas the orchestrator wants examined. Examples:
error handling on the new endpoint, migration rollback path, boundary
conditions on the parser. Keep this concrete; "review everything" wastes
the reviewer.]

For UI batches, include the current defect IDs, UI-IDs, applicable skills, input sequences, build and evidence paths. Identify the interaction or state transition requiring independent review. For a text-only reviewer, supply the actual skill instructions, applicable UI rows and revision-specific verification evidence in the input it will receive. If the adapter cannot deliver the required contents or inspect necessary visual evidence, assign a reviewer that can access them.

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
<repo>/.ai-collab/reviews/TASK-XXX-R1-REVIEW.md
```

In a read-only sandbox, do not write the file yourself: make your final
message the complete review, and the dispatcher saves it to that path.

Follow `.ai-collab/REVIEWER_PROMPT.md`, including severity definitions.
Reviewer reports findings only; arbitration belongs to the orchestrator.
