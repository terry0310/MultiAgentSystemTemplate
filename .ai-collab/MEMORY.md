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

## Entry Template

### M-001 [Short Title]

- Symptom:
- Root cause:
- Solution:
- Source:
