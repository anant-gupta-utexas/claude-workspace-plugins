# Documentation Plugin

Comprehensive documentation tools including an expert documentation architect agent and development documentation commands for creating structured technical documentation.

## What's Included

### Agents (1)
- **documentation-architect** - Expert agent for creating comprehensive documentation for architecture, APIs, and system design

### Commands (2)
- **/dev-docs** - Create structured development documentation with task breakdown
- **/dev-docs-update** - Update docs before context reset

## Installation

```bash
# From your project directory
/plugin install documentation@claude-workspace-plugins
```

## Usage Examples

### Using the Documentation Architect Agent

The documentation-architect agent specializes in creating comprehensive, professional documentation:

```bash
# API documentation
"Use the documentation-architect agent to document my REST API endpoints"

# Architecture documentation
"Use the documentation-architect agent to create architecture docs for my microservices"

# System design documentation
"Use the documentation-architect agent to document the authentication system"

# Database schema documentation
"Use the documentation-architect agent to document our database schema"
```

### Using Slash Commands

**Create development documentation:**
```bash
/dev-docs Implement user authentication with JWT
/dev-docs Add real-time notifications with WebSocket
/dev-docs Refactor payment processing module
```

**Update documentation before context reset:**
```bash
/dev-docs-update
/dev-docs-update Focus on recent API changes
```

## Component Details

### Documentation Architect Agent

**Specializes in:**
- API documentation (REST, GraphQL)
- Architecture documentation
- System design documentation
- Database schema documentation
- Technical specifications
- Integration guides
- Deployment documentation

**Features:**
- Structured, professional documentation format
- Comprehensive coverage of technical details
- Best practices for documentation structure
- Clear examples and code snippets
- Diagrams and visual representations (when applicable)

**When to use:**
- Creating new documentation from scratch
- Documenting complex systems or architectures
- Writing API reference documentation
- Creating technical specifications
- Need expert-level documentation quality

### Dev Docs Command

**Purpose:** Create structured development documentation with task breakdown

**Use cases:**
- Planning new feature implementation
- Documenting implementation approach
- Breaking down complex tasks
- Creating implementation roadmaps
- Recording development decisions

**Example output:**
- Task breakdown
- Implementation steps
- Technical considerations
- Dependencies and prerequisites
- Testing strategy

### Dev Docs Update Command

**Purpose:** Update existing documentation before context reset

**Use cases:**
- Capturing recent changes before context limit
- Updating implementation status
- Recording blockers or issues
- Documenting new insights or decisions

**Features:**
- Preserves important context
- Updates progress tracking
- Records decisions and changes
- Maintains documentation continuity

## Perfect For

- ✅ Creating comprehensive technical documentation
- ✅ API documentation
- ✅ Architecture and system design docs
- ✅ Development planning and tracking
- ✅ Technical specifications
- ✅ Integration guides
- ✅ Teams needing professional documentation

## Not Designed For

- ❌ User-facing documentation (user guides, tutorials)
- ❌ Marketing content
- ❌ Project management documentation
- ❌ Non-technical documentation

## Best Practices

### When to use the Documentation Architect Agent

Use the agent when you need:
- High-quality, comprehensive documentation
- Professional documentation structure
- Complex technical documentation
- Multiple documentation sections (overview, API, examples, etc.)

### When to use Dev Docs Commands

Use the commands when you need:
- Quick development documentation
- Task breakdown and planning
- Progress tracking
- Context preservation before reset

### Combining Tools

For best results:
1. Use `/dev-docs` to plan and track implementation
2. Use the `documentation-architect` agent to create final, comprehensive documentation
3. Use `/dev-docs-update` to maintain context during long implementations

## Tips for Effective Documentation

**For the Documentation Architect Agent:**
- Be specific about what you want documented
- Provide context about your system/API
- Mention any specific sections you need
- Include examples of existing patterns if available

**For Dev Docs Commands:**
- Provide clear, specific task descriptions
- Include relevant context about the feature/change
- Mention any constraints or requirements
- Update docs regularly to maintain context

## License

MIT

---

**Document better, communicate clearer!** 📚
