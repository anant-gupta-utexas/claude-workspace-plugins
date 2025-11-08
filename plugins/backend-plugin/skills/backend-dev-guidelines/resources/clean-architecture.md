# **Clean Architecture - Three-Layer Pattern**

Complete guide to Clean Architecture (Hexagonal Architecture / Ports and Adapters) for Python/FastAPI.

## **Table of Contents**

- [Core Concepts](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md#core-concepts)
- [The Three Layers](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md#the-three-layers)
- [Dependency Rule](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md#dependency-rule)
- [Directory Structure](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md#directory-structure)
- [Request Lifecycle](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md#request-lifecycle)
- [Benefits](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md#benefits)

---

## **Core Concepts**

### **What is Clean Architecture?**

Clean Architecture organizes code into layers with strict dependency rules:

- **Inner layers** contain business logic
- **Outer layers** contain technical details
- **Dependencies point inward** only

```
┌───────────────────────────────────────┐
│   Infrastructure Layer                │  ← Frameworks, DB, HTTP, External Services
│   (Adapters, Implementation)          │
│        │                               │
│        ▼                               │
│   Application Layer                    │  ← Use Cases, Orchestration, DTOs
│   (Business Workflows)                 │
│        │                               │
│        ▼                               │
│   Domain Layer                         │  ← Business Rules, Entities, Logic
│   (Pure Business Logic)                │
└───────────────────────────────────────┘

```

### **Key Principles**

**1. Dependency Inversion**

- Infrastructure depends on Application
- Application depends on Domain
- Domain depends on NOTHING

**2. Single Responsibility**

- Each layer has ONE clear purpose
- Entities contain business rules
- Use cases orchestrate workflows
- Adapters handle external concerns

**3. Testability**

- Domain: Pure unit tests (no mocks)
- Application: Mocked infrastructure
- Infrastructure: Integration tests

---

## **The Three Layers**

### **Domain Layer (`src/domain/`)**

**Purpose**: Pure business logic with zero external dependencies

**Contains**:

- **Entities**: Objects with identity and behavior
- **Value Objects**: Immutable data with validation
- **Domain Services**: Business logic spanning multiple entities
- **Interfaces (Ports)**: Abstractions for infrastructure
- **Exceptions**: Domain-specific errors

**Rules**:

- ✅ Only imports from domain/
- ✅ Pure Python (dataclasses, enums, etc.)
- ✅ No framework dependencies
- ❌ No imports from application/ or infrastructure/
- ❌ No FastAPI, SQLAlchemy, etc.

**Example**:

```python
# src/domain/entities/conversation.pyfrom dataclasses import dataclass, field
from datetime import datetime, timezone
from uuid import UUID, uuid4
from ..value_objects import ConversationStatus, ConversationPhase

@dataclass
class Conversation:
    """
    Conversation entity with business rules.

    Business Rules:
    - Must have a user_id
    - Phase transitions must be valid
    - Status changes must follow lifecycle
    """
    id: UUID = field(default_factory=uuid4)
    user_id: str = field(default="")
    status: ConversationStatus = ConversationStatus.ACTIVE
    phase: ConversationPhase = ConversationPhase.NONE
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def __post_init__(self):
        if not self.user_id:
            raise ValueError("user_id is required")

    def transition_phase(self, new_phase: ConversationPhase) -> None:
        """Transition to new phase with validation."""
        if not self._is_valid_transition(self.phase, new_phase):
            raise ValueError(f"Invalid transition: {self.phase} -> {new_phase}")
        self.phase = new_phase
        self.updated_at = datetime.now(timezone.utc)

```

### **Application Layer (`src/application/`)**

**Purpose**: Orchestrate business logic and coordinate workflows

**Contains**:

- **Use Cases**: Specific application workflows
- **Application Services**: Coordinate multiple use cases
- **DTOs (Data Transfer Objects)**: Boundary crossing data
- **Exceptions**: Application-specific errors

**Rules**:

- ✅ Imports from domain/
- ✅ Uses dataclasses for DTOs
- ✅ Depends on domain interfaces (not implementations)
- ❌ No imports from infrastructure/
- ❌ No HTTP, database, or framework code

**Example**:

```python
# src/application/use_cases/conversation/create_conversation.pyfrom dataclasses import dataclass
from uuid import UUID
from ...dtos import CreateConversationRequest, CreateConversationResponse
from ....domain.entities import Conversation
from ....domain.interfaces import IConversationRepository, IAgentRepository
from ....domain.value_objects import ConversationStatus

class CreateConversationUseCase:
    """
    Use case for creating a new conversation.

    Steps:
    1. Validate agent exists
    2. Create conversation entity
    3. Persist via repository
    4. Return response
    """

    def __init__(
        self,
        conversation_repo: IConversationRepository,
        agent_repo: IAgentRepository,
    ):
        self.conversation_repo = conversation_repo
        self.agent_repo = agent_repo

    async def execute(self, request: CreateConversationRequest) -> CreateConversationResponse:
# Validate agent exists
        agent = await self.agent_repo.get_by_id(request.agent_id)
        if not agent:
            raise AgentNotFoundException(request.agent_id)

# Create domain entity
        conversation = Conversation(
            user_id=request.user_id,
            agent_id=request.agent_id,
            status=ConversationStatus.ACTIVE,
        )

# Persist
        created = await self.conversation_repo.create(conversation)

        return CreateConversationResponse(
            conversation=ConversationDTO.from_entity(created),
            agent_id=request.agent_id,
        )

```

### **Infrastructure Layer (`src/infrastructure/`)**

**Purpose**: Implement technical details and external integrations

**Contains**:

- **API**: FastAPI routes, Pydantic models, middleware
- **Persistence**: Repository implementations, ORM models, database
- **Messaging**: Kafka producers/consumers
- **Observability**: OpenTelemetry, logging
- **Config**: Settings, environment configuration

**Rules**:

- ✅ Imports from domain/ and application/
- ✅ Implements domain interfaces
- ✅ All framework/library code here
- ✅ Pydantic models for API validation

**Example**:

```python
# src/infrastructure/persistence/repositories/conversation_repository.pyfrom uuid import UUID
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from src.domain.entities import Conversation
from src.domain.interfaces import IConversationRepository
from src.domain.value_objects import ConversationStatus
from ..models import ConversationModel
from .base_repository import BaseRepository

class ConversationRepository(
    BaseRepository[ConversationModel, Conversation],
    IConversationRepository
):
    """Repository implementation for conversation persistence."""

    def __init__(self, session: AsyncSession):
        super().__init__(session, ConversationModel, "Conversation")

    def _to_entity(self, model: ConversationModel) -> Conversation:
        """Convert ORM model to domain entity."""
        return Conversation(
            id=model.id,
            user_id=model.user_id,
            agent_id=model.agent_id,
            status=ConversationStatus.from_string(model.status),
            phase=ConversationPhase.from_string(model.phase),
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    def _to_model(self, entity: Conversation) -> ConversationModel:
        """Convert domain entity to ORM model."""
        return ConversationModel(
            id=entity.id,
            user_id=entity.user_id,
            agent_id=entity.agent_id,
            status=entity.status.value,
            phase=entity.phase.value,
            created_at=entity.created_at,
            updated_at=entity.updated_at,
        )

```

---

## **Dependency Rule**

### **The Golden Rule**

**Dependencies flow INWARD, never outward**

```
Infrastructure  ──▶  Application  ──▶  Domain
(can import)       (can import)     (imports nothing)

```

### **What This Means**

**Domain Layer**:

```python
# ✅ GOOD: Pure domain codefrom dataclasses import dataclass
from ..value_objects import TaskStatus

# ❌ BAD: External dependenciesfrom sqlalchemy import Column# NO!from fastapi import HTTPException# NO!from pydantic import BaseModel# NO!
```

**Application Layer**:

```python
# ✅ GOOD: Depends on domain interfacesfrom ....domain.interfaces import ITaskRepository
from ....domain.entities import Task

# ❌ BAD: Depends on infrastructurefrom ...infrastructure.persistence.repositories import TaskRepository# NO!
```

**Infrastructure Layer**:

```python
# ✅ GOOD: Implements domain interfacesfrom src.domain.interfaces import ITaskRepository
from src.domain.entities import Task
from sqlalchemy.ext.asyncio import AsyncSession

```

---

## **Directory Structure**

### **Complete Layout**

```
src/
├── domain/                              # Domain Layer
│   ├── __init__.py
│   ├── entities/                       # Business entities
│   │   ├── __init__.py
│   │   ├── conversation.py
│   │   ├── task.py
│   │   ├── agent.py
│   │   ├── message.py
│   │   └── hitl_checkpoint.py
│   ├── value_objects/                  # Immutable values
│   │   ├── __init__.py
│   │   ├── conversation_status.py
│   │   ├── conversation_phase.py
│   │   ├── task_status.py
│   │   └── message_type.py
│   ├── services/                       # Domain services
│   │   ├── __init__.py
│   │   ├── conversation_state_machine.py
│   │   └── task_state_machine.py
│   ├── interfaces/                     # Ports (abstractions)
│   │   ├── __init__.py
│   │   ├── repositories.py             # IConversationRepository, ITaskRepository
│   │   ├── gateways.py                 # IAgentGateway, IMessagingGateway
│   │   └── services.py                 # IMemoryService
│   └── exceptions/                     # Domain exceptions
│       ├── __init__.py
│       └── domain_exceptions.py
│
├── application/                         # Application Layer
│   ├── __init__.py
│   ├── use_cases/                      # Use case implementations
│   │   ├── __init__.py
│   │   ├── conversation/
│   │   │   ├── __init__.py
│   │   │   ├── create_conversation.py
│   │   │   ├── resume_conversation.py
│   │   │   └── get_conversation.py
│   │   ├── task/
│   │   │   ├── __init__.py
│   │   │   ├── create_task.py
│   │   │   ├── complete_task.py
│   │   │   └── delegate_task.py
│   │   └── agent/
│   │       ├── __init__.py
│   │       ├── discover_agent.py
│   │       └── invoke_agent.py
│   ├── services/                       # Application services
│   │   ├── __init__.py
│   │   ├── orchestrator_service.py
│   │   └── agent_lifecycle_service.py
│   ├── dtos/                           # Data Transfer Objects (dataclasses)
│   │   ├── __init__.py
│   │   ├── conversation_dto.py
│   │   ├── task_dto.py
│   │   └── agent_dto.py
│   └── exceptions.py                   # Application exceptions
│
└── infrastructure/                      # Infrastructure Layer
    ├── __init__.py
    ├── api/rest/                       # API adapters
    │   ├── __init__.py
    │   ├── main.py                     # FastAPI app
    │   ├── settings.py                 # Pydantic Settings
    │   ├── dependencies.py             # DI setup
    │   ├── routes/                     # Endpoints (Pydantic models)
    │   │   ├── __init__.py
    │   │   ├── conversations.py
    │   │   └── tasks.py
    │   └── middleware/
    │       ├── __init__.py
    │       ├── logging_middleware.py
    │       └── context_middleware.py
    ├── persistence/                    # Database adapters
    │   ├── __init__.py
    │   ├── session.py                  # DB session management
    │   ├── repositories/               # Repository implementations
    │   │   ├── __init__.py
    │   │   ├── base_repository.py
    │   │   ├── conversation_repository.py
    │   │   └── task_repository.py
    │   └── models/                     # SQLAlchemy ORM models
    │       ├── __init__.py
    │       ├── base.py
    │       ├── conversation_model.py
    │       └── task_model.py
    ├── messaging/                      # Message queue adapters
    │   ├── __init__.py
    │   ├── kafka_publisher.py
    │   └── kafka_consumer.py
    ├── observability/                  # Cross-cutting concerns
    │   ├── __init__.py
    │   ├── logger.py
    │   └── tracer_setup.py
    └── config/                         # Configuration
        ├── __init__.py
        └── llm_providers_config.py

```

---

## **Request Lifecycle**

### **Complete Flow Example**

**User Request → Domain Logic → Infrastructure → Response**

```
1. HTTP POST /api/v1/conversations
   │
   ▼
2. Infrastructure/API: FastAPI Route (conversations.py)
   - Pydantic validation
   - Extract user context
   │
   ▼
3. Infrastructure/API: Dependency Injection
   - Get database session
   - Create repository instances
   - Create use case with dependencies
   │
   ▼
4. Application: Use Case (CreateConversationUseCase)
   - Orchestrate business workflow
   - Call domain services
   - Use repositories via interfaces
   │
   ▼
5. Domain: Business Logic
   - Create Conversation entity
   - Validate business rules
   - State transitions
   │
   ▼
6. Infrastructure/Persistence: Repository
   - Convert entity to ORM model
   - Persist to database
   - Return domain entity
   │
   ▼
7. Application: Return DTO
   - Convert entity to DTO
   - Return to API layer
   │
   ▼
8. Infrastructure/API: HTTP Response
   - Convert DTO to Pydantic model
   - Return JSON response

```

### **Code Example**

```python
# 1. FastAPI Route (Infrastructure)@router.post("/conversations", status_code=201)
async def create_conversation(
    request: CreateConversationApiRequest,# Pydantic validation
    use_case: CreateConversationUseCase = Depends(get_create_conversation_use_case),
    current_user: str = Depends(get_current_user),
) -> ConversationApiResponse:
# 2. Call application use case
    app_request = CreateConversationRequest(
        user_id=current_user,
        initial_message=request.initial_message,
        agent_id=request.agent_id,
    )

    result = await use_case.execute(app_request)

# 3. Convert DTO to Pydantic responsereturn ConversationApiResponse(
        id=str(result.conversation.id),
        user_id=result.conversation.user_id,
        status=result.conversation.status,
    )

```

---

## **Benefits**

### **1. Testability**

**Domain Tests**: Pure unit tests, no mocks

```python
def test_conversation_phase_transition():
    conversation = Conversation(user_id="user123")
    conversation.transition_phase(ConversationPhase.REQUIREMENTS_GATHERING)
    assert conversation.phase == ConversationPhase.REQUIREMENTS_GATHERING

```

**Application Tests**: Mock infrastructure

```python
async def test_create_conversation_use_case():
    mock_repo = AsyncMock(spec=IConversationRepository)
    use_case = CreateConversationUseCase(mock_repo, mock_agent_repo)

    result = await use_case.execute(request)
    mock_repo.create.assert_called_once()

```

**Infrastructure Tests**: Integration tests

```python
async def test_conversation_repository(db_session):
    repo = ConversationRepository(db_session)
    conversation = Conversation(user_id="user123")

    created = await repo.create(conversation)
    assert created.id is not None

```

### **2. Maintainability**

- **Clear boundaries**: Each layer has distinct responsibilities
- **Easy to locate bugs**: Logic organized by layer
- **Isolated changes**: Modify one layer without affecting others
- **Type safety**: Type hints throughout

### **3. Flexibility**

- **Swap implementations**: Change database (Postgres → MongoDB)
- **Multiple adapters**: REST + GraphQL + gRPC
- **Framework independence**: Business logic not tied to FastAPI
- **Easy refactoring**: Clear interfaces

### **4. Independence**

- **Framework agnostic**: Domain layer has no framework code
- **Database agnostic**: Repository pattern abstracts storage
- **UI agnostic**: Use cases work with any interface
- **Testable without external dependencies**

### **5. Scalability**

- **Clear patterns**: Easy to add new features
- **Team scalability**: Teams can work on different layers
- **Parallel development**: Clear interfaces enable concurrent work
- **Consistent structure**: New developers onboard faster

---

**Related Files:**

- [SKILL.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/SKILL.md) - Main guide
- [domain-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/domain-layer.md) - Domain layer details
- [application-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/application-layer.md) - Application layer details
- [api-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/api-layer.md) - Infrastructure API details
- [repository-pattern.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/repository-pattern.md) - Repository implementation