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

### Hooks (2)
- **skill-activation-prompt** - Auto-suggests relevant skills
- **post-tool-use-tracker** - Tracks file changes

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

1. **Update skill-rules.json** with your project paths:
   ```bash
   # Edit .claude/skills/skill-rules.json
   # Update pathPatterns to match your backend code location
   # Example: "src/**/*.ts", "backend/**/*.ts", "services/*/src/**/*.ts"
   ```

2. **Install hook dependencies**:
   ```bash
   cd .claude/hooks && npm install
   ```

3. **Test skill activation**:
   Ask Claude: "How do I create a controller?"
   
   Expected: backend-dev-guidelines skill should automatically activate

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

## Customization

### Adjust Path Patterns

Edit `.claude/skills/skill-rules.json`:

**Single app**:
```json
{
  "backend-dev-guidelines": {
    "fileTriggers": {
      "pathPatterns": ["src/**/*.ts"]
    }
  }
}
```

**Monorepo**:
```json
{
  "backend-dev-guidelines": {
    "fileTriggers": {
      "pathPatterns": ["services/*/src/**/*.ts", "packages/*/src/**/*.ts"]
    }
  }
}
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
