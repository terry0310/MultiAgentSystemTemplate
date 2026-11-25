# RUNBOOK

This file binds the abstract protocol to the concrete tools available in the current execution environment. All other `.ai-collab/` files stay tool-agnostic on purpose: when the environment changes, rewrite this file and leave the protocol intact.

## Current Environment

- Harness: TBD
- Platform: TBD
- Repository default branch: main / master / TBD

## Availability Checks

Run these during intake and record the results in `ASSIGNMENT.md`.

```bash
command -v claude codex gemini cursor-agent ollama
```

PowerShell equivalent:

```powershell
Get-Command claude, codex, gemini, cursor-agent, ollama -ErrorAction SilentlyContinue
```

## Known Environment Constraints

Record shell, filesystem, encoding, sandbox, dependency, browser, or CI constraints here after they are verified.

## Step-To-Tool Mapping

| Protocol step | Defined in | Binding in this environment |
| --- | --- | --- |
| Intake | `INTAKE.md` | Ask the human owner directly; batch clarifying questions. |
| Create executor worktree | `WORKTREES.md` | Use `git worktree add` or a repo-local helper skill. |
| Dispatch executor | `ASSIGNMENT.md` | Use the assigned agent invocation with the role's profile from "Agent Permission Profiles"; for Codex see "Codex CLI Binding". |
| Pre-dispatch check | `ORCHESTRATOR_PROMPT.md` "Dispatch Rules" | `bash scripts/codex-preflight.sh <TASK-ID> <executor|reviewer> <worktree> <output-file>` |
| Verification | `VERIFIER_PROMPT.md` | Run the exact commands listed in the task's Required Verification. |
| Review | `REVIEWER_PROMPT.md` | Use a different model family when possible. |
| State and events | `README.md` | Edit files directly; never keep state only in chat. |
| Permission denial | `ORCHESTRATOR_PROMPT.md` "Permission Denials" | See "Permission Denials (Claude Code)" below. |

## UI verification tools

At planning, bind the task's target platform and input methods to available runners and record the commands, artifact destination, and operator in the contract. An OS-input check needs an authorized target window or device. For a design file, record its baseline revision and designated writer. Bind these capabilities from the current assignment and environment.

Use `verification/` for the round report. Give evidence a repository-relative tracked path or a shared artifact reference that another machine can resolve, with the build commit and a relevant excerpt. Keep private captures and large logs in an approved store. If an optional device is unavailable, record `NOT RUN`; if a required check cannot execute, record `BLOCKED` and its reason. Human risk acceptance follows the usual governance route.

Optional Windows-desktop runner: `scripts/ui-input-windows.ps1` sends real OS-level mouse and keyboard input to one target window and captures only that window. Use it only when the UI grant allows OS-level input on the operator's machine. Bind it per project here: the process name, the executable to launch, the screenshot root (`-OutRoot`, inside an ignored or approved store), and any project-specific way to read focus from the screen (for example caret or selection colors). Every input step aborts unless the target is the foreground window; the tester then follows `skills/ux-autopilot/references/interaction-testing.md`. Example:

```text
powershell -NoProfile -File scripts/ui-input-windows.ps1 -ProcessName <app> -ExePath <exe> -OutRoot <root> -OutDir <root>/<run> start activate 'type:abc' 'wait:300' 'shot:step1'
```

## Dispatch Patterns

### Same-Session Subagent

Use when the harness supports subagents. The prompt must include the role, prompt file, task file, and worktree path.

### Separate Session / Different Tool

Start the assigned tool in the correct directory with a bootstrap prompt:

```text
You are <ROLE> for <TASK-ID>. Read the repository entry file and follow your role contract in .ai-collab/.
```

### Text-Only Model Via Adapter

Use an adapter script only for roles that can operate from gathered context, usually REVIEWER or SCRIBE. Adapter output is a draft until the orchestrator checks it.

## Agent Permission Profiles

Every dispatched agent runs with the narrowest profile that lets its role do its job. The profile is part of the dispatch contract: the task file's `Sandbox / Permissions` section and the `agent.dispatched` event record it.

| Role | Sandbox | Approval | Can write | Network | Git | Output |
| --- | --- | --- | --- | --- | --- | --- |
| ORCHESTRATOR | Harness permission system | Harness | Main worktree; task worktrees for commits | Harness | Commits and merges per `WORKTREES.md` | State files |
| EXECUTOR | `workspace-write` | `never` | Its own task worktree, plus the OS temp folder | Off unless the task enables it | Read-only in practice (see below) | Code, report and events inside its worktree |
| REVIEWER | `read-only` | `never` | Nothing | Off | Read-only | Final message, saved by the dispatcher to the review path |
| VERIFIER | The orchestrator's own terminal | Harness, per command | Build outputs | Harness | Read-only | `verification/` |

Rules:

