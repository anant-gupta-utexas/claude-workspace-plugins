# Frontend Development Plugin

Complete frontend development setup with production-tested patterns for React/TypeScript/MUI v7 development.

## What's Included

### Skills (2)
- **frontend-dev-guidelines** - React/TypeScript/MUI v7 patterns (GUARDRAIL - blocks MUI v6 patterns)
- **skill-developer** - Meta-skill for creating/managing skills

### Agents (7)
- **frontend-error-fixer** - Debug and fix frontend errors (build and runtime)
- **code-refactor-master** - Plan and execute comprehensive refactoring
- **code-architecture-reviewer** - Review code for architectural consistency
- **refactor-planner** - Create comprehensive refactoring strategies
- **plan-reviewer** - Review development plans
- **web-research-specialist** - Research technical issues
- **documentation-architect** - Generate comprehensive documentation

### Hooks (2)
- **skill-activation-prompt** - Auto-suggests relevant skills
- **post-tool-use-tracker** - Tracks file changes

### Commands (2)
- **/dev-docs** - Create structured development documentation
- **/dev-docs-update** - Update docs before context reset

## Tech Stack Requirements

- React 18+
- TypeScript
- MUI v7
- TanStack Query
- TanStack Router (or similar)

## Installation

```bash
# From your project directory
/plugin install frontend-plugin@claude-workspace-plugins
```

## Post-Installation Setup

### 1. Customize Skill Triggers

Edit `.claude/skills/skill-rules.json` to match your project structure:

```json
{
  "skills": {
    "frontend-dev-guidelines": {
      "fileTriggers": {
        "pathPatterns": [
          "src/**/*.tsx"            // Single app
          // OR
          "apps/web/src/**/*.tsx"   // Monorepo
          // OR
          "frontend/src/**/*.tsx",  // Specific apps
          "admin-panel/src/**/*.tsx"
        ]
      }
    }
  }
}
```

**Why?** The skill-activation-prompt hook uses these patterns to automatically activate skills when you edit matching files.

**⚠️ Important:** frontend-dev-guidelines is a GUARDRAIL and will BLOCK edits with MUI v6 patterns!

### 2. Install Hook Dependencies

```bash
cd .claude/hooks && npm install
```

### 3. Test Skill Activation

Ask Claude: "Create a new React component"

**Expected:** frontend-dev-guidelines skill should automatically activate

## ⚠️ Important: GUARDRAIL Skill

**frontend-dev-guidelines is a GUARDRAIL** - it will **BLOCK** edits that use MUI v6 patterns!

This prevents accidental use of deprecated patterns like:
- ❌ `<Grid xs={6}>` (MUI v6)
- ✅ `<Grid size={{ xs: 6 }}>` (MUI v7)

To bypass for a specific file:
```typescript
// @skip-validation
import { Grid } from '@mui/material';
```

## Usage Examples

### Skill Activation
Skills automatically activate when you:
- Mention frontend topics: "component", "React", "MUI", "styling"
- Edit frontend files: `src/**/*.tsx`, `frontend/**/*.tsx`
- Work with React or MUI code

### Using Agents
```bash
# Fix frontend errors
"Use the frontend-error-fixer agent to debug this console error"

# Plan component refactoring
"Use the refactor-planner agent to break down this large Dashboard component"

# Review component architecture
"Use the code-architecture-reviewer agent to review my new UserProfile component"
```

### Slash Commands
```bash
/dev-docs Implement new user dashboard
/dev-docs-update
```

## Advanced Customization

### Adding Custom Keywords

Edit `.claude/skills/skill-rules.json` to add project-specific keywords:

```json
{
  "skills": {
    "frontend-dev-guidelines": {
      "promptTriggers": {
        "keywords": [
          "component",
          "React",
          "MUI",
          // Add your custom keywords
          "dashboard",
          "custom-component-name"
        ]
      }
    }
  }
}
```

### Adjusting File Pattern Examples

**Single React app**:
```json
"pathPatterns": [
  "src/**/*.tsx",
  "src/**/*.ts"
]
```

**Monorepo**:
```json
"pathPatterns": [
  "apps/web/src/**/*.tsx",
  "packages/ui/src/**/*.tsx"
]
```

**Multiple frontend apps**:
```json
"pathPatterns": [
  "frontend/src/**/*.tsx",
  "admin-panel/src/**/*.tsx",
  "client/src/**/*.tsx"
]
```

### Disabling the Guardrail

If you need to disable the MUI v7 guardrail:

**Per file** (recommended):
```typescript
// @skip-validation
// Rest of your code
```

**Environment variable** (affects all files):
```bash
export SKIP_FRONTEND_GUIDELINES=1
```

## Troubleshooting

**Skills not activating?**
- Check path patterns in skill-rules.json match your project structure
- Verify you're editing .tsx files that match the patterns

**Guardrail blocking edits?**
- Review the block message - it explains the issue
- Fix the MUI v6 pattern or add `// @skip-validation` if intentional

**Hooks failing?**
- Run: `cd .claude/hooks && npm install`
- Check hooks are executable: `ls -la .claude/hooks/*.sh`

## License

MIT
