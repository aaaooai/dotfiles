#!/bin/bash
# Secret detection & dangerous command restriction

SECRETS_FILE="$HOME/.claude/.env.secrets"
BLACKLIST_FILE="$HOME/.claude/blacklist.txt"

detect_secrets() {
    local input="$1"
    local found=0

    while IFS='|' read -r name pattern; do
        [[ "$pattern" == "" ]] && continue
        if echo "$input" | grep -qiE "$pattern"; then
            echo "⚠️  SECURITY: Detected potential secret: $name"
            found=1
        fi
    done < "$SECRETS_FILE"

    return $found
}

check_dangerous_command() {
    local cmd="$1"

    while IFS= read -r dangerous; do
        [[ "$dangerous" == "" ]] && continue
        if [[ "$cmd" =~ ^[[:space:]]*$dangerous ]]; then
            echo "🔒 BLOCKED: Dangerous command detected: $dangerous"
            echo "   Command: $cmd"
            read -p "   Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                return 1
            fi
        fi
    done < "$BLACKLIST_FILE"

    return 0
}

# Detect secrets in user input
if [[ -n "$CLAUDE_USER_INPUT" ]]; then
    detect_secrets "$CLAUDE_USER_INPUT"
fi

# Check bash commands before execution
if [[ -n "$BASH_COMMAND" && "$BASH_COMMAND" != "check_dangerous_command"* ]]; then
    check_dangerous_command "$BASH_COMMAND" || exit 1
fi
