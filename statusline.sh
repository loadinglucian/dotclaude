#!/usr/bin/env bash

# Read JSON input from stdin
input=$(cat)

# Extract values from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name // .model.id // empty')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')

# Get current usage (actual session context usage)
current_usage=$(echo "$input" | jq '.context_window.current_usage')

# Calculate session context usage from current_usage
if [[ "$current_usage" != "null" ]]; then
	input_tokens=$(echo "$current_usage" | jq -r '.input_tokens // 0')
	cache_creation=$(echo "$current_usage" | jq -r '.cache_creation_input_tokens // 0')
	cache_read=$(echo "$current_usage" | jq -r '.cache_read_input_tokens // 0')
	session_context=$((input_tokens + cache_creation + cache_read))
else
	session_context=0
fi

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

# Context window progress bar (using actual session context)
if [[ $context_size -gt 0 && $session_context -gt 0 ]]; then
	# Calculate percentage
	percentage=$((session_context * 100 / context_size))

	# Progress bar settings
	bar_width=15
	filled=$((session_context * bar_width / context_size))
	[[ $filled -gt $bar_width ]] && filled=$bar_width

	# Build bar
	bar=""
	for ((i=0; i<filled; i++)); do
		bar+="━"
	done
	for ((i=filled; i<bar_width; i++)); do
		bar+="╺"
	done

	# Format numbers with K suffix for readability
	if [[ $session_context -ge 1000 ]]; then
		used_display="$((session_context / 1000))K"
	else
		used_display="$session_context"
	fi

	if [[ $context_size -ge 1000 ]]; then
		size_display="$((context_size / 1000))K"
	else
		size_display="$context_size"
	fi

	printf ' │ %s %d%% (%s/%s)' "$bar" "$percentage" "$used_display" "$size_display"
fi

printf '\n'
