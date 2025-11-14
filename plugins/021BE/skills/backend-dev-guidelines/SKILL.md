---
name: backend-python-dev-guidelines
description: Comprehensive backend development guide for Python/FastAPI Clean Architecture projects. Use when working with domain entities, use cases, repositories, API routes, or implementing Clean Architecture layers. Covers Domain-Application-Infrastructure separation, dependency injection, async patterns, OpenTelemetry observability, Pydantic validation, and modern Python testing with pytest.
---

# **Backend Python Development Guidelines**

## **Purpose**

Establish consistency and best practices for Python/FastAPI applications following **Clean Architecture** principles.

## **When to Use This Skill**

Automatically activates when working on:

- Creating domain entities, value objects, or domain services
- Implementing use cases and application services
- Building repositories and infrastructure adapters
- Creating or modifying API routes and endpoints
- Implementing middleware (logging, context, error handling)
- Database operations with SQLAlchemy
- Observability with OpenTelemetry
- Input validation with Pydantic (API layer)
- Configuration management with Pydantic Settings
- Backend testing with pytest

---

## **Quick Start**

### **New Feature Checklist**

- [ ]  **Domain Entity**: Pure business logic, no dependencies
- [ ]  **Domain Interface**: Abstract repository/gateway contract
- [ ]  **Use Case**: Orchestrate domain logic
- [ ]  **DTO**: Application boundary data transfer (dataclass)
- [ ]  **Repository**: Implement domain interface
- [ ]  **API Route**: FastAPI endpoint with Pydantic validation
- [ ]  **Tests**: Unit (domain) + Use Case + Integration tests
- [ ]  **Config**: Use Pydantic Settings

### **New Project Checklist**

- [ ]  Directory structure (see `./resources/clean-architecture.md`)
- [ ]  `uv` for dependency management with dependency groups
- [ ]  Pydantic Settings for configuration
- [ ]  OpenTelemetry setup for observability
- [ ]  Base repository pattern with generics
- [ ]  Middleware stack (logging, context, errors)
- [ ]  pytest framework with custom markers

---

## **Architecture Overview**

### **Clean Architecture (3 Layers)**

```
┌─────────────────────────────────────┐
│    Infrastructure Layer             │
│  (API, Database, Messaging, etc.)   │
│           │                         │
│           ▼                         │
│    Application Layer                │
│  (Use Cases, Services, DTOs)        │
│           │                         │
│           ▼                         │
│    Domain Layer                     │
│  (Entities, Value Objects, Rules)   │
└─────────────────────────────────────┘
```

**Dependency Rule:** Dependencies flow INWARD

- Infrastructure → Application → Domain
- Domain has **zero** external dependencies
- Application depends only on Domain
- Infrastructure depends on Application and Domain

See `./resources/clean-architecture.md` for complete details.

---

## **Directory Structure**

```
src/
├── domain/                          # Domain Layer
│   ├── entities/                   # Business entities
│   ├── value_objects/              # Immutable value types
│   ├── services/                   # Domain services
│   ├── interfaces/                 # Ports (abstractions)
│   └── exceptions/                 # Domain exceptions
│
├── application/                     # Application Layer
│   ├── use_cases/                  # Use case implementations
│   ├── services/                   # Application services
│   ├── dtos/                       # Data Transfer Objects (dataclasses)
│   └── exceptions.py               # Application exceptions
│
└── infrastructure/                  # Infrastructure Layer
    ├── api/rest/                   # Inbound adapters
    │   ├── main.py                 # FastAPI app
    │   ├── settings.py             # Pydantic Settings
    │   ├── routes/                # API routes (Pydantic BaseModel)
    │   └── middleware/
    ├── persistence/                # Outbound adapters
    │   ├── repositories/          # Repository implementations
    │   ├── models/                # ORM models
    │   └── session.py             # DB session management
    ├── messaging/                  # Message queue adapters
    ├── observability/              # Cross-cutting concerns
    └── config/                     # Configuration loaders
```

**Naming Conventions:**

- **Domain Entities**: PascalCase - `Conversation`, `Task`
- **Value Objects**: PascalCase - `ConversationStatus`, `TaskStatus`
- **Use Cases**: PascalCase + UseCase - `CreateConversationUseCase`
- **DTOs**: PascalCase + DTO suffix - `ConversationDTO`, `CreateTaskRequest`
- **Repositories**: PascalCase + Repository - `ConversationRepository`

---

## **Core Principles (7 Key Rules)**

### **1. Domain Layer Has Zero Dependencies**

