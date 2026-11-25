---
name: ux-autopilot
description: Coordinate delegated UI decisions, interaction debugging, real-input verification and UX review. Use when a task's Workflow field selects UI under the UI policy.
metadata:
  roles: [ORCHESTRATOR, EXECUTOR, REVIEWER, VERIFIER]
---

# UX Autopilot

Read the task's grant and the [UI policy](../../UI-POLICY.md). The task contract and role permissions govern every action; this skill grants no permissions.

## Steps

1. **Describe.** Write each issue as: starting state, input, observed outcome, expected outcome, and the user's next action. For a new screen, list the affected states and transitions with the design source.
2. **Inventory and matrix.** The orchestrator writes the state and transition inventory and expands it into the interaction matrix (UI policy, "Planning a UI task"). Use the [interaction-design](../interaction-design/SKILL.md) state inventory template.
3. **Decide.** The orchestrator resolves clear specification questions directly. When a convention is needed, assign [research](references/research.md) with a [UI check request](../../templates/UI_CHECK_REQUEST_TEMPLATE.md). Classify every gap as A1-A4 or B, record it as a UD row, and cite the UD-ID in the contract. Name the one design-file writer if the baseline is edited.
4. **Implement.** The executor fixes the assigned batch. Reproduce each defect before the fix when possible, add a regression test named after the defect ID, and exercise the adjacent transitions. Keep the same defect ID for the same failed outcome.
5. **Verify.** The verifier runs the round's tier (T1 or T2), selects [evidence appropriate to each claim](testing.md), and follows the [interaction testing guide](references/interaction-testing.md) when the task needs real input. On Windows desktop, the optional runner is `scripts/ui-input-windows.ps1` when `RUNBOOK.md` binds it.
6. **Review.** The reviewer follows the [QA guide](references/qa-review.md) and uses [design-critique](../design-critique/SKILL.md) for heuristics.
7. **Arbitrate.** The orchestrator arbitrates every finding, updates the defect ledger and repair counts, and records each UI ruling in [UI-DECISIONS.md](../../UI-DECISIONS.md). Link each confirmed defect to its regression test and evidence in the task.
8. **Keep knowledge.** Add a reusable, framework-neutral rule to [interaction-patterns.md](references/interaction-patterns.md). Framework- or project-specific notes go to the project's `RUNBOOK.md` or `MEMORY.md`.

Resume from the standard state and task files.

## Bundled design skills

[interaction-design](../interaction-design/SKILL.md) and [design-critique](../design-critique/SKILL.md) are vendored unchanged from upstream revision `7e25e66e87f64f9d3dea22198f9e29937e7c48f5`, with their original support files and MIT licenses. Do not edit them; record local guidance in this skill instead.
