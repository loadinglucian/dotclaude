#!/usr/bin/env bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name // .model.id // empty')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')

# Get usage percentage directly from API (new method)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

# Directory display (basename only)
display_dir=$(basename "$cwd")
printf '\033[1;36m%s\033[0m' "$display_dir"

# Git information (Starship style)
if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  [[ -z "$branch" ]] && branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

  if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
    status_indicator='*'
  else
    status_indicator=''
  fi

  [[ -n "$branch" ]] && printf ' on \033[0;35m%s%s\033[0m' "$branch" "$status_indicator"
fi

# Model indicator
if [[ -n "$model" && "$model" != "null" ]]; then
  printf ' │ %s' "$model"
fi

# Context window progress bar (using API percentage)
if [[ $context_size -gt 0 ]]; then
  # Round percentage to integer
  percentage=$(printf "%.0f" "$used_pct")

  # Only show if there's usage
  if [[ $percentage -gt 0 ]]; then
    # Calculate used tokens from percentage
    used_tokens=$((context_size * percentage / 100))

    # Progress bar settings
    bar_width=15
    filled=$((percentage * bar_width / 100))
    [[ $filled -gt $bar_width ]] && filled=$bar_width

    # Build bar
    bar=""
    for ((i = 0; i < filled; i++)); do
      bar+="━"
    done
    for ((i = filled; i < bar_width; i++)); do
      bar+="╺"
    done

    # Format numbers with K suffix for readability
    if [[ $used_tokens -ge 1000 ]]; then
      used_display="$((used_tokens / 1000))K"
    else
      used_display="$used_tokens"
    fi

    if [[ $context_size -ge 1000 ]]; then
      size_display="$((context_size / 1000))K"
    else
      size_display="$context_size"
    fi

    printf ' │ %s %d%% (%s/%s)' "$bar" "$percentage" "$used_display" "$size_display"
  fi
fi

printf '\n'
