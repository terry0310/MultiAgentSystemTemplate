# UI policy

This policy applies only to a task whose `Workflow` field selects `UI`, after the human owner has approved a UI grant at intake. Every other task follows the standard workflow. A job can contain both kinds of task.

UI work produces many small defects, and fixing one interaction often exposes the next one in an adjacent state. The policy therefore lets the orchestrator decide routine UI details itself, counts repairs per defect instead of per task, and finds related defects early with an interaction matrix.

## Grant

The human owner approves one grant at intake, for the job or for one UI task. The orchestrator records it as a `UD-####` row in [UI-DECISIONS.md](UI-DECISIONS.md) and cites that ID in `JOB.md` and in every UI task. The grant states:

| Field | Content |
| --- | --- |
| Goal | The product goal of the UI work. |
| Design baseline | The approved design files or specification, with their revision or hash. |
| Platforms and inputs | Target platforms and input methods, for example keyboard, each mouse button, wheel, touch, IME and assistive technology. |
| Required platforms | Platforms that need current evidence before close. Every other platform is optional. |
| Delegated choices | What the orchestrator may decide alone (classes A1-A4 below), and any exclusions. |
| Design-file writer | The one agent allowed to edit each shared design file, if edits are allowed at all. |
| OS-level input | Whether agents may send real mouse and keyboard input on the operator's machine, which windows they may target, and whether to notify the human before each session. |
| Human-only checks | Checks that only a person can perform, for example IME composition, touch, physical gestures or a screen reader, and how the human returns the results. |
| Checkpoint interval | Number of rounds between checkpoints. Default: 3. |

The human owner keeps final acceptance and can supersede any UI decision. For a new screen, the grant can cover loading, empty, error and focus states within the approved direction and component library.

Each shared design file has one writer. All other roles read the same revision. For a read-only baseline, record its revision or hash before and after each round.

## Triage

The executor reports a specification gap to the orchestrator and does not decide it. The orchestrator classifies every gap and every finding:

| Class | The orchestrator may decide when | Evidence to record |
| --- | --- | --- |
| A1: established behavior | A documented rule or approved design already says what should happen. | The section, design node or UD-ID, and a reproduction. |
| A2: platform convention | Official guidance for the target platform covers the case directly, or two independent implementations agree. | The sources, what each says, and the platform. |
| A3: local choice | The detail is reversible, consistent with existing behavior and inside the grant. | The precedent, the affected surface, and how to reverse it. |
| A4: test or evidence | A fixture, regression test or evidence gap can be fixed without changing an agreed acceptance criterion. | The test or evidence added. |
| B: human decision | The item involves scope, behavior across screens, a shared design change outside the grant, a conflict with an approved rule, security, privacy, licensing, risk acceptance or an irreversible action. | The question and its options. |

- When sources disagree, the item can still be A3, but only if every A3 condition holds. Otherwise it is B.
- When the class is uncertain, treat the item as B.
- For B, record the question and options as a `pending` UD row, ask the human owner in one batch, and continue the work that does not depend on the answer.
- A class never grants extra tool or file permissions. Permission denials and blockers follow the standard procedures.

## Decision record

All UI content goes to [UI-DECISIONS.md](UI-DECISIONS.md):

- the grant;
- every UI ruling: A items decided by the orchestrator, and B items decided by the human owner;
- the UI arbitration of every review and verification finding;
- checkpoint rulings, deferrals and human overrides;
- the results of human-only checks.

`DECISIONS.md` keeps only general governance, such as scope approval, permissions, risk acceptance and merges, and cites the related UD-IDs. Task contracts, reports, reviews and the handoff cite UD-IDs so readers can find the rationale. Each task keeps its defect ledger (IDs, counts, status and regression tests) in the task file.

## Planning a UI task

