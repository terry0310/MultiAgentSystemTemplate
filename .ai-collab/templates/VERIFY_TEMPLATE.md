# TASK-XXX Verification

## Task

TASK-XXX

## Role

VERIFIER

## Agent / Tool

[Terminal / CI / Agent name]

## Branch

[branch name]

## Worktree

[path]

## Verification Status

PASS / FAIL / PARTIAL / BLOCKED / NOT RUN

## Commands Run

### Command 1

```bash
[command]
```

Result: PASS / FAIL / NOT RUN

Relevant output:

```text
[paste relevant output]
```

### Command 2

```bash
[command]
```

Result: PASS / FAIL / NOT RUN

Relevant output:

```text
[paste relevant output]
```

## Build Result

PASS / FAIL / NOT RUN

## Lint Result

PASS / FAIL / NOT RUN

## Typecheck Result

PASS / FAIL / NOT RUN

## Unit Test Result

PASS / FAIL / NOT RUN

## Integration Test Result

PASS / FAIL / NOT RUN

## Smoke Test Result

PASS / FAIL / NOT RUN

## Real Data Test

PASS / FAIL / NOT RUN

## UI checks (when applicable)

Tier: T1 / T2 (see `UI-POLICY.md` "UI repair loop").

| Defect / criterion | Build commit, platform and input | Precondition, action and next observable result | Evidence type / shared artifact | Required? | Result |
| --- | --- | --- | --- | --- | --- |

Record PASS, FAIL, BLOCKED or NOT RUN with a reason. Required checks that cannot execute block verification. Report simulated and real-device coverage separately.

For T2, also report the interaction-matrix sweep: cells run, cells failed (with defect IDs), cells not applicable.

Human-only checks (for example IME, touch, screen reader) are not judged by agents. List the outstanding ones here for the orchestrator to hand to the human owner.

## Unverified Items

- [Item 1]
- [Item 2]

## Failure Logs

If logs are long, store them in:

```text
.ai-collab/logs/TASK-XXX-[name].log
```

Relevant excerpt:

```text
[paste relevant failure excerpt]
```

## Verification Summary

[Short conclusion.]
