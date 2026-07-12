# BOARD

Use this board for task-level coordination. Every active task should have a task contract in `tasks/`.

## Flow

Backlog -> Ready -> In Progress -> Verify -> Review -> Arbitration -> Ready To Close -> Done

## Backlog

| Task | Owner | Role | Contract | Status | Notes |
| --- | --- | --- | --- | --- | --- |

## Ready

| Task | Owner | Role | Contract | Branch | Worktree |
| --- | --- | --- | --- | --- | --- |

## In Progress

| Task | Owner | Branch | Worktree | Started | Status |
| --- | --- | --- | --- | --- | --- |

## Blocked

| Task | Owner | Blocker | Needed Decision | Since | Status |
| --- | --- | --- | --- | --- | --- |

## Verify

| Task | Verifier | Verification File | Required Checks | Status |
| --- | --- | --- | --- | --- |

## Review

| Task | Reviewer | Review File | Finding Count | Status |
| --- | --- | --- | --- | --- |

## Arbitration

| Task | Decision File | Accepted Findings | Rejected Findings | Status |
| --- | --- | --- | --- | --- |

## Ready To Close

| Job | Verification | Review | Decisions | Handoff |
| --- | --- | --- | --- | --- |

## Done

| Task | Owner | Report | Review | Verification | Handoff |
| --- | --- | --- | --- | --- | --- |
