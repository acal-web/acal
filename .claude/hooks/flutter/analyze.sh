#!/usr/bin/env bash
# PostToolUse hook (Write|Edit): keeps Flutter files analyze-clean.
# Reads the tool-call JSON from stdin and fails loudly on analyzer issues.

file=$(jq -r '.tool_input.file_path // empty')
project_dir="${CLAUDE_PROJECT_DIR:-/workspace}"

case "$file" in
  "$project_dir"/app/*.dart) ;;
  *) exit 0 ;;
esac

out=$(flutter analyze "$file" 2>&1)
if ! echo "$out" | grep -q "No issues found"; then
  echo "$out" >&2
  exit 2
fi
