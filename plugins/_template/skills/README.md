# Skills

Place skill files in subdirectories: `skills/skill-name/SKILL.md`

## Skill Structure

Each skill requires:
1. A subdirectory with the skill name
2. A `SKILL.md` file with YAML frontmatter
3. Optional reference files for detailed documentation

Example: `skills/python-testing/SKILL.md`
```markdown
---
name: python-testing
description: Guidance for writing Python tests using pytest. Covers test structure, fixtures, mocking, and best practices.
---

# Python Testing

## Purpose
Provide comprehensive guidance for writing Python tests.

## When to Use
- Writing new test files
- Debugging failing tests
- Setting up test fixtures

## Key Practices
...
```

## Best Practices (from Anthropic)

✅ Keep SKILL.md under 500 lines
✅ Use progressive disclosure with reference files
✅ Include trigger keywords in description (max 1024 chars)
✅ Use gerund naming (e.g., "processing-data", "handling-errors")
✅ Add table of contents to reference files > 100 lines

## Auto-Activation

Skills can auto-activate based on:
- Keywords in user prompts
- File paths being edited
- Content patterns in files
- Intent patterns

Configure in `.claude/skills/skill-rules.json` if using skills outside plugins.
