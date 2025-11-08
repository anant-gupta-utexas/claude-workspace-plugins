# **Application Layer - Use Cases and Orchestration**

Complete guide to implementing the Application Layer in Clean Architecture.

## **Table of Contents**

- [Purpose and Rules](application-layer.md#purpose-and-rules)
- [Use Cases](application-layer.md#use-cases)
- [Application Services](application-layer.md#application-services)
- [Data Transfer Objects (DTOs)](application-layer.md#data-transfer-objects-dtos)
- [Application Exceptions](application-layer.md#application-exceptions)

---

## **Purpose and Rules**

### **What is the Application Layer?**

The **Application Layer** orchestrates business logic by coordinating domain entities and infrastructure services.

**Location**: `src/application/`

**Rules**:

- ✅ Imports from `domain/`
- ✅ Uses **dataclasses** for DTOs
- ✅ Depends on domain **interfaces** (not implementations)
- ❌ **NO** imports from `infrastructure/`
- ❌ **NO** HTTP, database, or framework code
- ❌ **NO** Pydantic models (use dataclasses)

### **Purpose**

- Implement application workflows (use cases)
- Coordinate multiple domain entities
- Define application boundaries via DTOs
- Handle application-specific errors

---

## **Use Cases**

### **What is a Use Case?**

A **Use Case** implements a specific application workflow.

**Characteristics**:

- One use case = one user action/workflow
- Orchestrates domain logic
- Uses repositories via interfaces
- Returns DTOs

### **Use Case Template**

```python
# src/application/use_cases/conversation/create_conversation.pyfrom dataclasses import dataclass
from typing import Optional
from uuid import UUID

from ...dtos import (
    CreateConversationRequest,
    CreateConversationResponse,
    ConversationDTO,
)
from ....domain.entities import Conversation
from ....domain.interfaces import (
    IConversationRepository,
    IAgentRepository,
    IMessagingGateway,
)
from ....domain.services import ConversationStateMachine
from ...exceptions import AgentNotFoundException

class CreateConversationUseCase:
    """
    Use case for creating a new conversation.

    Steps:
    1. Validate agent exists
    2. Create conversation entity via domain service
    3. Persist conversation
    4. Publish initial message
    5. Return response DTO
    """

    def __init__(
        self,
        conversation_repo: IConversationRepository,
        agent_repo: IAgentRepository,
        messaging: IMessagingGateway,
    ):
        self.conversation_repo = conversation_repo
        self.agent_repo = agent_repo
        self.messaging = messaging

    async def execute(
        self,
        request: CreateConversationRequest
    ) -> CreateConversationResponse:
# Step 1: Validate agent
        agent = await self.agent_repo.get_by_id(request.agent_id)
        if not agent:
            raise AgentNotFoundException(request.agent_id)

# Step 2: Create conversation via domain service
        conversation = ConversationStateMachine.start_conversation(
            user_id=request.user_id,
            agent_id=request.agent_id,
        )

# Step 3: Persist
        created = await self.conversation_repo.create(conversation)

# Step 4: Publish initial messageawait self.messaging.publish_message(
            agent_id=request.agent_id,
            payload={
                "conversation_id": str(created.id),
                "message": request.initial_message,
            }
        )

# Step 5: Return DTOreturn CreateConversationResponse(
            conversation=ConversationDTO.from_entity(created),
            primary_agent_id=request.agent_id,
            status="initiated",
        )

```

### **Complex Use Case Example**

```python
# src/application/use_cases/task/delegate_task.pyfrom ...dtos import DelegateTaskRequest, TaskDTO
from ...exceptions import (
    TaskNotFoundException,
    InvalidTaskStateError,
    InvalidDelegationError,
)
from ....domain.interfaces import ITaskRepository
from ....domain.value_objects import TaskStatus
from .create_task import CreateTaskUseCase
from ...dtos import CreateTaskRequest

class DelegateTaskUseCase:
    """
    Use case for delegating a task to a subtask.

    Business Rules:
    1. Parent task must exist and be RUNNING
    2. Sub-agent must be different from parent agent
    3. Subtask created via CreateTaskUseCase
    4. Parent task updated to WAITING_FOR_SUBTASK
    """

    def __init__(
        self,
        task_repository: ITaskRepository,
        create_task_use_case: CreateTaskUseCase,
    ):
        self.task_repo = task_repository
        self.create_task = create_task_use_case

    async def execute(self, request: DelegateTaskRequest) -> TaskDTO:
# Validate parent task
        parent_task = await self.task_repo.get_by_id(request.parent_task_id)
        if not parent_task:
            raise TaskNotFoundException(request.parent_task_id)

# Business rule: Can only delegate running tasksif parent_task.status != TaskStatus.RUNNING:
            raise InvalidTaskStateError(
                f"Cannot delegate task in status {parent_task.status}",
                current_state=parent_task.status.value
            )

# Business rule: Sub-agent must be differentif request.sub_agent_id == parent_task.agent_id:
            raise InvalidDelegationError(
                "Sub-agent must be different from parent agent"
            )

# Create subtask
        subtask_request = CreateTaskRequest(
            conversation_id=parent_task.conversation_id,
            agent_id=request.sub_agent_id,
            input=request.subtask_input,
            parent_task_id=parent_task.id,
        )

        subtask_response = await self.create_task.execute(subtask_request)

# Update parent task
        parent_task.wait_for_subtask()
        await self.task_repo.update(parent_task)

        return subtask_response.task

```

---

## **Application Services**

### **What is an Application Service?**

An **Application Service** coordinates multiple use cases.

**When to use**:

- Complex workflows spanning multiple use cases
- Business logic requiring multiple entities
- Transaction boundaries

### **Application Service Example**

```python
# src/application/services/orchestrator_service.pyfrom dataclasses import dataclass
from typing import Optional
from uuid import UUID

from ..use_cases import (
    CreateConversationUseCase,
    CreateTaskUseCase,
    DiscoverAgentUseCase,
)
from ..dtos import (
    CreateConversationRequest,
    CreateTaskRequest,
    AgentDiscoveryRequest,
)

@dataclass
class StartConversationRequest:
    """Request to start a new conversation with orchestration."""
    user_id: str
    initial_message: str
    agent_id: Optional[str] = None

class OrchestratorService:
    """
    Application service coordinating multiple use cases.

    Handles complex workflows like:
    - Starting conversations with agent discovery
    - Managing conversation lifecycle
    - Coordinating tasks and agents
    """

    def __init__(
        self,
        create_conversation: CreateConversationUseCase,
        create_task: CreateTaskUseCase,
        discover_agent: DiscoverAgentUseCase,
    ):
        self.create_conversation = create_conversation
        self.create_task = create_task
        self.discover_agent = discover_agent

    async def start_conversation(self, request: StartConversationRequest):
        """
        Start a new conversation with full orchestration.

        Steps:
        1. Discover agent (if not provided)
        2. Create conversation
        3. Create initial task
        4. Return complete result
        """
# Step 1: Agent discovery
        agent_id = request.agent_id
        if not agent_id:
            discovery_result = await self.discover_agent.execute(
                AgentDiscoveryRequest(
                    query=request.initial_message,
                    client_facing_only=True,
                )
            )
            agent_id = discovery_result.selected_agent.agent_id

# Step 2: Create conversation
        conv_result = await self.create_conversation.execute(
            CreateConversationRequest(
                user_id=request.user_id,
                initial_message=request.initial_message,
                agent_id=agent_id,
            )
        )

# Step 3: Create initial task
        task_result = await self.create_task.execute(
            CreateTaskRequest(
                conversation_id=conv_result.conversation.id,
                agent_id=agent_id,
                input={"message": request.initial_message},
            )
        )

        return {
            "conversation": conv_result.conversation,
            "task": task_result.task,
            "agent_id": agent_id,
        }

```

---

## **Data Transfer Objects (DTOs)**

### **What are DTOs?**

**DTOs** (Data Transfer Objects) carry data across application boundaries.

**Rules**:

- Use **dataclasses** (not Pydantic)
- Immutable when possible
- Simple data structures
- No business logic

### **DTO Examples**

```python
# src/application/dtos/conversation_dto.pyfrom dataclasses import dataclass
from datetime import datetime
from typing import Dict, Any, Optional
from uuid import UUID

@dataclass
class ConversationDTO:
    """DTO for conversation data."""

    id: UUID
    user_id: str
    agent_id: Optional[str]
    current_agent: Optional[str]
    status: str
    phase: str
    message_count: int
    metadata: Dict[str, Any]
    created_at: datetime
    updated_at: datetime

    @classmethod
    def from_entity(cls, entity) -> "ConversationDTO":
        """Convert domain entity to DTO."""
        return cls(
            id=entity.id,
            user_id=entity.user_id,
            agent_id=entity.agent_id,
            current_agent=entity.current_agent,
            status=entity.status.value,
            phase=entity.phase.value,
            message_count=entity.message_count,
            metadata=entity.metadata,
            created_at=entity.created_at,
            updated_at=entity.updated_at,
        )

@dataclass
class CreateConversationRequest:
    """Request to create a new conversation."""
    user_id: str
    initial_message: str
    agent_id: Optional[str] = None

@dataclass
class CreateConversationResponse:
    """Response after creating a conversation."""
    conversation: ConversationDTO
    primary_agent_id: str
    status: str# "initiated", "error"
```

### **DTO Mappers**

```python
# src/application/dtos/task_dto.pyfrom dataclasses import dataclass
from datetime import datetime
from typing import Dict, Any, Optional
from uuid import UUID

@dataclass
class TaskDTO:
    """DTO for task data."""

    id: UUID
    conversation_id: UUID
    agent_id: str
    parent_task_id: Optional[UUID]
    status: str
    input: Dict[str, Any]
    output: Optional[Dict[str, Any]]
    error: Optional[str]
    metadata: Dict[str, Any]
    created_at: datetime
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    updated_at: datetime

    @classmethod
    def from_entity(cls, entity) -> "TaskDTO":
        """Convert domain entity to DTO."""
        return cls(
            id=entity.id,
            conversation_id=entity.conversation_id,
            agent_id=entity.agent_id,
            parent_task_id=entity.parent_task_id,
            status=entity.status.value,
            input=entity.input,
            output=entity.output,
            error=entity.error,
            metadata=entity.metadata,
            created_at=entity.created_at,
            started_at=entity.started_at,
            completed_at=entity.completed_at,
            updated_at=entity.updated_at,
        )

```

---

## **Application Exceptions**

### **Exception Hierarchy**

```python
# src/application/exceptions.pyfrom typing import Optional
from uuid import UUID

class ApplicationException(Exception):
    """Base exception for all application layer errors."""
    pass

class AgentNotFoundException(ApplicationException):
    """Raised when an agent is not found in the registry."""

    def __init__(self, agent_id: str):
        self.agent_id = agent_id
        super().__init__(f"Agent not found: {agent_id}")

class TaskNotFoundException(ApplicationException):
    """Raised when a task is not found."""

    def __init__(self, task_id: UUID):
        self.task_id = task_id
        super().__init__(f"Task not found: {task_id}")

class InvalidTaskStateError(ApplicationException):
    """Raised when attempting an invalid task state transition."""

    def __init__(self, message: str, current_state: Optional[str] = None):
        self.current_state = current_state
        super().__init__(message)

class InvalidDelegationError(ApplicationException):
    """Raised when attempting an invalid task delegation."""

    def __init__(self, message: str):
        super().__init__(message)

class ConversationNotFoundException(ApplicationException):
    """Raised when a conversation is not found."""

    def __init__(self, conversation_id: UUID):
        self.conversation_id = conversation_id
        super().__init__(f"Conversation not found: {conversation_id}")

class UnauthorizedError(ApplicationException):
    """Raised when a user is not authorized for an operation."""

    def __init__(self, message: str):
        super().__init__(message)

```

---

## **Best Practices**

### **1. One Use Case, One Responsibility**

```python
# ✅ GOOD: Focused use caseclass CreateTaskUseCase:
    async def execute(self, request: CreateTaskRequest):
# Only creates taskspass

# ❌ BAD: Too many responsibilitiesclass TaskUseCase:
    async def create(self):...
    async def update(self):...
    async def delete(self):...
    async def delegate(self):...

```

### **2. Use Dataclasses for DTOs**

```python
# ✅ GOOD: Dataclass DTOfrom dataclasses import dataclass

@dataclass
class CreateTaskRequest:
    conversation_id: UUID
    agent_id: str
    input: Dict[str, Any]

# ❌ BAD: Pydantic in application layerfrom pydantic import BaseModel

class CreateTaskRequest(BaseModel):# Wrong layer!
    ...

```

### **3. Depend on Interfaces**

```python
# ✅ GOOD: Depends on interfacefrom ....domain.interfaces import ITaskRepository

class CreateTaskUseCase:
    def __init__(self, task_repo: ITaskRepository):
        self.task_repo = task_repo

# ❌ BAD: Depends on implementationfrom ....infrastructure.persistence.repositories import TaskRepository

class CreateTaskUseCase:
    def __init__(self, task_repo: TaskRepository):# Wrong!
        ...

```

---

**Related Files:**

- [SKILL.md](SKILL.md) - Main guide
- [clean-architecture.md](clean-architecture.md) - Architecture overview
- [domain-layer.md](domain-layer.md) - Domain layer details
- [api-layer.md](api-layer.md) - API layer details
- [testing-guide.md](testing-guide.md) - Testing use cases
