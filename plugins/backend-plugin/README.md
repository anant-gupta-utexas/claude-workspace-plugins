# Backend Development Plugin

Complete backend development setup with production-tested patterns, skills, and agents for Node.js/Express/TypeScript development.

## What's Included

### Skills (2)
- **backend-dev-guidelines** - Node.js/Express/TypeScript patterns with Prisma
- **skill-developer** - Meta-skill for creating/managing skills

### Agents (5)
- **code-architecture-reviewer** - Review code for architectural consistency
- **refactor-planner** - Create comprehensive refactoring strategies
- **documentation-architect** - Generate comprehensive documentation
- **plan-reviewer** - Review development plans before implementation
- **web-research-specialist** - Research technical issues online

### Hooks (3)
- **skill-activation-prompt** - Auto-suggests relevant skills
- **post-tool-use-tracker** - Tracks file changes
- **error-handling-reminder** - Reminds about error handling best practices

### Commands (2)
- **/dev-docs** - Create structured development documentation
- **/dev-docs-update** - Update docs before context reset

## Tech Stack Requirements

- Node.js/Express
- TypeScript
- Prisma ORM

## Installation

```bash
# From your project directory
/plugin install backend-plugin@claude-workspace-plugins
```

## Post-Installation Setup

### 1. Customize Skill Triggers

Edit `.claude/skills/skill-rules.json` to match your project structure:

```json
{
  "skills": {
    "backend-dev-guidelines": {
      "fileTriggers": {
        "pathPatterns": [
          "src/**/*.ts"           // Single app
          // OR
          "services/*/src/**/*.ts" // Monorepo
          // OR
          "blog-api/src/**/*.ts",  // Specific services
          "auth-service/src/**/*.ts"
        ]
      }
    }
  }
}
```

**Why?** The skill-activation-prompt hook uses these patterns to automatically activate skills when you edit matching files.

### 2. Install Hook Dependencies

```bash
cd .claude/hooks && npm install
```

### 3. Test Skill Activation

Ask Claude: "How do I create a controller?"

**Expected:** backend-dev-guidelines skill should automatically activate

## Usage Examples

### Skill Activation
Skills automatically activate when you:
- Mention backend topics: "controller", "service", "route", "API"
- Edit backend files: `src/**/*.ts`, `backend/**/*.ts`
- Work with Prisma or Express code

### Using Agents
```bash
# Review your code architecture
"Use the code-architecture-reviewer agent to review my authentication service"

# Plan a refactoring
"Use the refactor-planner agent to plan refactoring my user service"

# Generate documentation
"Use the documentation-architect agent to document my API endpoints"
```

### Slash Commands
```bash
/dev-docs Refactor authentication system
/dev-docs-update
```

## Advanced Customization

### Adding Custom Keywords

Edit `.claude/skills/skill-rules.json` to add project-specific keywords:

```json
{
  "skills": {
    "backend-dev-guidelines": {
      "promptTriggers": {
        "keywords": [
          "backend",
          "controller",
          "service",
          // Add your custom keywords
          "my-custom-service",
          "project-specific-term"
        ]
      }
    }
  }
}
```

### Adjusting File Pattern Examples

**Single app**:
```json
"pathPatterns": ["src/**/*.ts"]
```

**Monorepo**:
```json
"pathPatterns": [
  "services/*/src/**/*.ts",
  "packages/*/src/**/*.ts"
]
```

**Specific services**:
```json
"pathPatterns": [
  "blog-api/src/**/*.ts",
  "auth-service/src/**/*.ts",
  "notifications-service/src/**/*.ts"
]
```

## Troubleshooting

**Skills not activating?**
- Check path patterns in skill-rules.json match your project structure
- Verify you're editing files that match the patterns

**Hooks failing?**
- Run: `cd .claude/hooks && npm install`
- Check hooks are executable: `ls -la .claude/hooks/*.sh`

## License

MIT
