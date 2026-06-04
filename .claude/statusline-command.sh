#!/bin/sh
input=$(cat)

# Genshijin mode
genshijin=""
settings_file="$HOME/.claude/settings.json"
if [ -f "$settings_file" ]; then
    genshijin_enabled=$(jq -r '.enabledPlugins["genshijin@genshijin"] // false' "$settings_file" 2>/dev/null)
    if [ "$genshijin_enabled" = "true" ]; then
        genshijin="ｳﾎｯ"
    fi
fi

# Model
model=$(echo "$input" | jq -r '.model.display_name // empty')

# Context window usage
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')

# Git branch and dirty state
cwd=$(echo "$input" | jq -r '.cwd // empty')
branch=""
dirty=""
if [ -n "$cwd" ]; then
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null || dirty="*"
        git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null || dirty="*"
    fi
fi

# Build output
parts=""

# Genshijin
if [ -n "$genshijin" ]; then
    parts="${genshijin}"
fi

# Model
if [ -n "$model" ]; then
    if [ -n "$parts" ]; then
        parts="${parts} | ${model}"
    else
        parts="${model}"
    fi
fi

# Git
if [ -n "$branch" ]; then
    git_info="${branch}${dirty}"
    parts="${parts} | ${git_info}"
fi

# Token usage
if [ -n "$used" ]; then
    token_info="ctx:$(printf '%.0f' "$used")%"
    if [ -n "$total_in" ] && [ -n "$total_out" ]; then
        token_info="${token_info} (in:${total_in} out:${total_out})"
    fi
    parts="${parts} | ${token_info}"
fi

printf '%s' "$parts"
