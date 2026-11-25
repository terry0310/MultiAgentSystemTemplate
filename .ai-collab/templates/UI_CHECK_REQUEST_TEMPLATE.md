# UI Check Request: TASK-XXX R<n> (research | interaction)

<!-- Written by the orchestrator for a UI task (UI-POLICY.md). Every expectation
     states its precondition and how to confirm that the precondition holds:
     most wrong expectations come from an assumed state that was not true. -->

## Role and Guide

- Role: researcher ([research.md](../skills/ux-autopilot/references/research.md)) / interaction tester ([interaction-testing.md](../skills/ux-autopilot/references/interaction-testing.md))
- Read first: [exact paths]
- Grant: [UD-ID; whether OS-level input is allowed; notification rule]

## Location

- Repository / worktree:
- Build commit and artifact (interaction):
- Target window or device, platform, input runner (interaction):
- Output file and evidence directory:

## Research Questions (research)

| ID | Question | Platforms | Why it matters (defect / UD-ID) |
| --- | --- | --- | --- |

## Steps (interaction)

| Step | Precondition | How to confirm the precondition | Input | Expected outcome | Next user action and its expected result | Evidence to capture |
| --- | --- | --- | --- | --- | --- | --- |

Timing-sensitive steps: send in one runner call, repeat at least 5 times.

## Rules

- Stop on any blocked or denied command; do not reach the same effect another way.
- Do not modify tracked files or write the decision ledgers.
- Keep private data out of queries and captures.

## Report

[Format from the role guide; write it to the output file above.]
