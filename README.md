# Claude Workspace Plugins Marketplace

Production-tested Claude Code plugins for modern development workflows with specialized tools for backend, frontend, documentation, and essential utilities.

## 🎯 Available Plugins

### Core Plugins (Recommended for All Projects)

#### [essentials](./plugins/essentials/)
Essential utilities with specialized agents, expert consultation, skill development tools, and intelligent hooks.

**Includes:**
- 2 Skills (consult-experts, skill-developer)
- 4 Agents (business-strategist, plan-reviewer, refactor-planner, web-research-specialist)
- 3 Hooks (skill activation, file tracking, error handling reminders)

**Perfect for:** Planning, research, refactoring, expert consultation

#### [documentation](./plugins/documentation/)
Comprehensive documentation tools for technical writing and architecture documentation.

**Includes:**
- 1 Agent (documentation-architect)
- 2 Commands (/dev-docs, /dev-docs-update)

**Perfect for:** Creating technical documentation, API docs, architecture documentation

---

### Specialized Plugins (Install Based on Your Stack)

#### [021BE](./plugins/021BE/) - Backend Development
Python/FastAPI Clean Architecture backend development guidelines.

**Includes:**
- 1 Skill (backend-dev-guidelines)

**Tech Stack:**
- Python 3.9+
- FastAPI
- Pydantic
- Clean Architecture

**Perfect for:** Python/FastAPI backend projects

#### [021FE](./plugins/021FE/) - Frontend Development
React/TypeScript/MUI v7 frontend development guidelines with GUARDRAIL enforcement.

**Includes:**
- 1 Skill (frontend-dev-guidelines)
- 2 Agents (frontend-error-fixer, uiux-specialist)

**Tech Stack:**
- React 18+
- TypeScript
- MUI v7
- TanStack Query/Router

**Perfect for:** React/TypeScript frontend projects with MUI v7

---

## 🚀 Quick Start

### 1. Add This Marketplace

```bash
/plugin marketplace add anant-gupta-utexas/claude-workspace-plugins
```

### 2. Browse Available Plugins

```bash
/plugin
```

This opens an interactive UI showing all available plugins from this marketplace.

### 3. Install Plugins

**Recommended installation order:**

```bash
# Core plugins (install these first)
/plugin install essentials@claude-workspace-plugins
/plugin install documentation@claude-workspace-plugins

# Backend plugin (if you have a Python/FastAPI backend)
/plugin install 021BE@claude-workspace-plugins

# Frontend plugin (if you have a React/TypeScript frontend)
/plugin install 021FE@claude-workspace-plugins
```

### 4. Post-Installation Setup

**For essentials plugin (required):**
```bash
cd ~/.claude/plugins/marketplaces/claude-workspace-plugins/plugins/essentials/hooks && npm install
```

Test skill activation:
```bash
"Use the business-strategist agent to help with my product roadmap"
"Consult expert for architecture decisions"
```

---

## 📦 Plugin Details

### essentials Plugin (Core)

**Why install:** Provides fundamental utilities that enhance all development workflows regardless of tech stack.

**Skills:**
- **consult-experts** - Access specialized expert agents (Product Manager, Tech Lead, Code Reviewer)
- **skill-developer** - Meta-skill for creating and managing Claude Code skills

**Agents:**
- **business-strategist** - Business strategy and product guidance
- **plan-reviewer** - Review development plans before implementation
- **refactor-planner** - Create comprehensive refactoring strategies
- **web-research-specialist** - Research technical issues and solutions

**Hooks:**
- **skill-activation-prompt** - Auto-suggests relevant skills based on your work
- **post-tool-use-tracker** - Tracks file changes for context management
- **error-handling-reminder** - Reminds about error handling best practices

[View Details →](./plugins/essentials/README.md)

---

### documentation Plugin (Core)

**Why install:** Essential for creating and maintaining high-quality technical documentation.

**Agent:**
- **documentation-architect** - Expert agent for comprehensive documentation (APIs, architecture, system design)

**Commands:**
- **/dev-docs** - Create structured development documentation with task breakdown
- **/dev-docs-update** - Update docs before context reset

[View Details →](./plugins/documentation/README.md)

---

### 021BE Plugin (Backend Specialization)

**When to install:** You're working on Python/FastAPI backend projects following Clean Architecture.

**Skill:**
- **backend-dev-guidelines** - Python/FastAPI Clean Architecture with domain entities, use cases, repository patterns

**Key Topics:**
- Domain layer (entities, value objects)
- Application layer (use cases, DTOs)
- Repository pattern and data access
- FastAPI endpoint structure
- Validation, error handling, testing

**Resources:** 12 comprehensive guides on Clean Architecture patterns

[View Details →](./plugins/021BE/README.md)

---

### 021FE Plugin (Frontend Specialization)

**When to install:** You're working on React/TypeScript projects with MUI v7.

**Skill:**
- **frontend-dev-guidelines** - React/TypeScript/MUI v7 patterns with GUARDRAIL enforcement (blocks MUI v6)

**Agents:**
- **frontend-error-fixer** - Debug and fix frontend errors (build and runtime)
- **uiux-specialist** - UI/UX design and specialist guidance

**Key Topics:**
- Component patterns (Suspense, lazy loading)
- MUI v7 usage with guardrails
- TanStack Query/Router
- Performance optimization
- TypeScript standards

**Resources:** 10 comprehensive guides on React/MUI best practices

[View Details →](./plugins/021FE/README.md)

---

## 🎨 What's a Plugin?

A Claude Code plugin is a package of:

