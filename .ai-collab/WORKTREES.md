# WORKTREES

This file defines how git worktrees are used for multi-agent execution.

The goal is to let multiple executor agents work in parallel without modifying
the same working directory.

## Core Rule

Use this mapping whenever possible:

```text
1 executor task = 1 branch = 1 worktree = 1 isolated execution area
```

Only executor tasks require worktrees.

Reviewer and verifier roles do not need separate worktrees by default. They may
use one only when running tests, experiments, or verification steps would modify
files.

## Recommended Layout

Example project name:

```text
project/
```

Recommended directory layout:

```text
workspace/
  project/              # Main control worktree
  project.TASK-001/     # Executor worktree for TASK-001
  project.TASK-002/     # Executor worktree for TASK-002
  project.TASK-003/     # Executor worktree for TASK-003
```

Do not place worktrees inside the main repo directory.

Avoid this:

```text
project/
  worktrees/
    TASK-001/
```

Reason:

- Search tools may scan nested worktrees.
- Test runners may accidentally include nested worktrees.
- Formatters may modify unrelated worktree files.
- Agents may confuse the main repo with nested worktrees.

## Main Worktree Responsibilities

The main worktree is the control center.

Use it for:

- `.ai-collab/` state files.
- Task planning.
- Task assignment.
- Monitoring.
- Review coordination.
- Verification coordination.
- Arbitration.
- Final merge.
- Final verification.
- Cleanup.

The main worktree should usually stay clean.

Before creating new executor worktrees, check:

```bash
git status --short
```

## Executor Worktree Responsibilities

Executor worktrees are for implementation.

Use executor worktrees for:

- Modifying source code.
- Modifying tests.
- Running task-specific commands.
- Committing task-specific changes.
- Producing executor reports.

Executor agents must stay inside their assigned worktree.

A sandboxed executor's writable area is exactly the folder it was started in,
so always start it with the task worktree as its working directory, never the
main worktree. In such a sandbox the executor usually cannot write git
metadata; the orchestrator then commits its changes (see "Dispatch Rules" in
`ORCHESTRATOR_PROMPT.md`).

Executor agents must not:

- Switch branches.
- Merge branches.
- Rebase branches.
- Modify another worktree.
- Modify files outside their task scope.
- Commit unrelated changes.

## Reviewer Responsibilities

Reviewers do not need a separate worktree by default.

Reviewers should inspect:

- The job file.
- The task file.
- The executor report.
- The executor branch diff.
- The verification report, if available.

Reviewer findings go to:

```text
.ai-collab/reviews/TASK-XXX-R<n>-REVIEW.md
```

Reviewers must not directly modify code.
Reviewers must not directly command executors.
Reviewers only report findings; the orchestrator decides whether each finding is valid.

Useful review commands from the main worktree:

```bash
git diff main..agent/TASK-001 --stat
git diff main..agent/TASK-001
git log --oneline --decorate main..agent/TASK-001
```

If the default branch is `master`, use:

```bash
git diff master..agent/TASK-001 --stat
git diff master..agent/TASK-001
git log --oneline --decorate master..agent/TASK-001
```

## Verifier Responsibilities

Verifiers do not need a separate worktree by default.

Verification can happen in one of two ways.

### Option A: Verify From Executor Worktree

Use this when verification should run against the executor's actual working
directory.

```bash
cd ../project.TASK-001
npm test
npm run typecheck
```

### Option B: Verify From Main Worktree After Merge

Use this for final verification after accepted changes are merged.

```bash
cd ../project
git switch main
npm test
npm run typecheck
```

Verification results go to:

```text
.ai-collab/verification/TASK-XXX-R<n>-VERIFY.md
```

Verifiers must not mark unexecuted checks as `PASS`.

## Branch Naming

Use predictable branch names.

Executor branches:

```text
agent/TASK-001
agent/TASK-002
agent/TASK-003
```

Review findings inside a task's scope are fixed as the next round on the same
branch and worktree (`ORCHESTRATOR_PROMPT.md` "Fix Loop"); there are no
separate fix branches. Valid work outside the task's scope becomes a new task
with its own branch, for example `agent/TASK-004`.

Avoid reviewer or verifier branches unless the human owner explicitly asks for them.

## Worktree Naming

Use predictable directory names.

Executor worktrees:

```text
../project.TASK-001
../project.TASK-002
../project.TASK-003
```

Replace `project` with the actual repository directory name.

## Active Worktrees

Maintain this table while executor agents are running.

| Task | Purpose | Branch | Worktree Path | Assigned Role | Assigned Agent | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Status Values

- `TODO`
- `CREATED`
- `RUNNING`
- `BLOCKED`
- `REPORT_READY`
- `REVIEW_PENDING`
- `VERIFY_PENDING`
- `MERGED`
- `CLEANED_UP`
- `CANCELLED`
- `UNAVAILABLE`

Use `UNAVAILABLE` when this template is used outside a git repository.

## Standard Commands

