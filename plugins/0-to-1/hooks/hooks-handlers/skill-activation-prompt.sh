#!/bin/bash
set -e

# UserPromptSubmit hook that suggests relevant skills based on user prompts
# Uses CLAUDE_PLUGIN_ROOT to reference plugin directory

# Navigate to the hooks directory where TypeScript handler and dependencies live
cd "${CLAUDE_PLUGIN_ROOT}/hooks"

# Execute the TypeScript handler with stdin piped
cat | npx tsx skill-activation-prompt.ts