- **Skills** - Domain knowledge and best practices that auto-activate
- **Agents** - Specialized AI assistants for complex tasks
- **Hooks** - Auto-activation and automation for enhanced workflows
- **Commands** - Slash commands for common workflows

Together, they create an intelligent development environment tailored to your needs.

---

## 📖 How to Use Installed Plugins

### Skills Auto-Activate

After installation, skills automatically activate when:
- You use specific keywords in your prompts
- You edit files matching configured patterns
- You mention relevant technologies

**Best Practice:** Use explicit trigger phrases:
- "Following backend guidelines, create an endpoint"
- "Using react best practices, create a component"
- "Consult expert for architecture decisions"

### Using Agents

Invoke agents for complex tasks:

```bash
# Essential agents
"Use the business-strategist agent to help me plan my product strategy"
"Use the plan-reviewer agent to review my authentication implementation plan"
"Use the web-research-specialist agent to find best practices for WebSockets"

# Documentation agent
"Use the documentation-architect agent to document my REST API"

# Frontend agents (if 021FE installed)
"Use the frontend-error-fixer agent to debug this console error"
"Use the uiux-specialist agent to review my dashboard design"
```

### Slash Commands

Use commands for workflows:

```bash
/dev-docs Implement user authentication
/dev-docs-update
```

---

## ⚙️ Customization

### Adjusting Path Patterns

The essentials plugin includes `skill-rules.json` that configures when skills activate. This file references all skills (backend and frontend) for comprehensive activation logic.

**Important Note:** If you only install specialized plugins for your project type (e.g., only frontend), the skill activation hook will still check for keywords related to uninstalled skills. This doesn't cause errors - it simply won't find matches for those skills.

Edit `.claude/skills/skill-rules.json` to customize activation patterns:

**Monorepo Example:**
```json
{
  "skills": {
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
}
```

**Frontend-Only Project:**
```json
{
  "skills": {
    "frontend-dev-guidelines": {
      "fileTriggers": {
        "pathPatterns": [
          "src/**/*.tsx",
          "components/**/*.tsx"
        ]
      },
      "promptTriggers": {
        "keywords": [
          "react",
          "frontend guidelines",
          "mui patterns"
        ]
      }
    }
  }
}
```

---

## 🔧 Managing Plugins

### List Installed Plugins

```bash
/plugin list
```

### Update Plugins

```bash
/plugin update essentials
/plugin update documentation
/plugin update 021BE
/plugin update 021FE
```

### Remove Plugins

```bash
/plugin uninstall 021BE
/plugin uninstall 021FE
```

### List All Marketplaces

```bash
/plugin marketplace list
```

---

## 💡 Recommended Plugin Combinations

### For Fullstack Projects (Backend + Frontend)

```bash
/plugin install essentials@claude-workspace-plugins
/plugin install documentation@claude-workspace-plugins
/plugin install 021BE@claude-workspace-plugins
/plugin install 021FE@claude-workspace-plugins
```

**You get:** Complete development workflow with backend/frontend patterns, planning agents, documentation tools, and hooks.

### For Backend-Only Projects

```bash
/plugin install essentials@claude-workspace-plugins
/plugin install documentation@claude-workspace-plugins
/plugin install 021BE@claude-workspace-plugins
```

**You get:** Backend development patterns, planning agents, documentation tools, and essential utilities.

### For Frontend-Only Projects

```bash
/plugin install essentials@claude-workspace-plugins
/plugin install documentation@claude-workspace-plugins
/plugin install 021FE@claude-workspace-plugins
```

**You get:** Frontend development patterns with guardrails, UI/UX specialist, error fixing, planning agents, and documentation tools.

### For Product Planning & Documentation

```bash
/plugin install essentials@claude-workspace-plugins
/plugin install documentation@claude-workspace-plugins
```

**You get:** Business strategy, planning, documentation creation, and essential utilities without tech-specific development patterns.

---

## 🎓 Learn More

### Official Claude Code Docs
- [Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Creating Skills](https://code.claude.com/docs/en/skills)

### Plugin READMEs
- [essentials Plugin →](./plugins/essentials/README.md)
- [documentation Plugin →](./plugins/documentation/README.md)
- [021BE Plugin →](./plugins/021BE/README.md)
- [021FE Plugin →](./plugins/021FE/README.md)

---

## 🤝 Contributing

Want to contribute to these plugins?

1. Fork this repository
2. Create a feature branch
3. Submit a pull request

### Creating Your Own Plugins

You can create custom plugins following the same structure:

```
my-plugin/
├── plugin.json          # Plugin manifest
├── README.md           # Documentation
├── skills/             # Skill files
├── agents/             # Agent files
├── hooks/              # Hook files
└── commands/           # Command files
```

Then add to `.claude-plugin/marketplace.json`.

---

## 📄 License

MIT License - Use freely in your projects.

---

## 🆘 Support

**Issues or questions?**
- Check the relevant plugin README
- Review troubleshooting sections
- Open an issue on GitHub

---

## 🌟 What You Get

After installing these plugins, you get:

- ✅ **Intelligent skill activation** - Skills suggest themselves when relevant
- ✅ **Specialized agents** - AI assistants for business strategy, planning, UI/UX, research, and error fixing
- ✅ **Expert guidance** - Access to business strategist, tech lead, and UI/UX specialist agents
- ✅ **Automated workflows** - Hooks that track and optimize your work
- ✅ **Production patterns** - Best practices from real-world projects (Python/FastAPI, React/MUI)
- ✅ **Tech stack validation** - Prevents common mistakes with guardrails (MUI v7)
- ✅ **Comprehensive documentation** - Everything you need to know
- ✅ **Modular installation** - Install only what you need for your project

**Build better products faster!** 🚀