### List Existing Worktrees

```bash
git worktree list
```

### Create Executor Worktree From Main

Use this when starting a new executor task.

```bash
git worktree add -b agent/TASK-001 ../project.TASK-001 main
```

If the default branch is `master`, use:

```bash
git worktree add -b agent/TASK-001 ../project.TASK-001 master
```

### Create Executor Worktree From Current HEAD

Use this when the new task should start from the current checked-out commit.

```bash
git worktree add -b agent/TASK-001 ../project.TASK-001 HEAD
```

### Check Executor Branch Diff From Main

Run from the main worktree:

```bash
git diff main..agent/TASK-001 --stat
git diff main..agent/TASK-001
```

If the default branch is `master`, use:

```bash
git diff master..agent/TASK-001 --stat
git diff master..agent/TASK-001
```

### Check Executor Branch Commits

```bash
git log --oneline --decorate main..agent/TASK-001
```

If the default branch is `master`, use:

```bash
git log --oneline --decorate master..agent/TASK-001
```

### Merge Executor Branch Back To Main

Only the human owner or orchestrator should do this.

```bash
git switch main
git merge --no-ff agent/TASK-001
```

If the default branch is `master`, use:

```bash
git switch master
git merge --no-ff agent/TASK-001
```

### Remove Completed Executor Worktree

```bash
git worktree remove ../project.TASK-001
```

### Delete Branch After Merge

```bash
git branch -d agent/TASK-001
```

If Git refuses because the branch is not merged, do not force delete unless the
human owner approves.

Force delete only when intentionally discarding:

```bash
git branch -D agent/TASK-001
```

### Prune Broken Worktree Metadata

Use this if a worktree folder was manually deleted or metadata is stale.

```bash
git worktree prune
```

## Agent Rules

Every executor working inside a worktree must follow these rules.

### Required

- Stay inside the assigned worktree.
- Stay on the assigned branch.
- Modify only files allowed by the task file.
- Write reports to the paths specified by the task.
- Record commands run and results.
- Update event log when required.
- Stop and report if requirements are unclear.

### Forbidden

Executor agents must not run:

```bash
git switch
git checkout
git merge
git rebase
git reset --hard
git clean -fd
git push --force
```

Unless explicitly instructed by the human owner or orchestrator.

Executor agents must not:

- Modify another task's worktree.
- Modify forbidden files.
- Commit unrelated changes.
- Rewrite history.
- Delete worktrees.
- Delete branches.
- Merge their own branch into main.

## Executor Startup Checklist

Before an executor starts:

- [ ] Task file exists.
- [ ] Branch name is assigned.
- [ ] Worktree path is assigned.
- [ ] Worktree has been created.
- [ ] Executor is inside the correct worktree.
- [ ] Executor has read the task file.
- [ ] Executor understands allowed files.
- [ ] Executor understands forbidden files.
- [ ] Executor understands required verification.
- [ ] Executor knows where to write the report.

Recommended check:

```bash
pwd
git branch --show-current
git status --short
```

## Executor Completion Checklist

Before an executor reports completion:

- [ ] Required implementation is complete.
- [ ] Only allowed files were modified.
- [ ] Required verification was run or clearly marked `NOT RUN` with reason.
- [ ] `git status --short` was checked.
- [ ] `git diff --stat` was checked.
- [ ] Executor report was written.
- [ ] Event log was updated.
- [ ] Changes were committed if the task requires a commit, or, when git
      writes are denied, left in the worktree and listed in the report.
- [ ] Remaining risks were documented.

Recommended commands:

```bash
git status --short
git diff --stat
git diff
```

If committing:

```bash
git add <allowed-files>
git commit -m "TASK-001: <short summary>"
```

## Reviewer Checklist

Before a reviewer writes findings:

- [ ] Read the job file.
- [ ] Read the task file.
- [ ] Read the executor report.
- [ ] Inspect changed files.
- [ ] Inspect diff against base branch.
- [ ] Check forbidden file modifications.
- [ ] Check acceptance criteria.
- [ ] Check verification evidence.
- [ ] Write findings with evidence.
- [ ] Do not directly command executor.

Useful commands from the main worktree:

```bash
git diff main..agent/TASK-001 --stat
git diff main..agent/TASK-001
git log --oneline main..agent/TASK-001
```

## Verifier Checklist

Before a verifier marks verification as `PASS`:

- [ ] Required commands were actually run.
- [ ] Results were recorded.
- [ ] Failures include relevant log excerpts.
- [ ] `NOT RUN` items include reasons.
- [ ] Generated files were checked.
- [ ] Smoke test result is recorded if required.
- [ ] Real data test result is recorded if required.

Verification can be run from the executor worktree:

```bash
cd ../project.TASK-001
npm test
npm run lint
npm run typecheck
npm run build
```

Final verification can be run from the main worktree after merge:

```bash
cd ../project
npm test
npm run lint
npm run typecheck
npm run build
```

## External Resource Isolation

