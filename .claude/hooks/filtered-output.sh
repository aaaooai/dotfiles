#!/bin/bash
# Output filtering - mask sensitive data

SECRETS_FILE="$HOME/.claude/.env.secrets"

filter_output() {
    local output="$1"

    while IFS='|' read -r name pattern; do
        [[ "$pattern" == "" ]] && continue
        # Replace matched secrets with [REDACTED]
        output=$(echo "$output" | sed -E "s/$pattern/[REDACTED]/g")
    done < "$SECRETS_FILE"

    # Additional masking patterns
    output=$(echo "$output" | sed -E \
        -e 's/(password|passwd|pwd)[[:space:]]*[:=][[:space:]]*[^\s]+/\1=[REDACTED]/gi' \
        -e 's/(token|auth)[[:space:]]*[:=][[:space:]]*[^\s]+/\1=[REDACTED]/gi' \
        -e 's/(key|secret)[[:space:]]*[:=][[:space:]]*[^\s]+/\1=[REDACTED]/gi' \
        -e 's/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/[EMAIL_REDACTED]/g' \
        -e 's/\b([0-9]{1,3}\.){3}[0-9]{1,3}\b/[IP_REDACTED]/g' \
    )

    echo "$output"
}

# Filter output if CLAUDE_TOOL_OUTPUT is set
if [[ -n "$CLAUDE_TOOL_OUTPUT" ]]; then
    filter_output "$CLAUDE_TOOL_OUTPUT"
fi
