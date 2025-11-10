# 0-to-1 Plugin

Complete fullstack development plugin for building products from 0 to 1 with production-tested patterns, expert guidance, and intelligent tooling.

## What's Included

### Skills (4)
- **backend-dev-guidelines** - Python/FastAPI Clean Architecture with domain entities, use cases, and repositories
- **frontend-dev-guidelines** - React/TypeScript/MUI v7 patterns (GUARDRAIL - blocks MUI v6 patterns)
- **consult-experts** - Access specialized expert agents for business strategy, tech leadership, and UI/UX design
- **skill-developer** - Meta-skill for creating and managing Claude Code skills

### Agents (6)
- **business-strategist** - Business strategy and product guidance for building products from 0 to 1
- **frontend-error-fixer** - Debug and fix frontend errors (build and runtime)
- **plan-reviewer** - Review development plans before implementation
- **refactor-planner** - Create comprehensive refactoring strategies
- **uiux-specialist** - UI/UX design and specialist guidance for product interfaces
- **web-research-specialist** - Research technical issues and solutions online

### Hooks (3)
- **skill-activation-prompt** - Auto-suggests relevant skills based on your work
- **post-tool-use-tracker** - Tracks file changes for context management
- **error-handling-reminder** - Reminds about error handling best practices

### Commands (2)
- **/dev-docs** - Create structured development documentation with task breakdown
- **/dev-docs-update** - Update docs before context reset

## Tech Stack Support

### Backend
- Python/FastAPI with Clean Architecture

### Frontend
- React 18+
- TypeScript
- MUI v7 (Material-UI)
- TanStack Query/Router

## Installation

```bash
# From your project directory
/plugin install 0-to-1@claude-workspace-plugins
```

## Post-Installation Setup

### 1. Customize Skill Triggers (Optional)

The default file patterns work for most projects:
- Backend: `src/application/**/*.py`, `src/domain/**/*.py`, `src/infrastructure/**/*.py`
- Frontend: `src/**/*.tsx`

**Only customize if your project structure differs.** Edit `.claude/skills/skill-rules.json`:

```json
{
  "skills": {
    "backend-dev-guidelines": {
      "fileTriggers": {
        "pathPatterns": [
          "backend/**/*.py",       // Custom backend folder
          "services/*/src/**/*.py" // Monorepo
        ]
      }
    },
    "frontend-dev-guidelines": {
      "fileTriggers": {
        "pathPatterns": [
          "apps/web/src/**/*.tsx"  // Monorepo frontend
        ]
      }
    }
  }
}
```

### 2. Install Hook Dependencies

```bash
cd ~/.claude/plugins/marketplaces/claude-workspace-plugins/plugins/0-to-1/hooks && npm install
```

### 3. Test Skill Activation

Try using explicit trigger phrases:
- "Following backend guidelines, how do I create a FastAPI endpoint?"
- "Using react best practices, create a new dashboard component"
- "Consult product expert for help with my roadmap"

Or edit matching files and the skills will auto-activate.

## How Skills Activate

Skills activate automatically in two ways:

### 1. File-Based Activation
When you edit files matching these patterns (from `.claude/skills/skill-rules.json`):

**backend-dev-guidelines:**
- `src/application/**/*.py`
- `src/domain/**/*.py`
- `src/infrastructure/**/*.py`

**frontend-dev-guidelines:**
- `src/**/*.tsx`

### 2. Keyword-Based Activation
When your prompts contain these keywords:

**backend-dev-guidelines:**
- `backend guidelines`, `backend best practices`
- `domain-driven design`
- `use case`, `repository pattern`, `infrastructure layer`
- `FastAPI`, `Pydantic`, `SQLAlchemy`

**frontend-dev-guidelines:**
- `frontend guidelines`, `react best practices`
- `mui patterns`, `ui component`
- `MUI v7`, `Grid size prop`

**skill-developer:**
- `skill development`, `skill-rules.json`
- `create new skill`, `skill triggers`, `configure skill`

**consult-experts:**
- `consult product`, `consult tech`, `consult uiux`
- `expert advice`, `product strategy`, `tech leadership`

