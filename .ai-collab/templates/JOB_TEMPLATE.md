# JOB

## Job ID

JOB-YYYY-MM-DD-001

## Title

[Fill in job title]

## Original Request

> [Paste the human owner's request here VERBATIM. Do not paraphrase, translate,
> summarize, or clean up. This text is the final authority on intent: when any
> later phase disagrees about what was wanted, arbitrate against this section,
> not against the orchestrator's interpretation below.]

## Goal

[Describe what this job must achieve. Tag statements with provenance:
`[stated]` = human said it, `[inferred]` = follows from request/codebase,
`[assumed]` = orchestrator default that needs confirmation. See `INTAKE.md`.]

## Background

[Describe the current problem, context, known failures, and why this job matters.]

## User-Facing Behavior

[Describe what the user should see after the job is complete.]

## Owner

- HUMAN_OWNER:
- Requested by:
- Created at:
- Target date:

## Non-Goals

This job must not:

- [Non-goal 1]
- [Non-goal 2]
- [Non-goal 3]

## Acceptance Criteria

Every criterion must be verifiable: it maps to a command that can be run or a
concrete manual check. "Works correctly" is not a criterion.

- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Assumptions

All `[assumed]` items from this document, collected for one-shot confirmation
by the human owner. Confirmed assumptions become `[stated]`.

| # | Assumption | Status |
| --- | --- | --- |
| A1 | [Assumption] | proposed / confirmed / rejected |

## Intake Q&A

Questions asked during intake and the human owner's answers (see `INTAKE.md`).

| # | Question | Answer |
| --- | --- | --- |
| Q1 |  |  |

## Risk Areas

- [Example] Database migration
- [Example] Payment flow
- [Example] Authentication
- [Example] API contract
- [Example] Generated files
- [Example] Legacy behavior

## Forbidden Scope

- [File/module/behavior that must not be changed]
- [Unrelated refactor]
- [Public API changes unless approved]

## Required Verification

- [ ] Unit tests
- [ ] Integration tests
- [ ] Typecheck
- [ ] Lint
- [ ] Build
- [ ] Smoke test
- [ ] Real data test

## UI delegation (when applicable)

[Grant UD-ID; design baseline; target platforms and inputs; platforms required to close; delegated design surfaces and writer; OS-level input permission and notification; human-only checks; checkpoint interval. See `UI-POLICY.md` "Grant".]

## Inputs

| Input | Location | Notes |
| --- | --- | --- |
| Brief |  |  |
| Existing docs |  |  |
| Constraints |  |  |

## Close Check

- [ ] Review has no blocking findings.
- [ ] Verification evidence is recorded.
- [ ] Final handoff is written.
- [ ] Remaining risks are listed.

## Human Final Acceptance

The Human Owner must review final behavior and decide whether remaining risk is acceptable.

## Links

- Task board: `BOARD.md`
- Decisions: `DECISIONS.md`
- Worktrees: `WORKTREES.md`
