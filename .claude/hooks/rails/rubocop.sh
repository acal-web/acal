#!/usr/bin/env bash
# PostToolUse hook (Write|Edit): keeps Rails files rubocop-clean.
# Reads the tool-call JSON from stdin, checks, then autocorrects on failure.

file=$(jq -r '.tool_input.file_path // empty')
project_dir="${CLAUDE_PROJECT_DIR:-/workspace}"

case "$file" in
  "$project_dir"/api/*.rb) ;;
  *) exit 0 ;;
esac

cd "$project_dir/api" || exit 0

if ! out=$(bundle exec rubocop "$file" 2>&1); then
  if ! out=$(bundle exec rubocop -A "$file" 2>&1); then
    echo "RuboCop failed even after -A on $file:" >&2
    echo "$out" >&2
    exit 2
  fi
fi
