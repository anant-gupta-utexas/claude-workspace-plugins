# Claude Workspace Plugins Marketplace

Production-tested Claude Code plugin for building products from 0 to 1 with fullstack development patterns.

## 🎯 Available Plugin

### [0-to-1 Plugin](./plugins/0-to-1/)
Complete fullstack development setup for building products from scratch with backend/frontend patterns and expert guidance.

**Includes:**
- 4 Skills (backend, frontend, consult-experts, skill-developer)
- 6 Agents (business strategy, frontend debugging, planning, refactoring, UI/UX, research)
- 3 Hooks (skill activation, file tracking, error handling reminders)
- 2 Commands (/dev-docs, /dev-docs-update)

**Tech Stack:**
- Backend: Python/FastAPI or Node.js/Express
- Frontend: React 18+, TypeScript, MUI v7
- Database: Prisma ORM (optional)

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

### 3. Install the Plugin

```bash
/plugin install 0-to-1@claude-workspace-plugins
```

### 4. Configure After Installation

The plugin requires minimal post-installation setup:

1. Update `skill-rules.json` with your project paths
2. Install hook dependencies: `cd .claude/hooks && npm install`
3. Test skill activation

See the [plugin README](./plugins/0-to-1/README.md) for detailed instructions.

---

## 📦 Plugin Details

### 0-to-1 Plugin

Perfect for:
- Building products from 0 to 1
- Fullstack development (backend + frontend)
- Python/FastAPI or Node.js/Express backends
- React/TypeScript frontends with MUI v7
- Getting expert guidance on business strategy and UI/UX

**Skills:**
- **backend-dev-guidelines** - Python/FastAPI Clean Architecture patterns
- **frontend-dev-guidelines** - React/TypeScript/MUI v7 patterns (GUARDRAIL)
- **consult-experts** - Access specialized expert agents
- **skill-developer** - Meta-skill for creating skills

**Agents:**
- **business-strategist** - Business strategy and product guidance
- **frontend-error-fixer** - Debug and fix frontend errors
- **plan-reviewer** - Review development plans
- **refactor-planner** - Create refactoring strategies
- **uiux-specialist** - UI/UX design guidance
- **web-research-specialist** - Research technical issues

[View Details →](./plugins/0-to-1/README.md)

---

## 🎨 What's a Plugin?

A Claude Code plugin is a package of:

- **Skills** - Domain knowledge and best practices
- **Agents** - Specialized AI assistants for complex tasks
- **Hooks** - Auto-activation and automation
- **Commands** - Slash commands for workflows

Together, they create an intelligent development environment tailored to your tech stack.

---

## 📖 How to Use Installed Plugins

### Skills Auto-Activate

After installation, skills automatically activate when:
- You mention relevant keywords
- You edit matching files
- You work with specific technologies

**Example:** Edit a Python FastAPI file → backend-dev-guidelines activates automatically

### Using Agents

Invoke agents for complex tasks:

```bash
"Use the business-strategist agent to help me plan my product strategy"
"Use the frontend-error-fixer agent to debug this console error"
"Use the uiux-specialist agent to review my dashboard design"
```

### Access Expert Agents via Skills

The consult-experts skill provides access to specialized expert agents:

```bash
"I need help with product strategy"  # Activates consult-experts skill
```

### Slash Commands

Use commands for workflows:

```bash
/dev-docs Implement user authentication
/dev-docs-update
```

---

## ⚙️ Customization

### Path Patterns

After installing the plugin, customize path patterns in `.claude/skills/skill-rules.json`:

**Backend Example:**
```json
{
  "backend-dev-guidelines": {
    "fileTriggers": {
      "pathPatterns": [
        "src/**/*.py",           // Python backend
        "backend/**/*.ts",       // Node.js backend
        "services/*/src/**/*.ts" // Monorepo
      ]
    }
  }
}
```

**Frontend Example:**
```json
{
  "frontend-dev-guidelines": {
    "fileTriggers": {
      "pathPatterns": [
        "src/**/*.tsx",          // Single app
        "apps/web/src/**/*.tsx"  // Monorepo
      ]
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

### Update the Plugin

```bash
/plugin update 0-to-1
```

### Remove the Plugin

```bash
/plugin uninstall 0-to-1
```

### List All Marketplaces

```bash
/plugin marketplace list
```

---

## 🎓 Learn More

### Official Claude Code Docs
- [Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Creating Skills](https://code.claude.com/docs/en/skills)

### Plugin README
- [0-to-1 Plugin →](./plugins/0-to-1/README.md)

---

## 🤝 Contributing

Want to contribute to this plugin?

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
- Check the [plugin README](./plugins/0-to-1/README.md)
- Review [troubleshooting sections](./plugins/0-to-1/README.md#troubleshooting)
- Open an issue on GitHub

---

## 🌟 What You Get

After installing this plugin, you get:

- ✅ **Intelligent skill activation** - Skills suggest themselves when relevant
- ✅ **Specialized agents** - AI assistants for business strategy, UI/UX, and technical tasks
- ✅ **Expert guidance** - Access to business strategist, tech lead, and UI/UX specialist agents
- ✅ **Automated workflows** - Hooks that track and optimize your work
- ✅ **Production patterns** - Best practices from real-world projects (Python/FastAPI, React/MUI)
- ✅ **Tech stack validation** - Prevents common mistakes with guardrails
- ✅ **Comprehensive documentation** - Everything you need to know

**Build better products faster from 0 to 1!** 🚀
