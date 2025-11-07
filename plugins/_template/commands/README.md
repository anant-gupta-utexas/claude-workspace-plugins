# Commands

Place slash command files (.md) in this directory.

## Command File Structure

Each command file defines a slash command that Claude Code can execute.

Example file: `build.md`
```markdown
Run the build process and report any errors
```

This creates a `/build` command that expands to the prompt text.

## Naming Convention

- File name becomes the command name (without .md extension)
- Use lowercase with hyphens: `run-tests.md` → `/run-tests`
- Keep prompts focused and actionable

## Best Practices

- Be specific and clear in command descriptions
- Include expected outcomes
- Reference project-specific conventions
- Can include structured instructions or checklists