**💡 Best Practice:** Use explicit trigger phrases for reliable activation:
- "Following backend guidelines, create a user endpoint"
- "Using react best practices, create a dashboard component"

## Usage Examples

### Backend Development

**Example prompts:**
```bash
"Following backend guidelines, create a new user registration endpoint"
"Using repository pattern, implement orders repository"
"Following backend best practices, add validation to my Pydantic model"
```

### Frontend Development

**⚠️ Important:** frontend-dev-guidelines is a GUARDRAIL and will BLOCK MUI v6 patterns!

**Example prompts:**
```bash
"Following frontend guidelines, create a new dashboard component"
"Using react best practices, add a data grid with sorting"
"Following mui patterns, style this button"
```

### Expert Guidance

The **consult-experts** skill provides access to specialized agents:

**Business Strategy:**
```bash
"I need help planning my product roadmap"
"What features should I prioritize?"
```

**UI/UX Design:**
```bash
"Review my dashboard layout"
"Help me design the user onboarding flow"
```

### Using Agents Directly

Invoke agents for complex tasks:

```bash
# Business strategy
"Use the business-strategist agent to help me plan my MVP features"

# Fix frontend errors
"Use the frontend-error-fixer agent to debug this console error"

# Review plans
"Use the plan-reviewer agent to review my authentication implementation plan"

# Plan refactoring
"Use the refactor-planner agent to plan breaking down this large service"

# UI/UX guidance
"Use the uiux-specialist agent to review my checkout flow"

# Research solutions
"Use the web-research-specialist agent to find best practices for file uploads"
```

### Slash Commands

```bash
# Create development documentation
/dev-docs Implement user authentication with JWT

# Update documentation before context reset
/dev-docs-update
```

## Advanced Customization

### Adding Custom Keywords

You can add project-specific keywords to `.claude/skills/skill-rules.json`:

```json
{
  "skills": {
    "backend-dev-guidelines": {
      "promptTriggers": {
        "keywords": [
          "backend guidelines",
          "FastAPI",
          "use case",
          // Add your custom keywords
          "my-custom-service",
          "project-specific-term"
        ]
      }
    }
  }
}
```

### Common File Pattern Examples

**Monorepo:**
```json
{
  "backend-dev-guidelines": {
    "fileTriggers": {
      "pathPatterns": [
        "services/*/src/**/*.py",
        "packages/backend/**/*.ts"
      ]
    }
  },
  "frontend-dev-guidelines": {
    "fileTriggers": {
      "pathPatterns": [
        "apps/web/src/**/*.tsx",
        "packages/ui/src/**/*.tsx"
      ]
    }
  }
}
```

**Multiple backend services:**
```json
{
  "backend-dev-guidelines": {
    "fileTriggers": {
      "pathPatterns": [
        "auth-service/src/**/*.py",
        "api-service/src/**/*.py",
        "worker-service/src/**/*.py"
      ]
    }
  }
}
```

## Skill Details

### Backend Dev Guidelines

**Focus:** Python/FastAPI Clean Architecture

**Key Topics:**
- Domain layer (entities, value objects)
- Application layer (use cases)
- API layer (FastAPI endpoints)
- Repository pattern
- Validation with Pydantic/Dataclasses
- Error handling and observability
- Testing patterns

**Resources:** 12 detailed guides on Clean Architecture patterns

### Frontend Dev Guidelines

**Focus:** React/TypeScript/MUI v7

**Key Topics:**
- Component patterns
- MUI v7 usage (blocks v6 patterns)
- Routing and navigation
- Data fetching with TanStack Query
- State management
- Performance optimization
- TypeScript standards

**Resources:** 10 detailed guides on React/MUI best practices

### Consult Experts

**Provides access to:**
- Product Manager - Product strategy and roadmap planning
- Tech Lead - Technical architecture and system design
- Code Reviewer - Code quality and best practices review
- Documentation Architect - Comprehensive documentation creation
- System Design - Scalable system architecture

**Resources:** 5 expert agent profiles with specialized knowledge

### Skill Developer

**Meta-skill for creating skills**

**Topics:**
- Skill creation and structure
- Trigger patterns (keywords, intents, file paths)
- Enforcement levels (block, suggest, warn)
- Hook mechanisms
- Testing and troubleshooting

