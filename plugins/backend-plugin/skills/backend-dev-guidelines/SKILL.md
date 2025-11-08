---
name: backend-python-dev-guidelines
description: Comprehensive backend development guide for Python/FastAPI Clean Architecture projects. Use when working with domain entities, use cases, repositories, API routes, or implementing Clean Architecture layers. Covers Domain-Application-Infrastructure separation, dependency injection, async patterns, OpenTelemetry observability, Pydantic validation, and modern Python testing with pytest.
---

# **Backend Python Development Guidelines**

## **Purpose**

Establish consistency and best practices for Python/FastAPI applications following **Clean Architecture** principles.

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

- [ ]  [ ] **Domain Entity**: Pure business logic, no dependencies
- [ ]  [ ] **Domain Interface**: Abstract repository/gateway contract
- [ ]  [ ] **Use Case**: Orchestrate domain logic
- [ ]  [ ] **DTO**: Application boundary data transfer (dataclass)
- [ ]  [ ] **Repository**: Implement domain interface
- [ ]  [ ] **API Route**: FastAPI endpoint with Pydantic validation
- [ ]  [ ] **Tests**: Unit (domain) + Use Case + Integration tests
- [ ]  [ ] **Config**: Use Pydantic Settings

### **New Project Checklist**

- [ ]  Directory structure (see [clean-architecture.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md))
- [ ]  [ ] `uv` for dependency management with dependency groups
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
│           │                          │
│           ▼                          │
│    Application Layer                 │
│  (Use Cases, Services, DTOs)         │
│           │                          │
│           ▼                          │
│    Domain Layer                      │
│  (Entities, Value Objects, Rules)    │
└─────────────────────────────────────┘

```

**Dependency Rule:** Dependencies flow INWARD

- Infrastructure → Application → Domain
- Domain has **zero** external dependencies
- Application depends only on Domain
- Infrastructure depends on Application and Domain

See [clean-architecture.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md) for complete details.

---

## **Directory Structure**

```
src/
├── domain/                          # Domain Layer
│   ├── entities/                   # Business entities
│   │   ├── conversation.py
│   │   ├── task.py
│   │   └── agent.py
│   ├── value_objects/              # Immutable value types
│   │   ├── conversation_status.py
│   │   └── task_status.py
│   ├── services/                   # Domain services
│   │   └── state_machine.py
│   ├── interfaces/                 # Ports (abstractions)
│   │   ├── repositories.py
│   │   └── gateways.py
│   └── exceptions/                 # Domain exceptions
│       └── domain_exceptions.py
│
├── application/                     # Application Layer
│   ├── use_cases/                  # Use case implementations
│   │   ├── conversation/
│   │   │   ├── create_conversation.py
│   │   │   └── get_conversation.py
│   │   └── task/
│   │       ├── create_task.py
│   │       └── complete_task.py
│   ├── services/                   # Application services
│   │   └── orchestrator_service.py
│   ├── dtos/                       # Data Transfer Objects
│   │   ├── conversation_dto.py    # Use dataclasses
│   │   └── task_dto.py
│   └── exceptions.py               # Application exceptions
│
└── infrastructure/                  # Infrastructure Layer
    ├── api/rest/                   # Inbound adapters
    │   ├── main.py                 # FastAPI app
    │   ├── settings.py             # Pydantic Settings
    │   ├── routes/
    │   │   ├── conversations.py   # Use Pydantic BaseModel
    │   │   └── tasks.py
    │   └── middleware/
    │       ├── logging_middleware.py
    │       └── context_middleware.py
    ├── persistence/                # Outbound adapters
    │   ├── repositories/
    │   │   ├── base_repository.py # Generic base
    │   │   ├── conversation_repository.py
    │   │   └── task_repository.py
    │   ├── models/                # ORM models
    │   │   ├── conversation_model.py
    │   │   └── task_model.py
    │   └── session.py             # DB session management
    ├── messaging/                  # Message queue adapters
    │   ├── kafka_publisher.py
    │   └── kafka_consumer.py
    ├── observability/              # Cross-cutting concerns
    │   ├── logger.py
    │   └── tracer_setup.py        # OpenTelemetry
    ├── config/                     # Configuration loaders
    │   └── llm_providers_config.py
    └── utils/                      # Shared utilities

```

**Naming Conventions:**

- **Domain Entities**: PascalCase - `Conversation`, `Task`
- **Value Objects**: PascalCase - `ConversationStatus`, `TaskStatus`
- **Use Cases**: PascalCase + UseCase - `CreateConversationUseCase`
- **DTOs**: PascalCase + DTO suffix - `ConversationDTO`, `CreateTaskRequest`
- **Repositories**: PascalCase + Repository - `ConversationRepository`
- **Services**: snake_case files - `orchestrator_service.py`

---

## **Core Principles (7 Key Rules)**

### **1. Domain Layer Has Zero Dependencies**

```python
# ✅ GOOD: Pure domain entityfrom dataclasses import dataclass
from datetime import datetime
from uuid import UUID

@dataclass
class Conversation:
    id: UUID
    user_id: str
    status: ConversationStatus# Value object from domaindef transition_phase(self, new_phase: ConversationPhase) -> None:
        if not self._is_valid_transition(self.phase, new_phase):
            raise ValueError(f"Invalid transition: {self.phase} -> {new_phase}")
        self.phase = new_phase