```python
# ✅ GOOD: Pure domain entity
from dataclasses import dataclass
from datetime import datetime
from uuid import UUID

@dataclass
class Conversation:
    id: UUID
    user_id: str
    status: ConversationStatus  # Value object from domain
    def transition_phase(self, new_phase: ConversationPhase) -> None:
        if not self._is_valid_transition(self.phase, new_phase):
            raise ValueError(f"Invalid transition: {self.phase} -> {new_phase}")
        self.phase = new_phase

# ❌ BAD: Domain importing infrastructure
from sqlalchemy import Column, String  # NO!
from fastapi import HTTPException  # NO!
```

### **2. Use Dataclasses for DTOs, Pydantic for API**

```python
# ✅ Application Layer: Dataclass DTOs
from dataclasses import dataclass
from uuid import UUID

@dataclass
class CreateConversationRequest:
    user_id: str
    initial_message: str
    agent_id: Optional[str] = None

# ✅ Infrastructure API Layer: Pydantic for validation
from pydantic import BaseModel, Field

class StartConversationApiRequest(BaseModel):
    initial_message: str = Field(..., min_length=1)
    agent_id: Optional[str] = None
    metadata: Optional[dict] = Field(default_factory=dict)
```

### **3. All Observability via OpenTelemetry**

```python
from opentelemetry import trace
from src.infrastructure.observability.logger import get_logger

tracer = trace.get_tracer(__name__)
logger = get_logger(__name__)

async def execute(self, request: CreateTaskRequest):
    with tracer.start_as_current_span("create_task"):
        try:
            task = await self.task_repo.create(task_entity)
            logger.info(f"Task created: {task.id}")
            return task
        except Exception as e:
            logger.error(f"Task creation failed: {e}", exc_info=True)
            raise
```

### **4. Use Pydantic Settings, NEVER os.environ**

```python
# ❌ NEVER
import os
timeout = int(os.environ.get("TIMEOUT_MS", "5000"))

# ✅ ALWAYS
from src.infrastructure.api.rest.settings import settings
timeout = settings.TIMEOUT_MS
```

### **5. Use Dependency Injection**

```python
# Use case with injected dependencies
class CreateConversationUseCase:
    def __init__(
        self,
        conversation_repo: IConversationRepository,  # Interface from domain
        agent_repo: IAgentRepository,
    ):
        self.conversation_repo = conversation_repo
        self.agent_repo = agent_repo

# FastAPI dependency
async def get_create_conversation_use_case(
    session: AsyncSession = Depends(get_session),
) -> CreateConversationUseCase:
    conv_repo = ConversationRepository(session)
    agent_repo = AgentRepository(session)
    return CreateConversationUseCase(conv_repo, agent_repo)
```

### **6. Use Generic Base Repository Pattern**

```python
from typing import Generic, TypeVar, Type
from sqlalchemy.ext.asyncio import AsyncSession

TModel = TypeVar('TModel')  # SQLAlchemy model
TEntity = TypeVar('TEntity')  # Domain entity

class BaseRepository(Generic[TModel, TEntity]):
    def __init__(self, session: AsyncSession, model_class: Type[TModel]):
        self.session = session
        self.model_class = model_class

    async def get_by_id(self, entity_id: UUID) -> Optional[TEntity]:
        model = await self.session.get(self.model_class, entity_id)
        return self._to_entity(model) if model else None

    @abstractmethod
    def _to_entity(self, model: TModel) -> TEntity:
        """Convert ORM model to domain entity."""
        pass
```

### **7. Comprehensive Testing with pytest Markers**

```python
import pytest

# Mark tests with custom markers
pytestmark = [pytest.mark.asyncio, pytest.mark.use_case]

class TestCreateConversationUseCase:
    async def test_create_conversation_successfully(
        self,
        conversation_repo,
        agent_repo,
    ):
        use_case = CreateConversationUseCase(conversation_repo, agent_repo)
        result = await use_case.execute(request)
        assert result.conversation.id is not None
```

---

## **Common Imports**

```python
# Domain Layer - NO external dependencies
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any  # Use str | None (preferred) or Optional[str]
from uuid import UUID, uuid4
from enum import Enum
from abc import ABC, abstractmethod

# Application Layer
from dataclasses import dataclass
from typing import Optional, List  # Use str | None (preferred) or Optional[str]
from uuid import UUID

# Infrastructure API Layer
from fastapi import FastAPI, APIRouter, Depends, HTTPException, status
from fastapi import Request, Response, Query, Path, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, EmailStr, validator
from pydantic_settings import BaseSettings

# Infrastructure Persistence Layer
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import select, insert, update, delete

# Observability
from opentelemetry import trace
from opentelemetry.trace import Status, StatusCode
from src.infrastructure.observability.logger import get_logger

# Config
from src.infrastructure.api.rest.settings import settings

# Testing
import pytest
from unittest.mock import AsyncMock, Mock
```

---

## **Python Compatibility**

### **Required Versions**

- **Python**: 3.13+
- **Pydantic**: 2.8.0+
- **SQLAlchemy**: 2.0+ (for async support)
- **FastAPI**: Latest version

