# UI decisions

Append-only ledger for the [UI policy](UI-POLICY.md). Record here: UI grants, every UI ruling and UI arbitration, pending UI questions, checkpoint rulings, deferrals, human overrides, and the results of human-only checks. General governance stays in `DECISIONS.md` and points back to these IDs.

- Take the next unique `UD-####` in the control worktree.
- Record who actually decided: `HUMAN_OWNER` or `ORCHESTRATOR`.
- To answer, reverse or supersede a row, append a new row that names the earlier ID. Never edit an earlier row.
- Status is `pending`, `accepted`, `deferred` or `rejected`. A pending question is owned by the orchestrator until the human owner answers it.

| UD-ID | Date | Task / defect | Platform | Grant / A1-A4 / B | Decider | Ruling or open question | Basis / evidence | Rollback / supersedes | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