# ❌ BAD: Domain importing infrastructurefrom sqlalchemy import Column, String# NO!from fastapi import HTTPException# NO!
```

### **2. Use Dataclasses for DTOs, Pydantic for API**

```python
# ✅ Application Layer: Dataclass DTOsfrom dataclasses import dataclass
from uuid import UUID

@dataclass
class CreateConversationRequest:
    user_id: str
    initial_message: str
    agent_id: Optional[str] = None

# ✅ Infrastructure API Layer: Pydantic for validationfrom pydantic import BaseModel, Field

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
# ❌ NEVERimport os
timeout = int(os.environ.get("TIMEOUT_MS", "5000"))

# ✅ ALWAYSfrom src.infrastructure.api.rest.settings import settings
timeout = settings.TIMEOUT_MS

```

### **5. Use Dependency Injection**

```python
# Use case with injected dependenciesclass CreateConversationUseCase:
    def __init__(
        self,
        conversation_repo: IConversationRepository,# Interface from domain
        agent_repo: IAgentRepository,
    ):
        self.conversation_repo = conversation_repo
        self.agent_repo = agent_repo

# FastAPI dependencyasync def get_create_conversation_use_case(
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

TModel = TypeVar('TModel')# SQLAlchemy model
TEntity = TypeVar('TEntity')# Domain entityclass BaseRepository(Generic[TModel, TEntity]):
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
# Domain Layer - NO external dependenciesfrom dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Optional, List, Dict, Any
from uuid import UUID, uuid4
from enum import Enum
from abc import ABC, abstractmethod

# Application Layerfrom dataclasses import dataclass
from typing import Optional, List
from uuid import UUID

# Infrastructure API Layerfrom fastapi import FastAPI, APIRouter, Depends, HTTPException, status
from fastapi import Request, Response, Query, Path, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, EmailStr, validator
from pydantic_settings import BaseSettings

# Infrastructure Persistence Layerfrom sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import select, insert, update, delete

# Observabilityfrom opentelemetry import trace
from opentelemetry.trace import Status, StatusCode
from src.infrastructure.observability.logger import get_logger

# Configfrom src.infrastructure.api.rest.settings import settings

# Testingimport pytest
from unittest.mock import AsyncMock, Mock

```

---

## **Dependency Management with uv**

### **Installation**

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create project
uv init

# Install dependencies
uv sync

# Add dependency to group
uv add --group test pytest pytest-asyncio
uv add --group persistence sqlalchemy asyncpg

```

### **Dependency Groups**

```toml
# pyproject.toml[dependency-groups]
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

### **Common Commands**

```bash
# Sync all dependencies
uv sync

# Add to specific group
uv add --group test pytest-cov

# Run with uv
uv run python main.py
uv run pytest

# Update dependencies
uv lock --upgrade

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

❌ Domain layer importing from Application or Infrastructure ❌ Direct os.environ usage (use Pydantic Settings) ❌ Business logic in API routes ❌ Pydantic models in Application layer (use dataclasses) ❌ Missing error handling and logging ❌ No type hints ❌ Synchronous database operations ❌ Using Sentry (use OpenTelemetry) ❌ Not using generic base repository ❌ Tests without pytest markers

---

## **Navigation Guide**

| Need to... | Read this |
| --- | --- |
| Understand Clean Architecture | [clean-architecture.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md) |
| Implement domain entities | [domain-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/domain-layer.md) |
| Create use cases | [application-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/application-layer.md) |
| Build API endpoints | [api-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/api-layer.md) |
| Implement repositories | [repository-pattern.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/repository-pattern.md) |
| Validate input | [validation-patterns.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/validation-patterns.md) |
| Add observability | [observability.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/observability.md) |
| Manage config | [configuration.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/configuration.md) |
| Handle async/errors | [async-and-errors.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/async-and-errors.md) |
| Write tests | [testing-guide.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/testing-guide.md) |
| See complete examples | [complete-examples.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/complete-examples.md) |

---

## **Resource Files**

### [**clean-architecture.md**](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md)

Three-layer architecture, dependency rule, separation of concerns

### [**domain-layer.md**](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/domain-layer.md)

Entities, value objects, domain services, interfaces (ports)

### [**application-layer.md**](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/application-layer.md)

Use cases, DTOs, application services, orchestration

### [**api-layer.md**](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/api-layer.md)

FastAPI routes, Pydantic validation, middleware, dependencies

### [**repository-pattern.md**](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/repository-pattern.md)

Generic base repository, SQLAlchemy async, ORM models

### [**validation-patterns.md**](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/validation-patterns.md)

Pydantic (API layer), dataclasses (Application layer), domain validation

### [**observability.md**](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/observability.md)

OpenTelemetry setup, tracing, logging, structured logs

### [**configuration.md**](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/configuration.md)

Pydantic Settings, uv dependency groups, environment configs

### [**async-and-errors.md**](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/async-and-errors.md)

Async patterns, exception hierarchy, error handlers

### [**testing-guide.md**](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/testing-guide.md)

pytest markers, async tests, fixtures, mocking, coverage

### [**complete-examples.md**](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/complete-examples.md)

Full feature examples across all three layers

---

- **Skill Status**: COMPLETE ✅
- **Line Count**: < 600 ✅
- **Progressive Disclosure**: 11 resource files ✅