**Resources:** 7 comprehensive guides on skill development

## Important: GUARDRAIL Behavior

If **frontend-dev-guidelines is a GUARDRAIL** - it will **BLOCK** edits that use MUI v6 patterns!

This prevents accidental use of deprecated patterns:
- ❌ `<Grid xs={6}>` (MUI v6)
- ✅ `<Grid size={{ xs: 6 }}>` (MUI v7)

**To bypass for a specific file:**
```typescript
// @skip-validation
import { Grid } from '@mui/material';
// This file has been manually verified
```

**Environment variable (affects all files):**
```bash
export SKIP_FRONTEND_GUIDELINES=1
```

## Troubleshooting

### Skills not activating?

**Check:**
1. Path patterns in `skill-rules.json` match your project structure
2. You're editing files that match the patterns
3. You're using trigger keywords in your prompts

**Test manually:**
```bash
echo '{"session_id":"test","prompt":"your test prompt"}' | \
  npx tsx .claude/hooks/skill-activation-prompt.ts
```

### Guardrail blocking edits?

**Solutions:**
1. Review the block message - it explains the issue
2. Fix the MUI v6 pattern to use MUI v7
3. Add `// @skip-validation` if intentional
4. Set `SKIP_FRONTEND_GUIDELINES=1` to disable globally

### Hooks failing?

**Check:**
1. Hook dependencies installed: `cd .claude/hooks && npm install`
2. Hooks are executable: `ls -la .claude/hooks/*.sh`
3. Node.js and npx available in PATH

### Agents not working?

**Verify:**
1. Using correct agent names (see list above)
2. Asking Claude to "Use the [agent-name] agent"
3. Agent files exist in `.claude/agents/`

## What Makes This Plugin Special

### 🎯 0-to-1 Focus
Built specifically for building products from scratch with comprehensive guidance for both business and technical aspects.

### 🧠 Expert Guidance
Access to business strategist and UI/UX specialist agents for product-level decisions, not just technical implementation.

### 🏗️ Clean Architecture
Backend patterns follow Clean Architecture principles with clear separation of domain, application, and infrastructure layers.

### 🎨 Modern Frontend
React/TypeScript/MUI v7 patterns with guardrails to prevent deprecated usage.

### 🔍 Intelligent Activation
Skills auto-activate based on keywords, file patterns, and work context - no manual triggering needed.

### 📚 Comprehensive Resources
- Backend: 12 detailed resource files
- Frontend: 10 detailed resource files
- Experts: 5 specialized agent profiles
- Skill Development: 7 comprehensive guides

### 🛡️ Quality Guardrails
GUARDRAIL enforcement prevents common mistakes (e.g., MUI v6 usage) before they happen.

## Perfect For

- ✅ Building products from 0 to 1
- ✅ Fullstack development (backend + frontend)
- ✅ Python/FastAPI backends with Clean Architecture
- ✅ Node.js/Express backends (TypeScript)
- ✅ React/TypeScript frontends with MUI v7
- ✅ Startups and early-stage products
- ✅ Getting expert guidance on product strategy
- ✅ Learning Clean Architecture patterns
- ✅ Modern frontend development

## Not Designed For

- ❌ Mobile app development
- ❌ DevOps/infrastructure focus
- ❌ Legacy codebases
- ❌ Non-TypeScript projects (frontend)
- ❌ MUI v6 or older versions

## Resources & Documentation

### Skills
Each skill includes comprehensive documentation and resources:
- Backend: Clean Architecture, domain modeling, repositories, validation, testing
- Frontend: Component patterns, MUI v7, routing, data fetching, performance
- Experts: Business strategy, tech leadership, UI/UX design
- Skill Developer: Creating and managing skills

### Agents
Each agent is specialized for specific tasks:
- Business strategist: Product roadmap, feature prioritization, market analysis
- Frontend error fixer: Build errors, runtime errors, debugging
- Plan reviewer: Architecture review, implementation planning, risk assessment
- Refactor planner: Code organization, pattern improvements, migration strategies
- UI/UX specialist: Interface design, user experience, accessibility
- Web research: Best practices, solutions, community knowledge

## License

MIT

---

**Build better products faster from 0 to 1!** 🚀