### **Key Features**

1. **Modern Type Syntax**: Use `str | None` instead of `Optional[str]`
2. **Improved Error Messages**: Enhanced tracebacks with color highlighting
3. **Better Async Support**: Improved TaskGroup and cancellation handling
4. **Performance**: Optional free-threading (experimental) and JIT compiler
5. **New copy.replace()**: Convenient for creating modified copies of dataclasses

---

## **Dependency Management with uv**

### **Installation**

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create project with Python 3.13+
uv init --python 3.13

# Install dependencies
uv sync

# Add dependency to group
uv add --group test pytest pytest-asyncio
uv add --group persistence "sqlalchemy[asyncio]>=2.0.0" asyncpg
uv add "pydantic>=2.8.0"
```

### **Dependency Groups**

```toml
# pyproject.toml
[dependency-groups]
persistence = [
    "sqlalchemy[asyncio]>=2.0.0",
    "asyncpg>=0.29.0",
    "alembic>=1.13.0",
]

messaging = [
    "kafka-python>=2.0.2",
    "aiokafka>=0.10.0",
]

cache = [
    "redis[hiredis]>=5.0.0",
]

observability = [
    "opentelemetry-api>=1.32.1",
    "opentelemetry-sdk>=1.32.1",
    "opentelemetry-exporter-otlp>=1.23.0",
    "opentelemetry-instrumentation-fastapi>=0.53b1",
]

test = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "pytest-mock>=3.12.0",
    "pytest-cov>=4.1.0",
]
```

---

## **Quick Reference**

### **HTTP Status Codes**

| Code | Use Case |
| --- | --- |
| 200 | Success |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 422 | Validation Error (Pydantic) |
| 500 | Server Error |

### **pytest Markers**

| Marker | Purpose |
| --- | --- |
| `@pytest.mark.unit` | Domain/pure unit tests |
| `@pytest.mark.use_case` | Application use case tests |
| `@pytest.mark.service` | Application service tests |
| `@pytest.mark.integration` | Infrastructure integration tests |
| `@pytest.mark.workflow` | End-to-end workflow tests |

**Usage:**

```bash
# Run only use case tests
pytest -m use_case

# Run everything except integration
pytest -m "not integration"

# Run use case and service tests
pytest -m "use_case or service"
```

---

## **Anti-Patterns to Avoid**

❌ Domain layer importing from Application or Infrastructure
❌ Direct os.environ usage (use Pydantic Settings)
❌ Business logic in API routes
❌ Pydantic models in Application layer (use dataclasses)
❌ Missing error handling and logging
❌ No type hints
❌ Synchronous database operations
❌ Using Sentry (use OpenTelemetry)
❌ Not using generic base repository
❌ Tests without pytest markers
❌ Using Pydantic V1
⚠️ Prefer `str | None` over `Optional[str]` (both work, modern syntax preferred)

---

## **Navigation Guide**

| Need to... | Read this |
| --- | --- |
| Understand Clean Architecture | `./resources/clean-architecture.md` |
| Implement domain entities | `./resources/domain-layer.md` |
| Create use cases | `./resources/application-layer.md` |
| Build API endpoints | `./resources/api-layer.md` |
| Implement repositories | `./resources/repository-pattern.md` |
| Validate input | `./resources/validation-patterns.md` |
| Add observability | `./resources/observability.md` |
| Manage config | `./resources/configuration.md` |
| Handle async/errors | `./resources/async-and-errors.md` |
| Write tests | `./resources/testing-guide.md` |
| See complete examples | `./resources/complete-examples.md` |

---

## **Resource Files**

### `./resources/clean-architecture.md`

Three-layer architecture, dependency rule, separation of concerns

### `./resources/domain-layer.md`

Entities, value objects, domain services, interfaces (ports)

### `./resources/application-layer.md`

Use cases, DTOs, application services, orchestration

### `./resources/api-layer.md`

FastAPI routes, Pydantic validation, middleware, dependencies

### `./resources/repository-pattern.md`

Generic base repository, SQLAlchemy async, ORM models

### `./resources/validation-patterns.md`

Pydantic (API layer), dataclasses (Application layer), domain validation

### `./resources/observability.md`

OpenTelemetry setup, tracing, logging, structured logs

### `./resources/configuration.md`

Pydantic Settings, uv dependency groups, environment configs

### `./resources/async-and-errors.md`

Async patterns, exception hierarchy, error handlers

### `./resources/testing-guide.md`

pytest markers, async tests, fixtures, mocking, coverage

### `./resources/complete-examples.md`

Full feature examples across all three layers

---

- **Skill Status**: COMPLETE ✅
- **Line Count**: < 500 ✅
- **Progressive Disclosure**: 11 resource files ✅
