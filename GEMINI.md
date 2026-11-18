# Multi-Agent Collaboration Repo

This repository uses the file-based multi-agent protocol in `.ai-collab/`.

## Before doing ANY work in this repo

1. Read `.ai-collab/STATE.md` to learn the current job, phase, and next expected action.
   - If you were started with a role bootstrap that names a role other than
     ORCHESTRATOR (for example "You are the EXECUTOR for TASK-001"), do not run
     Session Recovery, onboarding, or intake: go to step 2 and follow that
     role's prompt contract.
   - If it shows an in-progress job, you are resuming interrupted work. Follow the
     Session Recovery procedure in `.ai-collab/ORCHESTRATOR_PROMPT.md` before acting.
   - If it shows `NO ACTIVE JOB` and the human has not yet stated a request,
     present the briefing in `.ai-collab/ONBOARDING.md`: introduce the system,
     show which agents are available on this machine, and ask how to assign
     roles and what to build.
   - If it shows `NO ACTIVE JOB` and the human already stated a request, start
     the intake procedure in `.ai-collab/INTAKE.md` directly.
2. Determine your role from `.ai-collab/ASSIGNMENT.md`, then read the matching
   prompt contract:
   - ORCHESTRATOR: `.ai-collab/ORCHESTRATOR_PROMPT.md`
   - EXECUTOR: `.ai-collab/EXECUTOR_PROMPT.md`
   - REVIEWER: `.ai-collab/REVIEWER_PROMPT.md`
   - VERIFIER: `.ai-collab/VERIFIER_PROMPT.md`
   - All roles: `.ai-collab/ROLES.md`
3. Follow `.ai-collab/README.md` for the workflow, and `.ai-collab/RUNBOOK.md`
   for how abstract steps map to the tools available in this session.
4. Check `.ai-collab/skills/` for user-provided custom skills (discovery rules:
   `.ai-collab/skills/README.md`). Skills listed in your dispatch contract
   (task file, review or verification request) are mandatory reading.

## Hard rules

- All cross-agent communication goes through files under `.ai-collab/`, never chat memory.
- Do not modify code without an assigned task contract in `.ai-collab/tasks/` and,
  for executor work, an assigned git worktree (see `.ai-collab/WORKTREES.md`).
- Commit `.ai-collab/` state changes at every phase transition (see README
  "State Persistence").
- Only the human owner or orchestrator merges branches.
