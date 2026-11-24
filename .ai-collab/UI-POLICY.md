# UI policy

## Grant and ownership

Use this policy when the task explicitly selects `UI` and the human owner has approved the UI delegation at intake. An absent selection uses the standard workflow. Record the grant in [UI-DECISIONS.md](UI-DECISIONS.md) and reference its ID in the job and task. The grant identifies the design baseline, target platforms and inputs, delegated choices, required platforms for acceptance and any design files the task may edit. The human owner retains final acceptance and may supersede a decision.

For a new screen, the grant can cover loading, empty, error and focus states within the approved direction and component library. Assign one writer per shared design file. All other roles read the same revision. With a read-only baseline, capture its revision or hash before and after work.

## Triage by the orchestrator

| Class | Authority and evidence |
| --- | --- |
| A1: established behavior | Restore a documented rule or approved design. Cite its section, node or UI-ID and a reproduction. |
| A2: platform convention | Fill a gap when official target-platform guidance directly covers the case, or two independent implementations agree. Cite the sources and the platform. |
| A3: local choice | Decide a reversible detail consistent with existing behavior and the grant. Describe the precedent, affected surface and how to reverse it. |
| A4: test or evidence | Repair a fixture, add a regression or improve evidence within the contract. Preserve the agreed acceptance criterion. |
| B: human decision | Batch questions involving scope, cross-screen behavior, shared design changes outside the grant, conflicts with an approved rule, security, privacy, licensing, risk acceptance or irreversible actions. Treat uncertain authority as B. |

The executor reports a gap to the orchestrator. The orchestrator rules on A items and records the evidence. Where conventions disagree, use A3 only if all its conditions hold. For B, record the pending question and options, request the human owner's ruling, and continue independent authorized work. Use the existing permission-denial and blocker procedures. A classification grants no additional tool or file permissions.

## Decision record and handoff

The orchestrator or assigned scribe appends each UI ruling, including deferrals and human overrides, to the UI ledger. A general scope or permissions approval stays in `DECISIONS.md` with only the related UI-ID. Cite IDs in the task contract, reports and handoff so readers can retrieve the design rationale. Keep defect counts in the task under its Round sections.

## UI repair loop

1. Give each confirmed defect a stable ID tied to its precondition, user input and violated outcome. Reuse a review finding ID if available. Record the platform, related finding or parent defect and acceptance check in the task.
2. Use the existing numbered rounds for dispatch, artifacts, verification and arbitration. Batch compatible in-scope defects in the same task worktree. At planning, agree a finite task budget and a checkpoint (round or time). At a checkpoint the orchestrator reviews progress and evidence, closes or defers permissible findings, or batches more work within the remaining authorization. Only an extension of an exhausted authorized budget or a change of scope needs human approval.
3. Start a defect's repair count at 1 when its first fix is dispatched. Increment once when the same acceptance check still fails or reopens and a further fix for it is dispatched. A different failing behavior gets its own ID and count. Never reset a count by renaming the finding. Tool retries, research, evidence-only requests and formatting carry no repair increment.
4. For UI tasks, the default limit is three repairs **per defect**. Before dispatching a repair above the limit, use the orchestrator's `loop.limit_reached` procedure. The existing early stops for a repeat finding, two consecutive failed verification rounds or a permission, environment or requirement blocker still apply. Use the original defect ID across rounds when assessing these stops.
5. At arbitration update the task's per-defect ledger and next batch, then update `STATE.md`, `CONTEXT.md` and lifecycle events. Close under the ordinary review and verification gates, with current-round evidence for each required platform and outstanding optional checks clearly identified.
