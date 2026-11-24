# MEMORY

This file records recurring cross-project lessons and proven solutions.
Machine-specific details belong in `RUNBOOK.md`; job-specific history belongs in git history, reports, reviews, verification files, and handoff documents.

## Usage Rules

- One entry = one recurring problem.
- Use the shape: Symptom -> Root cause -> Solution -> Source.
- Point solutions at executable assets when possible, such as a skill, script, runbook section, or protocol clause.
- Fold new lessons in when writing a retrospective at job close.
- Delete entries that become obsolete.

## Lessons

### M-001 Auto mode blocks dispatching an unsandboxed agent

- Symptom: Claude Code in auto mode denies `codex exec ... -s danger-full-access` with `[Undermining Oversight]`, even when a project allow rule matches the command.
- Root cause: launching an autonomous agent with isolation and per-action approval turned off is a default auto-mode block. Auto mode also drops wildcard-path allow rules and ignores `autoMode` rules in project settings.
- Solution: dispatch every role with its sandbox (`RUNBOOK.md` "Agent Permission Profiles"), move host-only steps to the VERIFIER, and on any denial follow `RUNBOOK.md` "Permission Denials (Claude Code)" instead of retrying another way.
- Source: two Codex dispatches denied in an earlier project (2026-11-18); sandboxed dispatches in the 2026-11-19 tests were not denied.

### M-002 A sandboxed executor cannot commit in a linked worktree

- Symptom: `git add` and `git commit` fail with `Unable to create '.../.git/worktrees/<name>/index.lock': Permission denied`, while `git status` works.
- Root cause: a linked worktree keeps its git metadata in the main repository's `.git`, outside the sandbox's writable folder.
- Solution: the executor leaves its changes uncommitted and lists them; the orchestrator commits the allowed files (`ORCHESTRATOR_PROMPT.md` "Dispatch Rules"). Do not make `.git` writable for the sandbox: hooks and config written there would later run outside it.
- Source: sandbox tests T2 and T3, 2026-11-19.

### M-003 `--ignore-user-config` turns default Codex plugins on

- Symptom: a dispatched Codex run with `--ignore-user-config` reads skill packs and sees app connectors that the user's own config never enabled.
- Root cause: without the user config Codex falls back to default plugin and app settings; skills under `~/.codex/skills/` are discovered either way.
- Solution: add `--disable plugins --disable apps` (`RUNBOOK.md` "Codex CLI Binding") and limit skills through the task contract.
- Source: configuration probes E0, E1, E2 and E7, 2026-11-19.

### M-004 UI tests pass with the harness's default input kind but the real app fails

- Symptom: new UI tests pass, but in the real desktop app pressing a suggestion row closes the list before the click lands, so a mouse cannot select anything.
- Root cause: the test harness defaulted to a mobile platform with touch input and no frame between pointer down and up. On desktop, a text input loses focus at pointer-down outside it, a path the default tests never take.
- Solution: select the target platform and the input kind explicitly in UI tests, split pointer down, a frame and pointer up when timing matters, and add a real-input sweep at T2 (`UI-POLICY.md`, `skills/ux-autopilot/testing.md`).
- Source: UI workflow trial in a desktop app project, 2026-11-24.

### M-005 "Has focus" is not the same as "kept focus"

- Symptom: after an outside click dismisses a popup, the input has focus but all of its text is selected, so the next keystroke replaces it. Tests that assert only "has focus" pass.
- Root cause: the input lost focus on pointer-down and code gave it back on release; some desktop platforms select all text when an input gains focus.
- Solution: keep the input from losing focus in the first place (put the related area in the input's focus or tap group) instead of restoring it afterwards. After every dismissal that keeps the user in the input (Esc, a press outside), type one more character and assert the caret, the selection and the text (`skills/ux-autopilot/references/interaction-patterns.md` IP-005).
- Source: UI workflow trial in a desktop app project, 2026-11-24; found by real OS-level input, not by widget tests.

## Entry Template

### M-001 [Short Title]

- Symptom:
- Root cause:
- Solution:
- Source:
