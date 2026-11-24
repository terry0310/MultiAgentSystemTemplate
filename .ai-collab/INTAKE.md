# INTAKE

This file defines how a raw human request becomes a job the orchestrator can
execute. Intake is the first phase of every job. Do not create tasks, branches,
or worktrees during intake.

## Why Intake Exists

Humans provide natural-language requests. The orchestrator needs acceptance
criteria, forbidden scope, and verification requirements. Intake is the
controlled translation between the two, with the original request preserved as
the final authority on intent.

## Procedure

### Step 0: Onboarding (first contact only)

If the human has not yet stated a request, present the briefing in
`ONBOARDING.md` first — it introduces the system, shows detected agents, and
asks for role assignment plus the request. Intake proper starts when the
request arrives.

### Step 1: Capture The Original Request Verbatim

- Initialize `JOB.md` from `templates/JOB_TEMPLATE.md` (JOB.md holds the real
  current job only; the template stays untouched).
- Copy the human request word-for-word into the `Original Request` section of
  `JOB.md`. Do not paraphrase, translate, summarize, or "clean up".
- The original request is the arbitration source. Whenever a later phase
  disagrees about what the human wanted, return to the original text, not to
  the orchestrator's interpretation of it.
- Set `STATE.md` phase to `INTAKE`, overall status to `TODO`.
- Append an `intake.started` event.

### Step 2: Draft The Job With Provenance Tags

Fill the rest of `JOB.md`. Tag every non-trivial statement with its provenance:

| Tag | Meaning |
| --- | --- |
| `[stated]` | The human said this explicitly. |
| `[inferred]` | Follows from the request or the codebase; low risk if wrong. |
| `[assumed]` | The orchestrator chose a default; must be confirmed. |

Rules:

- Every `[assumed]` item must also appear in the `Assumptions` section of
  `JOB.md` so the human can confirm them all in one place.
- Acceptance criteria must be verifiable: each criterion maps to either a
  command that can be run or a concrete manual check a human can perform.
  "Works correctly" is not a criterion.
- Criteria that involve localized / non-ASCII strings (中文 UI text, accented
  labels) must require RUNTIME byte-level verification of the rendered or
  stored strings, not just a green test suite — encoding corruption can pass
  tests when the test expectations were corrupted the same way.
- Non-goals and forbidden scope must be written even if the human did not
  mention them. Propose them as `[assumed]` when necessary.

### Step 3: Ask Clarifying Questions With Discipline

- Ask at most 5 questions in one batch. Do not interrogate iteratively.
- Only ask a question when the answer would change what gets built or how it
  is verified. Everything else gets a sensible default tagged `[assumed]`.
- Always resolve these three, either by asking or by an explicit assumption:
  1. How is success verified? (test command, manual scenario, real data)
  2. What must NOT change? (forbidden scope)
  3. Is real-data or production-like verification required?
- Record questions and answers in the `Intake Q&A` section of `JOB.md`.
  Answers are `[stated]` provenance.

For UI work, confirm one grant with the job, using the fields in [UI-POLICY.md](UI-POLICY.md) "Grant": the product goal, design baseline, target platforms and inputs, required platforms for acceptance, delegated choices, editable design files and their writer, whether agents may send OS-level input on the operator's machine (and whether to notify first), the human-only checks, and the checkpoint interval. Apply [UI-POLICY.md](UI-POLICY.md), log the human grant in [UI-DECISIONS.md](UI-DECISIONS.md), and cite its ID in the job. Seek clarification later only for choices outside the grant. A job can contain both UI and standard tasks.

### Step 3b: Resolve Role Assignment

- Take the human's one-line assignment instruction or preset name; default to
  preset `solo` if none was given (presets and fallback rules live in
  `AGENT_REGISTRY.md`).
- Run the availability check and fill both tables in `ASSIGNMENT.md`.
- Resolve model and thinking effort per role from `MODELS.md` (defaults and
  per-role floor table) and fill the `Model / Effort` column in
  `ASSIGNMENT.md`. An explicit model instruction from the human is `[stated]`
  and overrides `MODELS.md` defaults.
- Any fallback substitution (especially a reviewer in the same model family as
  the executor) is listed alongside the assumptions in Step 4.

### Step 4: Human Confirmation

- Present the draft `JOB.md` to the human owner: goal, acceptance criteria,
  non-goals, forbidden scope, the full assumptions list, and the resolved role
  assignment.
- The human confirms, edits, or rejects. Record the confirmation in
  `DECISIONS.md` as a decision by `HUMAN_OWNER`.
- Append an `intake.confirmed` event.

### Step 5: Definition Of Ready Gate

The job may enter `PLANNING` only when ALL of these are true:

- [ ] `Original Request` is captured verbatim.
- [ ] Goal is filled and consistent with the original request.
- [ ] Every acceptance criterion is verifiable (command or concrete manual check).
- [ ] Non-goals are filled.
- [ ] Forbidden scope is filled.
- [ ] Required verification is filled.
- [ ] All `[assumed]` items are listed in `Assumptions` and confirmed by the
      human owner, or explicitly delegated ("proceed on your assumptions").
- [ ] `ASSIGNMENT.md` is filled for this job and every assigned agent passed
      the availability check.
- [ ] Job confirmation is recorded in `DECISIONS.md`.

If any item is unmet, the job stays in `INTAKE`. Do not create tasks.

When the gate passes: set `STATE.md` phase to `PLANNING`, append `job.started`,
and commit `.ai-collab/` with message `collab: JOB-XXX enter PLANNING`.

## Amendments (New Requirements Or Bugs At Acceptance Time)

When the human owner responds to a delivered result with new requirements or
bug reports, do NOT restart intake and do NOT re-read the job archive. The
amendment path is deliberately cheap:

1. Read only: `STATE.md`, `CONTEXT.md`, and the Acceptance Criteria section of
   `JOB.md`. That is enough context to scope the amendment; the task ledger in
   `CONTEXT.md` tells you where existing behavior was implemented if you need
   a pointer.
2. Capture the feedback verbatim in an `Amendment N` subsection of `JOB.md`'s
   Original Request area, with new acceptance criteria numbered continuing the
   existing sequence (AC9, AC10, ...). Provenance tags apply as usual.
3. Distinguish bug from scope change: a bug (delivered behavior violates an
   existing criterion) needs no human confirmation to fix; a scope change
   (new behavior) needs a one-line confirmation and a `HUMAN_OWNER` decision
   in `DECISIONS.md`. For UI amendments, keep the behavior ruling in `UI-DECISIONS.md` and link its ID from the scope approval.
4. Ask at most the questions the new criteria strictly need (the Step 3
   discipline applies; usually zero or one).
5. Create the narrow follow-up task(s), update `CONTEXT.md` and `STATE.md`,
   set phase back to `EXECUTION`, and commit. The Definition of Ready gate
   applies only to the NEW criteria, not to re-validating the whole job.

## Small Requests

For trivial jobs (single obvious change, no risk surface), intake may be
compressed to one message: draft goal, one acceptance criterion, assumptions,
and ask for a single yes/no confirmation. The verbatim original request and the
Definition of Ready gate still apply.

## Intake Events

- `intake.started`
- `intake.questions` (optional, when questions are sent to the human)
- `intake.confirmed`

## Anti-Patterns

- Starting implementation "while waiting" for intake answers.
- Rewriting the human's request into what the orchestrator finds cleaner, then
  arbitrating against the rewrite.
- Question storms: asking about things a default would cover.
- Acceptance criteria that cannot fail (vague, unmeasurable, or tautological).
