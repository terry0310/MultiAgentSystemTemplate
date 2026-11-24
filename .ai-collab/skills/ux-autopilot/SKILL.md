---
name: ux-autopilot
description: Coordinate delegated UI design, interaction debugging and platform verification when the task selects the UI workflow.
metadata:
  roles: [ORCHESTRATOR, EXECUTOR, REVIEWER, VERIFIER]
---

# UX Autopilot

Read the task's grant and the [UI policy](../../UI-POLICY.md). The task contract and role permissions govern every action.

1. Describe each issue as a starting state, input, observed outcome and expected next action. For new screens list the affected states and transitions with the design source.
2. The orchestrator resolves clear spec questions directly. When platform behavior is unclear, assign [research](references/research.md). Apply A1-A4/B and cite each UI-ID in the contract. Identify the sole design-file writer if editing the baseline.
3. The executor works on the assigned batch. Reproduce each defect before the fix when possible, add a named regression and exercise adjacent transitions. Preserve the same defect ID for the same failed outcome.
4. The verifier selects [evidence appropriate to the claim](testing.md) and follows the [interaction testing guide](references/interaction-testing.md) where the task requires actual input. The reviewer uses the [QA guide](references/qa-review.md).
5. The orchestrator arbitrates every finding, updates the task's counts and records UI rulings in [UI-DECISIONS.md](../../UI-DECISIONS.md). Keep reusable interaction patterns discoverable through UI-ID, and link each confirmed defect ID to its regression test and evidence in the task. Resume from the standard state and task files.

## Bundled design skills

The trial recorded upstream revision `7e25e66e87f64f9d3dea22198f9e29937e7c48f5` for [interaction-design](../interaction-design/SKILL.md) and [design-critique](../design-critique/SKILL.md). Both packages retain their original support files and MIT licenses.
