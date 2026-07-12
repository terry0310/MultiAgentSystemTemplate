# Multi-Agent Collaboration Protocol

A file-based protocol that lets multiple AI agents — Claude Code, Codex CLI,
Gemini CLI, Cursor, local models via Ollama, or any mix — collaborate on one
codebase with clear authority boundaries, durable memory, and verifiable
results.

No framework, no server, no SDK. The entire protocol is Markdown contracts,
git worktrees, and an append-only event log. If an agent can read files, write
files, and run commands in a directory, it can participate.

## Why

A single AI agent asked to "keep working" on a large task drifts: it defines
its own "done", reviews its own work, forgets decisions after a context reset,
and expands scope. This protocol splits the work into roles with separated
powers:

| Role | Does | Must not |
| --- | --- | --- |
| **Human Owner** | Sets direction, accepts final behavior and risk | — |
| **Orchestrator** | Clarifies the request, splits narrow tasks, arbitrates review findings, controls scope | Skip verification, close without evidence |
| **Executor** | Implements one task in an isolated git worktree | Define "done", merge, expand scope |
| **Reviewer** | Finds real bugs with evidence and severity | Decide what gets fixed, command the executor |
| **Verifier** | Runs tests/build/smoke; only observed results count | Mark unexecuted checks as PASS |
| **Scribe** | Keeps state, decisions, and handoff notes durable | Change decisions |

Reviewers can doubt but not rule. Executors can fix but not close.
The orchestrator decides but must verify. The human owner accepts the result.

Every round has the same shape:
**goal → constraints → diff → tests → review → arbitration → close.**

## How It Survives Interruptions

All coordination lives in files under [`.ai-collab/`](.ai-collab/), committed
to git at every phase transition. Chat context is treated as disposable:

- `STATE.md` holds the current phase and the next expected action.
- `events.ndjson` is an append-only machine-readable event stream.
- Every new session starts with a recovery procedure: read state, replay
  recent events, reconcile against `git status` / `git worktree list` —
  when files and repository disagree, the repository wins.

A session can die at any moment and the next one resumes with at most one
step lost.

## Quick Start

1. Copy `.ai-collab/`, the entry files (`CLAUDE.md`, `AGENTS.md`,
   `GEMINI.md`), `.gitattributes`, and `scripts/` into your repository
   (or use this repo as a template).
2. Open your preferred agentic CLI at the repo root and state your request.
   The entry file routes the agent into the protocol: intake → confirmed job
   → narrow tasks → isolated worktrees → verify → review → arbitrate → close.
3. Assign agents to roles with one sentence ("use codex as executor, ollama
   as reviewer") or a preset name — `solo`, `standard`, or `offline`. Say
   nothing and you get `solo`. See
   [`AGENT_REGISTRY.md`](.ai-collab/AGENT_REGISTRY.md).

## Bridging Different Agents

| Tier | What | How it joins |
| --- | --- | --- |
| 1 | Agentic CLIs (Claude Code, Codex, Gemini CLI, Cursor, aider/opencode/goose + Ollama) | Started in the right worktree with a one-line bootstrap prompt; the entry file does the rest. Headless dispatch: `claude -p` / `codex exec` / `gemini -p`. |
| 2 | Text-only models (raw Ollama, chat UIs) | An adapter script gathers inputs, calls the model once, writes the contract file. Example: `scripts/ollama-review.sh TASK-001 qwen2.5-coder`. Fits REVIEWER/SCRIBE. |
| 3 | Deterministic tools (terminal, CI, pytest) | Serve as VERIFIER; command output is the whole contract. |

Which agents exist on a machine is detected at job intake
(`command -v claude codex gemini ollama`), never hardcoded in the repo.

## Layout

```
CLAUDE.md / AGENTS.md / GEMINI.md   entry files (route any agent in)
.ai-collab/
  README.md          full workflow reference
  INTAKE.md          raw request -> confirmed job
  ROLES.md           role powers and limits
  *_PROMPT.md        dispatchable role contracts
  AGENT_REGISTRY.md  agent types, tiers, presets
  ASSIGNMENT.md      per-job role assignment + availability
  RUNBOOK.md         environment-specific tool bindings (the only tool-aware file)
  WORKTREES.md       worktree/branch policy and commands
  STATE.md BOARD.md DECISIONS.md events.ndjson   live state
  templates/         job/task/report/review/verify/handoff templates
scripts/             tier-2 adapters (e.g. ollama-review.sh)
```

Start with [`.ai-collab/README.md`](.ai-collab/README.md) for the complete
workflow.
