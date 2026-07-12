# MODELS

This file is the model configuration for this repository. The human owner edits it; the orchestrator reads it.

## Thinking Effort Values

| Value | Meaning |
| --- | --- |
| `NONE` | No extended thinking / reasoning disabled or minimal. |
| `LOW` | Brief reasoning; fast, cheap. |
| `MEDIUM` | Moderate reasoning; sensible default. |
| `HIGH` | Deep reasoning; slow and expensive, for hard problems only. |

## Defaults

Adjust these to match the tools and subscriptions available in the target project.

| Agent family | Default model | Default thinking effort |
| --- | --- | --- |
| Claude Code | `sonnet` | `MEDIUM` |
| Codex CLI | `gpt-5.3-codex` | `MEDIUM` |
| Gemini CLI | `gemini-2.5-pro` | `MEDIUM` |
| Ollama (local) | `qwen2.5-coder` | `NONE` |

## Effort Levels

### `LIGHT`

Mechanical, low-risk work: renames, docs, config tweaks, formatting, and scribe duties.

| Agent family | Models (preference order) | Thinking effort |
| --- | --- | --- |
| Claude Code | `haiku`, `sonnet` | `MEDIUM` |
| Codex CLI | `gpt-5.1-codex-mini`, `gpt-5.3-codex` | `LOW` |
| Gemini CLI | `gemini-2.5-flash` | `NONE` |
| Ollama (local) | `qwen2.5-coder` | `NONE` |

### `STANDARD`

Normal feature work and reviews: multi-file changes with tests, typical bug fixes, routine code review.

| Agent family | Models (preference order) | Thinking effort |
| --- | --- | --- |
| Claude Code | `sonnet` | `HIGH` |
| Codex CLI | `gpt-5.3-codex` | `HIGH` |
| Gemini CLI | `gemini-2.5-pro` | `MEDIUM` |
| Ollama (local) | `qwen2.5-coder` | `NONE` |

### `HEAVY`

Hard problems: architecture decisions, cross-cutting refactors, unclear debugging, security-sensitive code, or arbitration of conflicting findings.

| Agent family | Models (preference order) | Thinking effort |
| --- | --- | --- |
| Claude Code | `opus`, `sonnet` | `HIGH` |
| Codex CLI | `gpt-5.3-codex` | `HIGH` |
| Gemini CLI | `gemini-2.5-pro` | `HIGH` |
| Ollama (local) | `qwen2.5-coder` | `NONE` |

## Selection Rules

1. Resolve the agent type per role first from `AGENT_REGISTRY.md` and `ASSIGNMENT.md`.
2. Pick an effort level per role or per executor task.
3. Use `LIGHT` only for reversible, low-risk work.
4. Use at least `STANDARD` for user-visible behavior, tests, multiple files, or environment traps.
5. Use `HEAVY` for hard debugging, security-sensitive work, architecture, or repeated failed attempts.
6. If the chosen model is unavailable, fall down the preference order within the same agent family and record the substitution.
7. Explicit human owner model instructions override this file and must be recorded in `DECISIONS.md`.

## Recording Rules

- Role-level choice: `Model / Effort` column in `ASSIGNMENT.md`.
- Task-level choice: `Model / Effort` field in the task file.
- Escalations, substitutions, and human overrides: `DECISIONS.md`.
- Exact dispatch command: task file or executor report.

## Rules

- This file never assigns roles and never records availability.
- Keep model names in sync with what the target tool actually accepts.
- Do not hardcode model names in other protocol files; reference this file.
