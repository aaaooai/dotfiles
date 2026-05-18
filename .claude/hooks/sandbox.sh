#!/bin/bash
# File access restrictions

RESTRICTED_PATHS=(
    "$HOME/.ssh"
    "$HOME/.aws"
    "$HOME/.kube"
    "$HOME/.docker"
    "$HOME/.gnupg"
    "$HOME/.git-credentials"
    "/etc/shadow"
    "/etc/sudoers"
    "/root/.ssh"
)

check_restricted_access() {
    local cmd="$1"

    for restricted in "${RESTRICTED_PATHS[@]}"; do
        # Check for cat, less, more, head, tail, cp, mv, rm on restricted paths
        if echo "$cmd" | grep -qE "(cat|less|more|head|tail|cp|mv|rm|chmod|chown|nano|vim).*$restricted"; then
            echo "🔒 SANDBOX: Access denied to $restricted"
            return 1
        fi
    done

    return 0
}

# Enforce sandbox for bash commands
if [[ -n "$BASH_COMMAND" ]]; then
    check_restricted_access "$BASH_COMMAND" || exit 1
fi
