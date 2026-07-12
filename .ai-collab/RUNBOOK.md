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
| Dispatch executor | `ASSIGNMENT.md` | Use the assigned agent invocation. |
| Verification | `VERIFIER_PROMPT.md` | Run the exact commands listed in the task's Required Verification. |
| Review | `REVIEWER_PROMPT.md` | Use a different model family when possible. |
| State and events | `README.md` | Edit files directly; never keep state only in chat. |

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

## Model And Effort Binding

Which model and effort level to use is decided by `MODELS.md`. This section records how the current environment maps those abstract choices to concrete commands.

| Tool | Model selection | Thinking effort mapping |
| --- | --- | --- |
| Claude Code | TBD | TBD |
| Codex CLI | `codex exec -m <model> "<bootstrap>"` | Map `NONE/LOW/MEDIUM/HIGH` to the CLI's supported reasoning effort flags. |
| Gemini CLI | `gemini -m <model> -p "<bootstrap>"` | Usually model choice only. |
| Ollama adapter | Adapter argument, e.g. `[adapter command] TASK-XXX <model>` | Usually `NONE`. |

## Environment Rules

- Do not reference harness-specific tools in protocol files other than this runbook.
- If a binding listed here is unavailable, fall back to raw commands in `WORKTREES.md` and record the substitution.
- Record the exact command used in the task file or report.