1. Describe each issue as: starting state, user input, observed outcome, expected outcome, and what the user can do next.
2. Write a state and transition inventory of the affected components. The [interaction-design](skills/interaction-design/SKILL.md) skill's state inventory template is a good format.
3. Expand the inventory into an **interaction matrix**: each relevant state against each input in the grant. Inputs include keyboard keys (for example Esc, Tab, Shift+Tab, arrows and Enter), each mouse button, the wheel, an overlay or menu being open, focus loss and window switch, and IME. Mark every cell as automated test, real-input check, human-only, or not applicable.
4. When a cell has no documented rule and needs a convention, assign research ([research guide](skills/ux-autopilot/references/research.md)), then triage the result.
5. Give each confirmed defect a stable ID tied to its precondition, user input and violated outcome. Reuse the review finding ID when there is one. A defect found while fixing another records that one as its parent.
6. In the task, record: the grant UD-ID, where the inventory and matrix are, the defect ledger, the checkpoint interval, and the T1 and T2 verification commands.

## UI repair loop

A round keeps the standard structure and files: executor run, verification, review, arbitration.

**Batching.** Each round fixes every open in-scope defect that can be fixed together in the same task worktree.

**Verification tiers.**

| Tier | When | Contents |
| --- | --- | --- |
| T1 | Every round | Static analysis, the full automated test suite, and real-input checks for this round's defects. |
| T2 | At every checkpoint, after the first round that fixes a defect, and before close | T1, plus the build, the project's end-to-end runs, and a sweep of the whole interaction matrix. |

Every round needs its own passing evidence; T1 is the minimum. Close needs T2 PASS in the final round. The T2 sweep after the first fixing round exists to find derived defects together, instead of one per round.

**Repair count.**

- A defect's count starts at 1 when its first fix is dispatched.
- The count increases by 1 only when the same acceptance check still fails, or the defect reopens, and another fix for it is dispatched.
- A different failing behavior gets its own ID, linked to its parent, and its own count starting at 1. Renaming a finding never resets a count.
- No increment for: a re-dispatch in the same round after `NEEDS_CLARIFICATION`, a tool retry, research, an evidence-only request, or a formatting-only change.

**Severity and deferral.**

- P0-P2 defects inside the task's scope are fixed in this task.
- A P3 defect is fixed when it is in the same component and fits the current batch. Otherwise the orchestrator may defer it as an A3 ruling, recorded as a `deferred` UD row.
- The handoff lists every deferred defect with its UD-ID.

**Checkpoint.** Hold one every N rounds (the grant's interval, default 3), or earlier when no P0-P2 defect is open:

1. Run T2.
2. Review the defect ledger: close fixed defects, defer P3 defects under the rule above, and choose the next batch.
3. Record the checkpoint ruling as a UD row and append a `ui.checkpoint` event.
4. Continue without human approval unless a stop condition applies.

**Stop conditions.** Set the task to `BLOCKED`, append `loop.limit_reached`, and ask the human owner when:

- the next fix for a defect would exceed its repair limit (default 3 per defect);
- the same assertion fails with the same evidence in two consecutive rounds, which means no progress (when a suite reports several results, track each assertion or scenario separately);
- a permission, environment or requirement blocker appears.

A pending B question blocks only the work that depends on it. The standard `Max Rounds` limit and the standard rule "the same finding is accepted in two consecutive rounds" do not apply to UI tasks: a derived defect is progress, not repetition, and a defect that keeps failing is caught by its own repair count.

**Close.**

1. The final round has T2 PASS, and a review that is PASS or has every finding arbitrated as non-blocking, with current evidence for every required platform.
2. Give the human owner the human-only checklist once, at close or at a checkpoint. Each item has steps, the expected result, and what happens on the next user action. Record the answers as UD rows. Optional platforms without evidence are reported as `NOT RUN`.
3. The handoff lists the deferred defects, the outstanding optional checks, and the UD-IDs of this delivery.

## Knowledge

- Reusable interaction rules that do not depend on a framework go to [interaction-patterns.md](skills/ux-autopilot/references/interaction-patterns.md).
- Framework- or project-specific notes stay in the project's `RUNBOOK.md` or `MEMORY.md`.
- Each confirmed defect links to its regression test in the task's defect ledger.
