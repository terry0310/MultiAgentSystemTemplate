# Agent Registry

This file is a catalog of agent TYPES this protocol knows how to bridge.
It does not assign roles (that belongs in `ASSIGNMENT.md`), and it does not
record what is installed on any particular machine (availability is detected
at assignment time, per machine, per session; see Availability Detection).

## Capability Tiers

The protocol is file-based: an agent participates if it can start in the right
directory, read and write files, and run commands. Tiers describe who provides
those abilities.

| Tier | Description | Can serve as |
| --- | --- | --- |
| Tier 1 | Agentic CLI/IDE with its own file and terminal tools. | Any role |
| Tier 2 | Text-only model (local or API). An adapter script gathers inputs, calls the model once, writes the output to the contract file. | REVIEWER, SCRIBE |
| Tier 3 | Deterministic tool: terminal, test runner, CI. Output is command results only. | VERIFIER |

## Known Agent Types

| Agent type | Tier | Entry file it auto-reads | Interactive | Headless invocation |
| --- | --- | --- | --- | --- |
| Claude Code | 1 | `CLAUDE.md` | `claude` | `claude -p "<bootstrap>"` |
| Codex CLI | 1 | `AGENTS.md` | `codex` | `codex exec "<bootstrap>"` |
| Gemini CLI | 1 | `GEMINI.md` | `gemini` | `gemini -p "<bootstrap>"` |
| Cursor Agent | 1 | `AGENTS.md` | IDE / `cursor-agent` | `cursor-agent -p "<bootstrap>"` |
| Agent harness + local model (aider, opencode, goose + Ollama backend) | 1 | varies by harness | varies | varies |
| Ollama (raw model, no harness) | 2 | N/A (adapter feeds it) | N/A | `[adapter command] TASK-XXX <model>` |
| Any chat-only model (web UI, raw API) | 2 | N/A (human or script ferries text) | N/A | adapter or copy-paste |
| Terminal / CI | 3 | N/A | N/A | direct commands |

The bootstrap prompt format is defined in `RUNBOOK.md`. Entry files
(`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) live at the repository root and route
any Tier-1 agent into this protocol.

## Availability Detection

Never assume an agent type is installed, and never record long-term
availability in this file; this repository is shared across machines.

At assignment time (during intake), the orchestrator checks each candidate:

```bash
command -v claude codex gemini cursor-agent ollama
```

(PowerShell: `Get-Command claude, codex, gemini, cursor-agent, ollama`.)

Record the results in the `Agent Availability` table in `ASSIGNMENT.md` for
the current job only. An agent that fails the check is `UNAVAILABLE` for this
job and must not be assigned.

## Minimum Tier Per Role

| Role | Minimum tier | Reason |
| --- | --- | --- |
| ORCHESTRATOR | 1 | Maintains state files, runs git, dispatches work. |
| EXECUTOR | 1 | Needs multi-round edit-test-edit loops. |
| REVIEWER | 2 | One read-in, one findings-document out. |
| VERIFIER | 3 | Command output is the whole contract. |
| SCRIBE | 2 | Summarizes and organizes text. |

## Presets

A preset is a named role-to-agent-type plan the human can pick with one word.
Each slot lists a preference order; the orchestrator resolves it against the
availability check and takes the first available option.

Presets choose agent TYPES only. Which model that agent runs as, and with how
much thinking effort, is resolved separately from `MODELS.md` (defaults plus
effort levels). The two compose: any preset works with any `MODELS.md`
content; under `offline`, only the local-model rows of `MODELS.md` apply.

### `solo` (default)

Everything in one Tier-1 tool. Works anywhere a single agentic CLI exists.

| Role | Preference order |
| --- | --- |
| ORCHESTRATOR | the CLI the human is currently talking to |
| EXECUTOR | subagent (or second session) of the same CLI |
| REVIEWER | subagent of the same CLI (record the independence caveat, see below) |
| VERIFIER | terminal |
| SCRIBE | orchestrator wearing a second hat |

### `standard`

Cross-model independence for review.

| Role | Preference order |
| --- | --- |
| ORCHESTRATOR | strongest available Tier-1 CLI |
| EXECUTOR | any other available Tier-1 CLI, else same CLI subagent |
| REVIEWER | Tier-1 CLI from a DIFFERENT model family than the executor, else Tier-2 local model via adapter, else same-family subagent |
| VERIFIER | terminal |
| SCRIBE | orchestrator |

### `offline`

No cloud calls for model work (verification commands still run locally).

| Role | Preference order |
| --- | --- |
| ORCHESTRATOR | agent harness with local model backend, else human + files |
| EXECUTOR | agent harness with local model backend (aider/opencode/goose + Ollama) |
| REVIEWER | Ollama via adapter command |
| VERIFIER | terminal |
| SCRIBE | Ollama via adapter, else orchestrator |

### Fallback Rules

- If a preferred slot has no available agent, fall back down the preference
  order and record the substitution in `ASSIGNMENT.md`.
- If REVIEWER ends up in the same model family as EXECUTOR, review
  independence is weakened. Proceed only after noting this in `DECISIONS.md`;
  the human owner may insist on a Tier-2 local model instead.
- If no agent can fill a required role, the orchestrator stops and asks the
  human owner. Do not silently skip a role.

## Registration Template

Copy this block when adding another agent type.

```markdown
### Agent Type Name

- Tier:
- Capabilities:
- Entry file:
- Interactive invocation:
- Headless invocation:
- Good fit:
- Poor fit:
- Notes:
```

## Agent Rules

- Do not bind an agent to a role in this file.
- Do not assume one agent owns a role permanently.
- Do not record machine-specific availability in this file.
- Do not start work without an assignment in `ASSIGNMENT.md` or a task contract.
- Write reports that can be understood without chat history.
- Include exact file paths and verification commands in reports.

