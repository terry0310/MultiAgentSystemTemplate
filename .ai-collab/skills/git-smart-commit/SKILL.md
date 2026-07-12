---
name: git-smart-commit
description: >-
  Use when the working tree has accumulated mixed, unrelated changes that
  should become several clean conventional commits instead of one blob.
  Groups changes by the logical role they play, then stages and commits them
  batch by batch. Works for any language and project type.
metadata:
  roles: [ORCHESTRATOR, EXECUTOR]
---

# Git Smart Commit — Split Messy Changes Into Meaningful Commits

Take all current staged / unstaged / untracked changes, group them into
logical units, then `git add` + `git commit` batch by batch. This skill is
project-type agnostic: grouping is based on the role a change plays in the
project, not on any framework's directory layout.

## Procedure

### 1. Check Change State

```bash
git status --short
```

- No changes at all: tell the user "there is nothing to commit" and stop.
- Unfinished merge / rebase / cherry-pick state: stop and ask the user to
  resolve it first.

Get the change content to drive the grouping decisions:

```bash
git diff
git diff --cached
```

Untracked files do not appear in the diff — read them directly (or use
`git diff --no-index /dev/null <file>`) to judge their purpose. Also note
rename (`R`) and delete (`D`) status codes.

### 2. Detect Project Conventions

Grouping and message style must follow the repository, not a fixed template:

```bash
git log --oneline -20
```

- If existing commits show a clear format (language, conventional-type usage,
  prefix rules), follow it.
- If a contract file in the current environment mandates a commit format (for
  example, tasks in this repo require `TASK-XXX: <summary>`), the contract
  wins: put the conventional description after the mandated prefix, e.g.
  `TASK-001: feat(parser): support nested arrays`.
- If neither exists, default to `<type>(<scope>): <description>`.

### 3. Analyze And Group

Split the file changes into **commit groups**, each an independently
understandable logical unit.

#### Grouping Dimensions (By Priority)

| Priority | Dimension | Typical examples (map to your project type) |
|----------|-----------|------|
| 1 | Project scaffolding / build config | Manifests and build files (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `*.csproj`, `Makefile`, `CMakeLists.txt`), `.gitignore`, linter/formatter config |
| 2 | Dependencies | Lockfile together with the matching manifest dependency changes (same group) |
| 3 | CI/CD and deployment | `.github/workflows/*`, `Dockerfile`, `docker-compose*`, deploy scripts, infra config |
| 4 | Data structures / interface definitions | DB migrations, schemas, `.proto`, OpenAPI specs, shared type definitions |
| 5 | Core code (grouped by feature module) | Implementation files serving one feature within the same module / package / subdirectory |
| 6 | Entry points / public surface | CLI entry points, public APIs, routes, UI pages or components (for applications) |
| 7 | Shared utilities | Utils, helpers, constants, shared config loading |
| 8 | Tests | Tests not committed alongside the module they cover; test infrastructure (fixtures, conftest, test helpers) |
| 9 | Docs and misc | `docs/*`, `*.md`, examples, everything else |

#### Grouping Rules

- Implementation + its tests + its resources (styles, fixtures, config
  snippets) for one feature → same group.
- A lockfile always goes with the manifest change that caused it.
- After each commit the tree should stay buildable and testable as far as
  possible; if a file is needed by two groups, put it in the earlier one.
- A group with a single file and a tiny change (< 5 lines) → merge into the
  most closely related neighboring group.
- New functionality is `feat`, bug fixes are `fix`, behavior-preserving
  cleanup is `refactor`, removals and chores are `chore`.

### 4. Produce A Commit Plan

Before running any git operation, present the plan:

```text
📋 Commit plan (N commits)

1. chore(build): initialize build config and dependencies
   → pyproject.toml, poetry.lock, .gitignore

2. feat(parser): add config file parsing module (with tests)
   → src/parser.py, tests/test_parser.py

...

Proceed? (Y/n)
```

- Interactive session: show the plan to the user and wait for confirmation.
- Inside a dispatched multi-agent task (no human available to confirm): if
  the task contract already authorizes committing these files, execute
  directly and attach this plan verbatim to the report; if not authorized,
  stop and report.

### 5. Commit Batch By Batch

For each group in order:

```bash
git add <file1> <file2> ...
git commit -m "<message in the format detected in step 2>"
```

#### Default Format (When No Convention Exists)

```text
<type>(<scope>): <short description>
```

**Type reference:**

| type | When to use |
|------|---------|
| `feat` | New functionality, module, or command |
| `fix` | Bug fix |
| `refactor` | Restructuring without behavior change |
| `perf` | Performance improvement |
| `style` | Pure formatting / styling (no logic change) |
| `test` | Test-related changes |
| `build` | Build system, dependencies |
| `ci` | CI/CD configuration |
| `docs` | Documentation |
| `chore` | Other maintenance |

**Scope rules:**

- Use the module / package / directory / feature name the change belongs to
  (lowercase), inferred from the project structure, e.g. `parser`, `auth`,
  `cli`, `build`.
- Multiple scopes: pick the dominant one; do not join scopes with slashes.
- Omit the parentheses when no scope fits.

**Subject rules:**

- Language follows the repo's existing commits (step 2); when there is no
  convention, use the language the human owner communicates in.
- At most ~50 characters, no trailing period.
- Start with a verb: add, adjust, fix, remove, refactor.

### 6. Verify The Result

```bash
git log --oneline -20
git status --short
```

Show the outcome: every planned commit exists, and no files from the plan
remain uncommitted in the working tree.

## Edge Cases

- **Unfinished merge / rebase**: perform no operations; ask the user to
  resolve first.
- **Likely sensitive files** (`.env`, keys, certificates, configs containing
  tokens): never auto-commit; ask whether they belong in `.gitignore`.
- **Very large change set (> 50 files)**: produce a grouping summary first
  and get confirmation before executing.
- **Partially staged changes already exist**: respect the existing staged
  state — treat it as its own group or fold it into the most related group;
  do not `git reset` just to regroup.
- **Renames / deletes**: a rename goes with its follow-up edits; bulk
  deletions become their own `chore` or `refactor` commit.
- **Submodule pointer changes**: separate group; the message states the new
  revision being pointed to.
