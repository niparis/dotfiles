#!/bin/sh
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')
total_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -n "$used" ] && [ -n "$total_tokens" ]; then
  tokens_k=$(echo "$total_tokens" | awk '{printf "%.1fk", $1/1000}')
  printf '%s | %s | %.0f%% used' "$model" "$tokens_k" "$used"
else
  printf '%s' "$model"
fi
