---
name: git-worktree-design
description: >-
  Use when a request contains several independent features, or mentions
  "worktree", "git worktree", or "parallel branches" — analyze how to split
  the work into parallel executor tasks, then set up the protocol-compliant
  branches and worktrees after confirmation.
metadata:
  roles: [ORCHESTRATOR]
---

# Git Worktree Design — Parallel Task Split Planning

Analyze whether a request should be split into multiple parallel executor
tasks, design the split and its dependencies, and create the worktrees per
protocol after confirmation.

This skill is the **planning layer** on top of `WORKTREES.md`: how to split,
into how many tasks, with what dependencies and merge order is decided here;
the mechanical rules for naming, registration, creation, and cleanup always
come from `.ai-collab/WORKTREES.md` — this document defines no competing
rules.

## Procedure

### 1. Analyze Current State

```bash
git branch --show-current   # should be the default branch in the main worktree
git worktree list           # compare against the Active Worktrees table in WORKTREES.md
git status --short          # the main worktree should be clean
git fetch                   # sync first when a remote exists
```

- Uncommitted changes: handle them first (commit or stash) before continuing.
- `git worktree list` disagrees with the `WORKTREES.md` registry: reconcile
  the registry first per the Session Recovery rules; never stack new worktrees
  on top of an inconsistent state.
- Check `STATE.md`: the protocol runs one job at a time — parallelism happens
  at the TASK level. This skill splits one job into multiple executor tasks,
  never into multiple jobs.

### 2. Split The Request

Split the request into independent executor tasks, each mapping to one branch
plus one worktree (the protocol's core rule:
`1 executor task = 1 branch = 1 worktree`).

**Split principles:**

| Principle | Meaning |
|------|------|
| Functional independence | One independent objective per task; tasks never compete for the same files |
| Minimal dependency | Each task should be developable, testable, and reviewable on its own; when that is impossible, record the dependency direction explicitly |
| Task granularity | Follow the "narrow" definition in `ORCHESTRATOR_PROMPT.md`: one objective, roughly 5 or fewer allowed files, a diff readable in one sitting, acceptance verifiable without other unfinished tasks |
| File partitioning | Use Allowed / Forbidden Files to keep tasks apart; a shared file both tasks need goes into the task that merges first |

**Naming always follows the protocol** (`WORKTREES.md` Branch / Worktree
Naming):

```text
Task ID:   TASK-001, TASK-002, ...
Branch:    agent/TASK-001
Worktree:  ../<repo-dir-name>.TASK-001   # sibling of the main repo, never inside it
```

### 3. Design Each Task Contract

For every task, **derive** the full content from the original request and the
current state of the project (never hand out blank templates), using
`templates/TASK_TEMPLATE.md` as the format:

| Template field | What to decide at design time |
|----------|------------------|
| Objective | The single goal this task must achieve |
| Allowed / Forbidden Files | The file partition that keeps parallel tasks from trampling each other |
| Relevant Skills | Applicable skills found by scanning `.ai-collab/skills/` |
| Acceptance Criteria | Independently verifiable behavior, not dependent on other unfinished tasks |
| Required Verification | Concrete commands, specific enough for the executor to run as-is |
| Background | Cross-task dependencies, suggested merge order, shared interface agreements |

> Key point: handle cross-task dependencies at design time — for example,
> whether a shared module produced by task A affects task B, and whether the
> merge order matters. For dependent tasks, state "merge X first", or make
> them sequential instead.

### 4. Present The Full Plan And Confirm

```text
📋 Worktree split plan (N tasks)

| # | Task | Branch | Worktree | Feature | Depends on |
|---|------|------|----------|----------|------|
| 1 | TASK-001 | agent/TASK-001 | ../project.TASK-001 | Config parsing module | None |
| 2 | TASK-002 | agent/TASK-002 | ../project.TASK-002 | CLI interface | Interface agreement from TASK-001 |

📝 Task contract summaries:
(per task: objective, acceptance criteria, dependencies)

Suggested merge order: TASK-001 → TASK-002

Proceed? (Y/n)
```

Show the complete plan (split + contract summaries) to the human owner and
wait for confirmation. Trade-offs of scope or risk are the human owner's
call — do not make them on their behalf.

### 5. Create Per Protocol (Write-Ahead Order)

After confirmation, **register first, create second**:

1. Add every task to the Active Worktrees table in `WORKTREES.md` (status
   `TODO`).
2. Write the task contracts to `.ai-collab/tasks/TASK-XXX.md` and update
   `BOARD.md` and `STATE.md` accordingly.
3. Create the worktrees one by one (command details: `WORKTREES.md` Standard
   Commands):

   ```bash
   git worktree add -b agent/TASK-001 ../project.TASK-001 main
   ```

4. Flip the registry status to `CREATED`, append the matching events to
   `events.ndjson`, and commit the `.ai-collab/` state changes (for example
   `collab: JOB-XXX register TASK-001..003 worktrees`).

### 6. Prepare The Environments

Each worktree is a separate directory; decide per ecosystem what needs
per-worktree setup:

- **Dependency installation**: detect the manifest / lockfile to pick the
  command — `package.json` (npm / pnpm / yarn / bun, per the lockfile),
  `requirements.txt` or `pyproject.toml` (pip / poetry / uv), `go.mod` and
  `Cargo.toml` (usually resolved at build time, no pre-install needed), other
  ecosystems per the project README. Prefer package managers with shared
  caches.
- **Environment files**: a fresh worktree lacks untracked files such as
  `.env`; copy them from the main worktree when needed (see `WORKTREES.md`
  Environment Files).
- **External resource isolation**: worktrees isolate files only. When
  parallel tasks touch ports, databases, containers, and similar resources,
  assign non-conflicting resources in the task contracts (see `WORKTREES.md`
  External Resource Isolation).

### 7. Verify The Result

```bash
git worktree list
```

Show a table of each task's worktree, branch, contract path, and registry
status, and point to the next step: dispatch executors per `ASSIGNMENT.md`
and the dispatch patterns in `RUNBOOK.md`.

## Edge Cases

- **Branch already exists**: drop `-b` and use
  `git worktree add <path> <existing-branch>`, after confirming the branch's
  existing content belongs to the same task.
- **Directory already exists**: report the conflict; check whether it is an
  uncleaned old worktree (compare with the registry) — never overwrite.
- **The split yields only one task**: no parallel split is needed; still
  create the single task's worktree per protocol. Do not split for
  splitting's sake.
- **Tasks are too interdependent**: rather than forcing parallelism, make the
  tasks sequential or merge them into one; parallelism presumes low
  dependency.
- **Cleanup**: after merge, cleanup follows the `WORKTREES.md` Cleanup Policy
  and is performed by the human owner or orchestrator; this skill never
  deletes worktrees or branches on its own.
- **Used in a repo without the `.ai-collab/` protocol**: fall back to common
  conventions — branch `feature/<name>`, worktree `../<repo>-<name>`, task
  contracts written as a spec file in each worktree root; the rest of the
  procedure is unchanged.