- `danger-full-access`, `--dangerously-bypass-approvals-and-sandbox`, `--approve-for-me`, `--add-dir` (pointing at the main worktree or `.git`) and `codex exec --worktree` are not used. A task that seems to need one goes to the human owner first; never switch silently.
- Steps that need host privileges the sandbox cannot give (native builds, UI integration tests, anything that writes tool caches outside the worktree) are VERIFIER steps run from the orchestrator's terminal, where the harness permission system sees every command. They are not a reason to lift the executor's sandbox.
- Writing tests is EXECUTOR work (list the test files under Allowed Files). Running them as evidence is VERIFIER work.
- Sandbox and approval are separate settings. The sandbox limits what commands can touch; the approval policy decides what happens when a command needs more. Headless runs use `never`: a denied action fails and is reported instead of waiting for an answer nobody can give.
- The sandbox isolates writes, not reads. Secrets and licensed data on the same machine are protected only by the task contract; say so in the task when it matters.

## Codex CLI Binding

Verified on Windows 10 19045 with codex-cli 0.169.0 and the elevated Windows sandbox (2026-11-19). Re-verify after upgrading Codex: flags change between versions (`codex mcp-server` no longer exists in 0.169.0).

Placeholders: `<codex>` is the Codex executable recorded in `ASSIGNMENT.md` (it may not be on PATH; on Windows npm installs it as `%APPDATA%\npm\codex.cmd`). `<repo>` is the main worktree, `<worktree>` the task worktree registered in `WORKTREES.md`, `<run>` the run id `TASK-XXX-R<n>-<role>` (`<role>` is `executor` or `reviewer`; a second or later attempt of the same round after an interruption or retry adds `-a<k>`, for example `TASK-002-R1-executor-a2`), `<model>` and `<effort>` come from `MODELS.md`. All paths are absolute.

Common arguments for every role:

```text
--ignore-user-config --disable plugins --disable apps
-m <model> -c 'model_reasoning_effort="<effort>"' -c 'windows.sandbox="elevated"'
-c 'approval_policy="never"' -C '<worktree>' --json
```

- `--ignore-user-config` keeps the user's personal Codex config (MCP servers, extra writable roots, personal defaults) out of dispatched runs, so every run is reproducible from this file. Model, effort and the Windows sandbox mode must therefore be given explicitly.
- Without the user config Codex falls back to default plugins and app connectors (for example skill packs, GitHub and remote-desktop connectors). `--disable plugins --disable apps` removes them; other feature flags showed no further effect in 0.169.0.
- Skills installed directly under `~/.codex/skills/` are still offered to the agent and cannot be switched off from the command line. The executor contract limits the agent to the skills listed in its task file.

EXECUTOR:

```bash
<codex> exec <common arguments> -s workspace-write \
  -o '<repo>/.ai-collab/logs/<run>.last.md' \
  "You are the EXECUTOR for TASK-XXX round <n>. Read <repo>/.ai-collab/tasks/TASK-XXX.md and follow <repo>/.ai-collab/EXECUTOR_PROMPT.md." \
  < /dev/null > '<repo>/.ai-collab/logs/<run>.jsonl' 2> '<repo>/.ai-collab/logs/<run>.stderr.log'
```

REVIEWER:

```bash
<codex> exec <common arguments> -s read-only \
  -o '<repo>/.ai-collab/logs/<run>.last.md' \
  "You are the REVIEWER for TASK-XXX round <n>. Read <repo>/.ai-collab/reviews/TASK-XXX-R<n>-REVIEW-REQUEST.md and follow <repo>/.ai-collab/REVIEWER_PROMPT.md. Your final message is the complete review." \
  < /dev/null > '<repo>/.ai-collab/logs/<run>.jsonl' 2> '<repo>/.ai-collab/logs/<run>.stderr.log'
```

Dispatch rules:

- Run the pre-dispatch check first and dispatch only when it exits 0.
- Keep the bootstrap to one or two sentences. Details belong in the task file or review request, never in a long shell argument.
- Start the command directly: no `cd ... &&` prefix and no wrapper script, so the harness sees the complete command and its sandbox flags. Run it in the background (Claude Code: `run_in_background`); the completion notification carries the exit code.
- Redirect stdin (`< /dev/null`), otherwise `codex exec` waits for input.
- `-o` is written by the Codex process itself, outside the sandbox, so it can write wherever the user can. Use only `<repo>/.ai-collab/logs/<run>.last.md`; the pre-dispatch check enforces it.
- Codex creates the `-o` file, empty, as soon as it starts and fills it at the end. A run is complete only when that file is non-empty AND the `--json` log contains `"type":"turn.completed"`. For a reviewer run, the orchestrator then copies the file to `<repo>/.ai-collab/reviews/TASK-XXX-R<n>-REVIEW.md`.
- A run that fails ends its `--json` log with `{"type":"turn.failed","error":{"message":"..."}}`; that message decides "Run Recovery". An unsupported model, a configuration problem, authentication, or a usage limit is not retryable. A run that simply stops (no `turn.completed`, no `turn.failed`) is a crash or a kill.
- The first `--json` line is `{"type":"thread.started","thread_id":"..."}`. Record the id in the `agent.exited` event; `codex exec resume <id>` can continue that session, but the protocol's own Resume Procedure is the reliable recovery path.
- A hung run: a harness timeout does not stop Codex's child processes. List processes named `cmd.exe`, `node.exe` or `codex.exe` whose command line contains `codex` and the run id (it is part of the `-o` path); filter by name, because your own search command and the harness's shell contain the same text. Stop the tree from the outermost of them (`cmd.exe /c ...codex.cmd exec ...`) with `taskkill /PID <pid> /T /F`; the harness's background shell then exits by itself with a non-zero code. Never stop Codex processes you did not start; the desktop app runs its own.

