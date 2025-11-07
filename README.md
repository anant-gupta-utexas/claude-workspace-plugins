# Claude Workspace Plugins Marketplace

Production-tested Claude Code plugins for professional development workflows.

## 🎯 Available Plugins

### [Backend Plugin](./plugins/backend-plugin/)
Complete backend development setup with Node.js/Express/TypeScript patterns.

**Includes:**
- 2 Skills (backend-dev-guidelines, skill-developer)
- 5 Agents (architecture review, refactoring, documentation, etc.)
- 3 Hooks (skill activation, file tracking, error handling reminders)
- 2 Commands (/dev-docs, /dev-docs-update)

**Tech Stack:** Node.js, Express, TypeScript, Prisma

---

### [Frontend Plugin](./plugins/frontend-plugin/)
Complete frontend development setup with React/TypeScript/MUI v7 patterns.

**Includes:**
- 2 Skills (frontend-dev-guidelines with GUARDRAIL, skill-developer)
- 7 Agents (error fixing, refactoring, architecture review, etc.)
- 2 Hooks (skill activation, file tracking)
- 2 Commands (/dev-docs, /dev-docs-update)

**Tech Stack:** React 18+, TypeScript, MUI v7, TanStack Query/Router

---

## 🚀 Quick Start

### 1. Add This Marketplace

```bash
/plugin marketplace add yourusername/claude-workspace-plugins
```

### 2. Browse Available Plugins

```bash
/plugin
```

This opens an interactive UI showing all available plugins from this marketplace.

### 3. Install a Plugin

```bash
# For backend development
/plugin install backend-plugin@claude-workspace-plugins

# For frontend development
/plugin install frontend-plugin@claude-workspace-plugins
```

### 4. Configure After Installation

Each plugin requires minimal post-installation setup:

1. Update `skill-rules.json` with your project paths
2. Install hook dependencies: `cd .claude/hooks && npm install`
3. Test skill activation

See individual plugin READMEs for detailed instructions.

---

## 📦 Plugin Details

### Backend Plugin

Perfect for:
- REST API development
- Microservices
- Node.js/Express backends
- TypeScript projects with Prisma

[View Details →](./plugins/backend-plugin/README.md)

### Frontend Plugin

Perfect for:
- React SPAs
- Admin panels
- Web applications with MUI v7
- TypeScript frontends

[View Details →](./plugins/frontend-plugin/README.md)

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

**Example:** Edit a TypeScript controller file → backend-dev-guidelines activates automatically

### Using Agents

Invoke agents for complex tasks:

```bash
"Use the code-architecture-reviewer agent to review my authentication service"
"Use the refactor-planner agent to plan breaking down this large component"
"Use the frontend-error-fixer agent to debug this console error"
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

After installing a plugin, customize path patterns in `.claude/skills/skill-rules.json`:

**Backend Example:**
```json
{
  "backend-dev-guidelines": {
    "fileTriggers": {
      "pathPatterns": [
        "src/**/*.ts",           // Single app
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

### Update a Plugin

```bash
/plugin update backend-plugin
```

### Remove a Plugin

```bash
/plugin uninstall backend-plugin
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

### Plugin READMEs
- [Backend Plugin →](./plugins/backend-plugin/README.md)
- [Frontend Plugin →](./plugins/frontend-plugin/README.md)

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
- Check individual plugin READMEs
- Review [troubleshooting sections](./plugins/backend-plugin/README.md#troubleshooting)
- Open an issue on GitHub

---

## 🌟 What You Get

After installing these plugins, you get:

- ✅ **Intelligent skill activation** - Skills suggest themselves when relevant
- ✅ **Specialized agents** - AI assistants for complex tasks
- ✅ **Automated workflows** - Hooks that track and optimize your work
- ✅ **Production patterns** - Best practices from real-world projects
- ✅ **Tech stack validation** - Prevents common mistakes
- ✅ **Comprehensive documentation** - Everything you need to know

**Start building better software faster!** 🚀
