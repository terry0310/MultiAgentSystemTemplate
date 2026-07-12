# Custom Skills

This directory holds user-provided skills: reusable, named instruction
packages that any agent in this repo can discover and apply, regardless of
which tool (Claude Code, Codex CLI, Gemini CLI, ...) the agent runs on.

## What A Skill Is

A skill is a folder containing a `SKILL.md` plus optional support files
(scripts, reference docs, templates):

```text
.ai-collab/skills/
  <skill-name>/
    SKILL.md          # required: frontmatter + instructions
    <support files>   # optional: anything SKILL.md references
```

`SKILL.md` follows the Agent Skills format, so a skill stays portable to
tool-native skill folders:

```markdown
---
name: <skill-name>
description: >-
  One or two sentences: what the skill does and WHEN to use it. Agents decide
  from this line alone whether to open the file, so state the trigger
  explicitly ("Use when ...").
metadata:
  roles: [EXECUTOR]
---

# <Skill title>

Step-by-step instructions written for an agent with file and terminal access.
Reference support files by path relative to this folder.
```

- `name` is kebab-case and must match the folder name.
- `metadata.roles` is optional: which roles may apply the skill. Omit it to
  allow all roles. It lives under `metadata` because top-level custom keys are
  rejected by some harnesses' skill frontmatter linting.

## Discovery

Discovery is a directory scan — there is no separate index file that can go
stale:

1. List `.ai-collab/skills/*/SKILL.md`.
2. Read only the frontmatter (`name`, `description`, `metadata.roles`) of
   each.
3. Open the full `SKILL.md` only for skills whose description matches the
   current work.

When this happens:

- ORCHESTRATOR scans during planning and lists every applicable skill in the
  task contract under `Relevant Skills` (see `templates/TASK_TEMPLATE.md`).
  It may likewise name skills in review or verification requests.
- EXECUTOR / REVIEWER / VERIFIER read every skill listed in their dispatch
  contract before starting, and follow it while doing the matching step.
- Skills listed in a contract are mandatory. An agent may additionally apply
  a skill it discovered on its own if the description matches its current
  step and `metadata.roles` allows it; note any such use in the report.

## Invocation

"Invoking" a skill is tool-agnostic: read its `SKILL.md` and follow the
instructions exactly, the same way as any other contract file in this
protocol. If the current harness also supports native skill triggering,
`RUNBOOK.md` defines how to bridge (for example, mirroring a skill into
`.claude/skills/` for Claude Code).

## Rules

- A skill must not contradict a role's prompt contract or a task's
  Allowed/Forbidden Files. The contract always wins; report the conflict
  instead of following the skill.
- Skills are instructions, not authority: a skill never grants scope, files,
  or permissions the dispatch contract did not grant.
- One skill = one capability. Split multi-purpose skills into separate
  folders.
- Keep `SKILL.md` self-sufficient and under roughly 200 lines; push detail
  into support files it references.