Observed sandbox behavior:

| Check | Result |
| --- | --- |
| `workspace-write`: write inside the `-C` folder | Allowed |
| Write to the OS temp folder | Allowed |
| Write to the main worktree, another worktree, the repository root, the user profile, the main `.git` | Denied |
| Read files anywhere on the machine | Allowed |
| `git status`, `git diff`, `git log` in a linked worktree | Work |
| `git add`, `git commit` in a linked worktree | Denied (`.git/worktrees/<name>/index.lock`): the orchestrator commits for the executor |
| `read-only`: any write | Denied; the `-o` file is still written |
| `-o` file | Created empty when the run starts, filled when it ends |
| Run stopped with `taskkill /T /F` | Partial file changes stay in the worktree; the `-o` file stays empty |
| `node --test` in either mode | Works |
| Sandbox account | `CodexSandboxOffline` (no network) |

Windows sandbox notes:

- Write access is granted through `CodexSandboxUsers` entries in folder ACLs, and they stay after the run. On the first `workspace-write` run Codex adds a Modify entry to the workspace root itself (the task worktree), not to its parents; the entry goes away with the worktree folder. An entry on a parent folder (left by an earlier run there) is inherited by everything below it: remove such leftovers with `icacls <folder> /remove:g <COMPUTER>\CodexSandboxUsers`, and check `icacls` before relying on a folder being protected.
- Tool caches outside the worktree (package managers, SDKs) are not writable. Point caches into the worktree, or record the toolchain under "Stack Sandbox Needs" before planning in-sandbox builds.

## Stack Sandbox Needs

Fill one row per toolchain before planning tasks that build or test inside the executor sandbox.

| Toolchain | Runs under `workspace-write` | Extra setup | Host-only steps (VERIFIER) | Verified at |
| --- | --- | --- | --- | --- |
| Node.js (`node --test`) | Yes | None | None | 2026-11-19 |

## Permission Denials (Claude Code)

In auto mode the harness classifier may deny an orchestrator action (for example `Blocked by auto mode ... [Undermining Oversight]`). Then:

1. Stop that action. Do not retry it through another tool, shell, wrapper script, flag order, or path; reaching the same effect another way is the circumvention the check exists to prevent.
2. Keep the evidence. The `PermissionDenied` hook in `.claude/settings.json` appends the raw denial (tool name, full `tool_input`, reason) to `.ai-collab/logs/permission-denied.ndjson`. Also save the exact command or edit in `.ai-collab/logs/` when it is long.
3. Append an `agent.denied` event (or `decision.recorded` for a non-dispatch action), set the task to `BLOCKED`, update `STATE.md`, and commit.
4. Ask the human owner, offering: (A) state the exact action in their next message, after which the orchestrator retries it once with the same tool; (B) approve it in `/permissions` → Recently blocked; (C) run or apply it themselves; (D) add an `autoMode.allow` entry in their own `~/.claude/settings.json` for a recurring sanctioned pattern. The orchestrator never edits its own permission settings.

Notes:

- Auto mode ignores `autoMode` rules in project `.claude/settings*.json` and drops broad or wildcard-path allow rules, so a project allow rule is not a reliable way to pre-approve agent dispatch.
- The hook only records. It fires for auto-mode denials, not for denials the human clicks, `deny` rules, or hook blocks.
- A dispatch with the sandbox on was not blocked in testing, while dispatches with `danger-full-access` were. Neither result is guaranteed; the procedure above applies either way.

## Model And Effort Binding

Which model and effort level to use is decided by `MODELS.md`. This section records how the current environment maps those abstract choices to concrete commands.

| Tool | Model selection | Thinking effort mapping |
| --- | --- | --- |
| Claude Code | TBD | TBD |
| Codex CLI | `codex exec -m <model> ...` with the role arguments in "Codex CLI Binding" | `-c 'model_reasoning_effort="<value>"'`: `NONE` → `minimal`, `LOW` → `low`, `MEDIUM` → `medium`, `HIGH` → `high`. |
| Gemini CLI | `gemini -m <model> -p "<bootstrap>"` | Usually model choice only. |
| Ollama adapter | Adapter argument, e.g. `[adapter command] TASK-XXX <model>` | Usually `NONE`. |

## Environment Rules

- Do not reference harness-specific tools in protocol files other than this runbook.
- If a binding listed here is unavailable, fall back to raw commands in `WORKTREES.md` and record the substitution.
- Record the exact command used in the task file or report.
