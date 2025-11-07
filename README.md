# Claude Workspace Plugins

Personal collection of Claude Code plugins, skills, and agents for enhanced development workflows.

## Quick Start

### Adding This Marketplace

```bash
/plugin marketplace add <your-github-username>/claude-workspace-plugins
```

### Installing Plugins

```bash
# Browse available plugins
/plugin

# Install a specific plugin
/plugin install plugin-name@<your-github-username>
```

## Repository Structure

```
claude-workspace-plugins/
├── .claude-plugin/
│   └── marketplace.json      # Marketplace configuration
├── plugins/                   # Individual plugin directories
│   ├── _template/            # Template for creating new plugins
│   └── your-plugin-name/     # Your custom plugins
├── docs/                      # Documentation
└── README.md
```

## Creating a New Plugin

1. **Copy the template**
   ```bash
   cp -r plugins/_template plugins/my-plugin
   ```

2. **Update plugin.json**
   Edit `plugins/my-plugin/.claude-plugin/plugin.json`:
   ```json
   {
     "name": "my-plugin",
     "description": "What your plugin does",
     "version": "1.0.0",
     "author": "Your Name",
     "tags": ["category"],
     "dependencies": []
   }
   ```

3. **Add your content**
   - **Agents**: Add `.md` files to `plugins/my-plugin/agents/`
   - **Commands**: Add `.md` files to `plugins/my-plugin/commands/`
   - **Skills**: Create `plugins/my-plugin/skills/skill-name/SKILL.md`

4. **Register in marketplace**
   Add to `.claude-plugin/marketplace.json`:
   ```json
   {
     "plugins": [
       {
         "name": "my-plugin",
         "path": "plugins/my-plugin",
         "description": "What your plugin does",
         "version": "1.0.0",
         "tags": ["category"]
       }
     ]
   }
   ```

5. **Test locally**
   ```bash
   /plugin marketplace add file:///absolute/path/to/claude-workspace-plugins
   /plugin install my-plugin
   ```

## Plugin Components

### Agents
Specialized AI personalities for specific tasks. Create agents as markdown files that define expertise and behavior patterns.

**Example**: `agents/python-expert.md`

### Commands
Slash commands that expand to reusable prompts. Simple markdown files become executable commands.

**Example**: `commands/run-tests.md` → `/run-tests`

### Skills
Auto-activating knowledge modules with progressive disclosure. Include YAML frontmatter and trigger configuration.

**Example**: `skills/error-handling/SKILL.md`

## Publishing Your Marketplace

1. **Push to GitHub**
   ```bash
   git add .
   git commit -m "Initial plugin marketplace"
   git remote add origin git@github.com:<username>/claude-workspace-plugins.git
   git push -u origin main
   ```

2. **Share with others**
   Others can add your marketplace:
   ```bash
   /plugin marketplace add <username>/claude-workspace-plugins
   ```

## Best Practices

- **Version Control**: Use semantic versioning (1.0.0, 1.1.0, 2.0.0)
- **Documentation**: Include clear README.md in each plugin
- **Testing**: Test plugins locally before publishing
- **Organization**: Group related functionality in single plugins
- **Naming**: Use descriptive, hyphenated names (my-python-tools)
- **Skills**: Follow Anthropic's 500-line rule for SKILL.md files

## Resources

- [Claude Code Documentation](https://code.claude.com/docs)
- [Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Skills Best Practices](https://code.claude.com/docs/en/skills)

## License

Specify your license here (MIT, Apache 2.0, etc.)

## Contributing

Guidelines for contributing to your plugin collection.