Git worktrees isolate files only. They do not isolate external resources.

Multiple agents may still conflict through:

- Ports.
- Databases.
- Redis.
- Queues.
- Docker containers.
- `.env`.
- Log files.
- API quota.
- Test data.
- Browser sessions.
- Local caches.
- Background services.
- Generated artifacts outside the repo.

When running multiple agents in parallel, assign separate resources when needed.

Examples:

```text
TASK-001 uses port 3001
TASK-002 uses port 3002

TASK-001 uses database app_test_task_001
TASK-002 uses database app_test_task_002
```

## Environment Files

New worktrees may not have local untracked files such as `.env`.

Options:

```bash
cp ../project/.env ../project.TASK-001/.env
```

```text
.env.task-001
.env.task-002
.env.example
```

Agents must not commit secret files.

Before committing, check:

```bash
git status --short
```

## Dependency Installation

Each worktree is a separate directory.

Some ecosystems require installing dependencies per worktree.

Examples:

```bash
npm install
pnpm install
yarn install
pip install -r requirements.txt
```

Prefer package managers with shared caches when possible.

Agents must not modify dependency lockfiles unless the task explicitly allows it.

## Reporting Back To Main Worktree

Executors write their report and events inside their OWN worktree. A
sandboxed executor can write nowhere else, and the files travel with the task
branch. Report filenames are unique per task, round and role, so there is no
write contention.

Example:

```text
../project.TASK-001/.ai-collab/reports/TASK-001-R1-EXECUTOR-REPORT.md
../project.TASK-001/.ai-collab/events.ndjson
```

The orchestrator reads them from the worktree and commits them with the
task's changes when the executor could not commit; the merge brings them to
the main worktree.

Reviews and verification reports belong to the main control worktree:

```text
../project/.ai-collab/reviews/TASK-001-R1-REVIEW.md
../project/.ai-collab/verification/TASK-001-R1-VERIFY.md
```

A reviewer in a read-only sandbox does not write this file itself: its final
message is the review, and the dispatcher saves it to the review path.

## Event Logging

Agents should append events to:

```text
.ai-collab/events.ndjson
```

Events must be append-only.
Do not rewrite previous events.

Concurrency rule: agents in the main worktree append to the main event log
directly. Executors append to the `events.ndjson` INSIDE their own worktree and
commit it on their task branch; `merge=union` in `.gitattributes` combines the
streams at merge time. This avoids two agents appending to the same file at
the same moment.

Example:

```json
{"ts":"YYYY-MM-DDTHH:mm:ss+08:00","type":"task.started","actor":"EXECUTOR","summary":"Started TASK-001 in worktree ../project.TASK-001","job":"JOB-YYYY-MM-DD-001","task":"TASK-001","agent":"Agent B"}
```

## Merge Policy

Only the human owner or orchestrator should merge task branches.

Before merging:

- [ ] Executor report exists.
- [ ] Verification report exists, or missing verification is explicitly accepted.
- [ ] Review findings were arbitrated.
- [ ] No unresolved blocking findings remain.
- [ ] Diff is understood.
- [ ] No forbidden files were modified.
- [ ] Acceptance criteria are satisfied.
- [ ] Human owner approval is obtained if required.

Merge command:

```bash
git switch main
git merge --no-ff agent/TASK-001
```

After merge, run final verification from the main worktree.

## Cleanup Policy

After successful merge and final verification:

```bash
git worktree remove ../project.TASK-001
git branch -d agent/TASK-001
git worktree prune
```

Also update:

- `.ai-collab/BOARD.md`
- `.ai-collab/STATE.md`
- `.ai-collab/WORKTREES.md`
- `.ai-collab/handoff/[final handoff file].md`

Do not delete logs or reports unless the human owner approves.

## Worktree Request Template

```markdown
### Worktree Request

- Task:
- Owner:
- Base branch:
- Proposed branch:
- Proposed path:
- Files expected to change:
- Cleanup owner:
```

## Minimal Workflow

For a simple task:

```bash
# In main worktree
git status --short
git worktree add -b agent/TASK-001 ../project.TASK-001 main

# In executor worktree
cd ../project.TASK-001
git branch --show-current
git status --short

# Executor performs task
# Executor writes report

# In main worktree
git diff main..agent/TASK-001 --stat
git diff main..agent/TASK-001

# Reviewer reviews diff and report from main worktree
# Verifier runs checks from executor worktree or after merge

# If accepted:
git switch main
git merge --no-ff agent/TASK-001

# Cleanup
git worktree remove ../project.TASK-001
git branch -d agent/TASK-001
git worktree prune
```

## Summary

Use the main worktree as the control center.

Use separate worktrees only for parallel executor tasks.

Reviewer and verifier roles do not need their own worktrees by default.

Use separate branches for each executor task.

Use `.ai-collab` files for state, reports, reviews, verification, decisions, and
handoff.

Never let multiple executor agents edit the same working directory at the same
time.

