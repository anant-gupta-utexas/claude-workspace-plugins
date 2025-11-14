#!/bin/bash

# Stop hook that reminds developers about error handling best practices
# Skip if environment variable is set

# Skip if environment variable is set
if [ -n "$SKIP_ERROR_REMINDER" ]; then
    exit 0
fi

# Navigate to the hooks directory where TypeScript handler and dependencies live
cd "${CLAUDE_PLUGIN_ROOT}/hooks"

# Execute the TypeScript handler with stdin piped
cat | npx tsx error-handling-reminder.ts
