# Claude Workspace Plugins - Development Guide

Guide for moving skills, agents, commands, and hooks between plugins.

## Quick Reference

### Files to Update (7 files minimum)

1. Physical files (move)
2. Source `plugin.json` (remove entry)
3. Source `README.md` (remove docs)
4. Target `plugin.json` (add entry)
5. Target `README.md` (add docs)
6. `.claude-plugin/marketplace.json` (update both plugins)
7. Root `README.md` (update summaries)

### Component Types

| Type | File Extension | Location Pattern | Frontmatter Fields |
|------|---------------|------------------|--------------------|
| Skill | Directory with `SKILL.md` | `plugins/{plugin}/skills/{skill-name}/` | `name`, `description` |
| Agent | `.md` | `plugins/{plugin}/agents/{agent-name}.md` | `name`, `description`, `color` |
| Command | `.md` | `plugins/{plugin}/commands/{command-name}.md` | `description`, `argument-hint` |
| Hook | `.ts` or `.json` | `plugins/{plugin}/hooks/{hook-name}.ts` | N/A (TypeScript/JSON) |

## Moving Components

**Skills are directories** (contain `SKILL.md` + optional `resources/`), others are files.

```bash
# Move component
mv plugins/source/{type}/{component} plugins/target/{type}/{component}

# Update 7 files (see checklist above)
```

---

## Update Checklist

### Source Plugin
- [ ] `plugin.json` - Remove from `components.{type}` array
- [ ] `README.md` - Remove from "What's Included", descriptions, examples, update counts

### Target Plugin
- [ ] `plugin.json` - Add to `components.{type}` array (alphabetical order)
- [ ] `README.md` - Add to "What's Included", descriptions, examples, update counts

### Marketplace & Root
- [ ] `.claude-plugin/marketplace.json` - Update both plugin descriptions and keywords
- [ ] `README.md` - Update all plugin sections

---

## plugin.json Entry Format

**Skills:**
```json
{
  "name": "skill-name",
  "path": "${CLAUDE_PLUGIN_ROOT}/skills/skill-name",
  "description": "Skill description"
}
```

**Agents/Commands:**
```json
{
  "name": "component-name",
  "path": "${CLAUDE_PLUGIN_ROOT}/{type}/{component-name}.md",
  "description": "Description"
}
```

---


## Troubleshooting

**Skill not activating:**
- `plugin.json` must reference directory, not `SKILL.md` file
  - ❌ `"${CLAUDE_PLUGIN_ROOT}/skills/skill-name/SKILL.md"`
  - ✅ `"${CLAUDE_PLUGIN_ROOT}/skills/skill-name"`
- Check `SKILL.md` frontmatter has `name` and `description`

**JSON validation:**
```bash
jq empty .claude-plugin/marketplace.json && echo "✓ Valid"
```

---

## Best Practices

- Move one component at a time
- Validate JSON after changes: `jq empty {file}.json`
- Keep descriptions consistent across all files
- Commit physical moves separately from config updates

## Frontmatter Templates

### Command
```markdown
---
description: Brief description
argument-hint: Example arguments
---
```

### Agent
```markdown
---
name: agent-name
description: Agent description
color: blue|green|red|purple|orange|white
---
```

### Skill (SKILL.md)
```markdown
---
name: skill-name
description: Comprehensive description with trigger conditions
---
```

**Note:** Skills are directories with `SKILL.md` + optional `resources/` folder.

---

## Useful Commands

```bash
# Find all components
find plugins -name "*.md" -path "*/agents/*"
find plugins -name "*.md" -path "*/commands/*"
find plugins -type d -path "*/skills/*" -depth 2

# Validate JSON
for f in plugins/*/plugin.json; do jq empty "$f" && echo "✓ $f"; done

# Search references
grep -r "component-name" plugins/ .claude-plugin/ README.md
```
