#!/usr/bin/env bash
# Claude Code PermissionDenied hook: keep the raw auto-mode denial (tool name,
# full tool_input, reason) for the orchestrator. It only records; it never
# asks for a retry. See RUNBOOK.md "Permission Denials (Claude Code)".
dir="${CLAUDE_PROJECT_DIR:-.}/.ai-collab/logs"
mkdir -p "$dir"
{
  printf '{"ts":"%s","hook":"PermissionDenied","raw":' "$(date +%Y-%m-%dT%H:%M:%S%:z)"
  tr -d '\r\n'
  printf '}\n'
} >> "$dir/permission-denied.ndjson"
exit 0
