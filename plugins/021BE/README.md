# 021BE - Backend Development Plugin

Python/FastAPI Clean Architecture backend development guidelines with comprehensive patterns for building scalable, maintainable backend applications.

## What's Included

### Skills (1)
- **backend-dev-guidelines** - Python/FastAPI Clean Architecture with domain entities, use cases, repositories, and infrastructure patterns

## Tech Stack Support

### Backend
- Python 3.9+
- FastAPI framework
- Pydantic validation
- SQLAlchemy (optional)
- Clean Architecture principles

## Installation

```bash
# From your project directory
/plugin install 021BE@claude-workspace-plugins
```

## How the Skill Activates

The backend-dev-guidelines skill activates automatically in two ways:

### 1. File-Based Activation
When you edit files matching these patterns:
- `src/application/**/*.py`
- `src/domain/**/*.py`
- `src/infrastructure/**/*.py`

### 2. Keyword-Based Activation
When your prompts contain these keywords:
- `backend guidelines`, `backend best practices`
- `domain-driven design`
- `use case`, `repository pattern`, `infrastructure layer`
- `FastAPI`, `Pydantic`, `SQLAlchemy`

### Customizing File Patterns

If your project structure differs, edit `.claude/skills/skill-rules.json`:

```json
{
  "skills": {
    "backend-dev-guidelines": {
      "fileTriggers": {
        "pathPatterns": [
          "backend/**/*.py",
          "services/*/src/**/*.py"
        ]
      }
    }
  }
}
```

## Usage Examples

**Example prompts:**
```bash
"Following backend guidelines, create a new user registration endpoint"
"Using repository pattern, implement orders repository"
"Following backend best practices, add validation to my Pydantic model"
"How do I structure domain entities for an e-commerce system?"
```

## Skill Details

### Backend Dev Guidelines

**Focus:** Python/FastAPI Clean Architecture

**Key Topics:**
- Domain layer (entities, value objects)
- Application layer (use cases, DTOs)
- API layer (FastAPI endpoints, dependencies)
- Repository pattern and data access
- Validation with Pydantic/Dataclasses
- Error handling and observability
- Middleware patterns
- Testing strategies (unit, integration, e2e)
- Complete implementation examples

**Resources:** 12 comprehensive guides covering:
1. Clean Architecture overview
2. Domain layer patterns
3. Application layer patterns
4. API layer implementation
5. Repository pattern
6. Infrastructure layer
7. Middleware guide
8. Error handling
9. Validation patterns
10. Testing guide
11. Observability
12. Complete examples

## Perfect For

- ✅ Python/FastAPI backend development
- ✅ Clean Architecture projects
- ✅ Domain-driven design
- ✅ Scalable API development
- ✅ Learning Clean Architecture patterns
- ✅ Building maintainable backend systems

## Not Designed For

- ❌ Non-Python backends
- ❌ Monolithic architecture without layers
- ❌ Frontend development
- ❌ DevOps/infrastructure

## Resources & Documentation

The backend-dev-guidelines skill includes 12 detailed resource files covering:
- Domain modeling and entity design
- Use case implementation patterns
- Repository pattern and data access
- FastAPI endpoint structure
- Validation strategies
- Error handling and observability
- Comprehensive testing approaches
- Real-world implementation examples

## License

MIT

---

**Build clean, maintainable backends!** 🚀
