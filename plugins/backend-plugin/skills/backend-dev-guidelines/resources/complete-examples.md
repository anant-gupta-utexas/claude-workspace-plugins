# **Complete Examples - Full Feature Implementation**

Complete end-to-end examples showing features implemented across all Clean Architecture layers.

## **Table of Contents**

- [Task Management Feature](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/complete-examples.md#task-management-feature)
- [Conversation Lifecycle](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/complete-examples.md#conversation-lifecycle)
- [Testing Full Stack](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/complete-examples.md#testing-full-stack)

---

## **Task Management Feature**

### **Overview**

Complete implementation of task creation across all three layers.

### **1. Domain Layer**

### **Task Entity**

```python
# src/domain/entities/task.pyfrom dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Dict, Any, Optional
from uuid import UUID, uuid4

from ..value_objects import TaskStatus

@dataclass
class Task:
    """
    Task entity representing a unit of work.

    Business Rules:
    - Must have conversation_id and agent_id
    - Status transitions must be valid
    - Terminal states cannot be changed
    """
    id: UUID = field(default_factory=uuid4)
    conversation_id: UUID = field(default=None)
    agent_id: str = field(default="")
    parent_task_id: Optional[UUID] = None
    status: TaskStatus = TaskStatus.PENDING
    input: Dict[str, Any] = field(default_factory=dict)
    output: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    updated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def __post_init__(self):
        """Validate business rules."""
        if not self.conversation_id:
            raise ValueError("conversation_id is required")
        if not self.agent_id:
            raise ValueError("agent_id is required")

    def start(self) -> None:
        """Mark task as started."""
        if self.status != TaskStatus.PENDING:
            raise ValueError(f"Can only start pending tasks, current: {self.status}")

        self.status = TaskStatus.RUNNING
        self.started_at = datetime.now(timezone.utc)
        self.updated_at = self.started_at

    def complete(self, output: Dict[str, Any]) -> None:
        """Complete task with output."""
        if self.status != TaskStatus.RUNNING:
            raise ValueError(f"Can only complete running tasks, current: {self.status}")

        self.status = TaskStatus.COMPLETED
        self.output = output
        self.completed_at = datetime.now(timezone.utc)
        self.updated_at = self.completed_at

```

### **Task Status Value Object**

```python
# src/domain/value_objects/task_status.pyfrom enum import Enum

class TaskStatus(str, Enum):
    """Task lifecycle status."""
    PENDING = "pending"
    RUNNING = "running"
    WAITING_FOR_USER = "waiting_for_user"
    WAITING_FOR_SUBTASK = "waiting_for_subtask"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"

    @classmethod
    def from_string(cls, value: str) -> "TaskStatus":
        """Convert string to enum."""
        try:
            return cls(value)
        except ValueError:
            raise ValueError(f"Invalid task status: {value}")

    def is_terminal(self) -> bool:
        """Check if this is a terminal status."""
        return self in {self.COMPLETED, self.FAILED, self.CANCELLED}

```

### **Repository Interface**

```python
# src/domain/interfaces/repositories.pyfrom abc import ABC, abstractmethod
from typing import List, Optional
from uuid import UUID
from ..entities import Task

class ITaskRepository(ABC):
    """Interface for task persistence."""

    @abstractmethod
    async def create(self, task: Task) -> Task:
        """Create a new task."""
        pass

    @abstractmethod
    async def get_by_id(self, task_id: UUID) -> Optional[Task]:
        """Get task by ID."""
        pass

    @abstractmethod
    async def update(self, task: Task) -> Task:
        """Update an existing task."""
        pass

    @abstractmethod
    async def find_pending_for_agent(self, agent_id: str) -> List[Task]:
        """Find all pending tasks for an agent."""
        pass

```

### **2. Application Layer**

### **DTOs**

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
    def from_entity(cls, entity: Task) -> "TaskDTO":
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

@dataclass
class CreateTaskRequest:
    """Request to create a new task."""
    conversation_id: UUID
    agent_id: str
    input: Dict[str, Any]
    parent_task_id: Optional[UUID] = None

@dataclass
class CreateTaskResponse:
    """Response after creating a task."""
    task: TaskDTO
    status: str

```

### **Use Case**

```python
# src/application/use_cases/task/create_task.pyfrom uuid import UUID
from ...dtos import CreateTaskRequest, CreateTaskResponse, TaskDTO
from ...exceptions import AgentNotFoundException
from ....domain.entities import Task
from ....domain.interfaces import (
    ITaskRepository,
    IMessagingGateway,
    IAgentRepository,
)
from ....domain.value_objects import TaskStatus

class CreateTaskUseCase:
    """
    Use case for creating a new task.

    Business Rules:
    1. Agent must exist
    2. Conversation must exist
    3. Task created with PENDING status
    4. Message published to agent queue
    """

    def __init__(
        self,
        task_repository: ITaskRepository,
        messaging_gateway: IMessagingGateway,
        agent_repository: IAgentRepository,
    ):
        self.task_repo = task_repository
        self.messaging = messaging_gateway
        self.agent_repo = agent_repository

    async def execute(self, request: CreateTaskRequest) -> CreateTaskResponse:
# Step 1: Validate agent exists
        agent = await self.agent_repo.get_by_id(request.agent_id)
        if not agent:
            raise AgentNotFoundException(request.agent_id)

# Step 2: Create task entity
        task = Task(
            conversation_id=request.conversation_id,
            agent_id=request.agent_id,
            parent_task_id=request.parent_task_id,
            status=TaskStatus.PENDING,
            input=request.input,
        )

# Step 3: Persist task
        created_task = await self.task_repo.create(task)

# Step 4: Publish message to agent queueawait self.messaging.publish_message(
            agent_id=request.agent_id,
            payload={
                "task_id": str(created_task.id),
                "conversation_id": str(created_task.conversation_id),
                "input": created_task.input,
            }
        )

# Step 5: Return responsereturn CreateTaskResponse(
            task=TaskDTO.from_entity(created_task),
            status="initiated",
        )

```

### **3. Infrastructure Layer**

### **ORM Model**

```python
# src/infrastructure/persistence/models/task_model.pyfrom datetime import datetime, timezone
from typing import Optional, Dict, Any
from uuid import UUID, uuid4

from sqlalchemy import String, Text, JSON, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from .base import Base

class TaskModel(Base):
    """SQLAlchemy ORM model for tasks."""
    __tablename__ = "tasks"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    conversation_id: Mapped[UUID] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE")
    )
    parent_task_id: Mapped[Optional[UUID]] = mapped_column(
        ForeignKey("tasks.id", ondelete="SET NULL"),
        nullable=True
    )
    agent_id: Mapped[str] = mapped_column(String(255), nullable=False)
    status: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    input: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSON, nullable=True)
    output: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSON, nullable=True)
    error: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    metadata_: Mapped[Optional[Dict[str, Any]]] = mapped_column("metadata", JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

```

### **Repository Implementation**

```python
# src/infrastructure/persistence/repositories/task_repository.pyfrom typing import Optional, List
from uuid import UUID
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.domain.entities import Task
from src.domain.interfaces import ITaskRepository
from src.domain.value_objects import TaskStatus
from ..models import TaskModel
from .base_repository import BaseRepository

class TaskRepository(
    BaseRepository[TaskModel, Task],
    ITaskRepository
):
    """Repository for task persistence."""

    def __init__(self, session: AsyncSession):
        super().__init__(session, TaskModel, "Task")

    def _to_entity(self, model: TaskModel) -> Task:
        """Convert ORM model to domain entity."""
        return Task(
            id=model.id,
            conversation_id=model.conversation_id,
            agent_id=model.agent_id,
            parent_task_id=model.parent_task_id,
            status=TaskStatus.from_string(model.status),
            input=model.input or {},
            output=model.output,
            error=model.error,
            metadata=model.metadata_ or {},
            created_at=model.created_at,
            started_at=model.started_at,
            completed_at=model.completed_at,
            updated_at=model.updated_at
        )

    def _to_model(self, entity: Task) -> TaskModel:
        """Convert domain entity to ORM model."""
        return TaskModel(
            id=entity.id,
            conversation_id=entity.conversation_id,
            agent_id=entity.agent_id,
            parent_task_id=entity.parent_task_id,
            status=entity.status.value,
            input=entity.input,
            output=entity.output,
            error=entity.error,
            metadata_=entity.metadata,
            created_at=entity.created_at,
            started_at=entity.started_at,
            completed_at=entity.completed_at,
            updated_at=entity.updated_at
        )

    async def create(self, task: Task) -> Task:
        """Create a new task."""
        model = self._to_model(task)
        created_model = await self._create(model)
        return self._to_entity(created_model)

    async def get_by_id(self, task_id: UUID) -> Optional[Task]:
        """Get task by ID."""
        model = await self._get_by_id(task_id)
        return self._to_entity(model) if model else None

    async def update(self, task: Task) -> Task:
        """Update an existing task."""
        existing = await self._get_by_id(task.id)
        if not existing:
            raise EntityNotFoundError("Task", task.id)

        existing.status = task.status.value
        existing.output = task.output
        existing.error = task.error
        existing.started_at = task.started_at
        existing.completed_at = task.completed_at
        existing.updated_at = task.updated_at

        updated_model = await self._update(existing)
        return self._to_entity(updated_model)

    async def find_pending_for_agent(self, agent_id: str) -> List[Task]:
        """Find all pending tasks for an agent."""
        query = select(TaskModel).where(
            TaskModel.agent_id == agent_id,
            TaskModel.status == TaskStatus.PENDING.value
        )
        result = await self.session.execute(query)
        models = list(result.scalars().all())
        return [self._to_entity(model) for model in models]

```

### **API Route**

```python
# src/infrastructure/api/rest/routes/tasks.pyfrom fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from uuid import UUID

from ..dependencies import get_create_task_use_case
from src.application.use_cases.task import CreateTaskUseCase
from src.application.dtos import CreateTaskRequest
from src.application.exceptions import AgentNotFoundException

router = APIRouter()

# Pydantic models for APIclass CreateTaskApiRequest(BaseModel):
    """API request to create a task."""
    agent_id: str = Field(..., min_length=1, description="Agent to assign task")
    input: Dict[str, Any] = Field(..., description="Task input data")
    parent_task_id: Optional[str] = Field(None, description="Parent task if subtask")

class TaskApiResponse(BaseModel):
    """API response for task."""
    id: str
    conversation_id: str
    agent_id: str
    status: str
    input: Dict[str, Any]
    created_at: str

@router.post(
    "",
    response_model=TaskApiResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new task"
)
async def create_task(
    conversation_id: UUID,
    request: CreateTaskApiRequest,
    use_case: CreateTaskUseCase = Depends(get_create_task_use_case),
) -> TaskApiResponse:
    """Create a new task for a conversation."""
    try:
# Convert API request to application DTO
        app_request = CreateTaskRequest(
            conversation_id=conversation_id,
            agent_id=request.agent_id,
            input=request.input,
            parent_task_id=UUID(request.parent_task_id) if request.parent_task_id else None,
        )

# Execute use case
        result = await use_case.execute(app_request)

# Convert application DTO to API responsereturn TaskApiResponse(
            id=str(result.task.id),
            conversation_id=str(result.task.conversation_id),
            agent_id=result.task.agent_id,
            status=result.task.status,
            input=result.task.input,
            created_at=result.task.created_at.isoformat(),
        )
    except AgentNotFoundException as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Agent not found: {e.agent_id}"
        )

```

---

## **Testing Full Stack**

### **Domain Tests**

```python
# tests/domain/test_entities/test_task.pyimport pytest
from datetime import datetime
from uuid import uuid4

from src.domain.entities import Task
from src.domain.value_objects import TaskStatus

pytestmark = pytest.mark.unit

def test_task_creation():
    """Test task entity creation."""
    task = Task(
        conversation_id=uuid4(),
        agent_id="test_agent",
    )

    assert task.id is not None
    assert task.status == TaskStatus.PENDING

def test_task_requires_conversation_id():
    """Test that task requires conversation_id."""
    with pytest.raises(ValueError, match="conversation_id is required"):
        Task(conversation_id=None, agent_id="test_agent")

def test_task_start():
    """Test starting a task."""
    task = Task(conversation_id=uuid4(), agent_id="test_agent")

    task.start()

    assert task.status == TaskStatus.RUNNING
    assert task.started_at is not None

def test_task_cannot_start_if_not_pending():
    """Test that only pending tasks can be started."""
    task = Task(conversation_id=uuid4(), agent_id="test_agent")
    task.status = TaskStatus.RUNNING

    with pytest.raises(ValueError, match="Can only start pending tasks"):
        task.start()

```

### **Application Tests**

```python
# tests/application/use_cases/test_create_task.pyimport pytest
from unittest.mock import AsyncMock
from uuid import uuid4

from src.application.use_cases.task import CreateTaskUseCase
from src.application.dtos import CreateTaskRequest
from src.application.exceptions import AgentNotFoundException
from tests.factories import TaskFactory, AgentFactory

pytestmark = [pytest.mark.asyncio, pytest.mark.use_case]

@pytest.fixture
def task_repo():
    """Mock task repository."""
    return AsyncMock()

@pytest.fixture
def messaging_gateway():
    """Mock messaging gateway."""
    return AsyncMock()

@pytest.fixture
def agent_repo():
    """Mock agent repository."""
    return AsyncMock()

@pytest.fixture
def use_case(task_repo, messaging_gateway, agent_repo):
    """Create use case with mocked dependencies."""
    return CreateTaskUseCase(
        task_repository=task_repo,
        messaging_gateway=messaging_gateway,
        agent_repository=agent_repo,
    )

class TestCreateTaskUseCase:
    """Tests for CreateTaskUseCase."""

    async def test_create_task_successfully(
        self,
        use_case,
        task_repo,
        messaging_gateway,
        agent_repo,
    ):
        """Test successful task creation."""
# Arrange
        agent = AgentFactory.create(agent_id="test_agent")
        agent_repo.get_by_id.return_value = agent

        task = TaskFactory.create()
        task_repo.create.return_value = task

        request = CreateTaskRequest(
            conversation_id=uuid4(),
            agent_id="test_agent",
            input={"message": "test"},
        )

# Act
        result = await use_case.execute(request)

# Assertassert result.task.id == task.id
        agent_repo.get_by_id.assert_called_once_with("test_agent")
        task_repo.create.assert_called_once()
        messaging_gateway.publish_message.assert_called_once()

    async def test_create_task_agent_not_found(
        self,
        use_case,
        agent_repo,
    ):
        """Test task creation with invalid agent."""
# Arrange
        agent_repo.get_by_id.return_value = None

        request = CreateTaskRequest(
            conversation_id=uuid4(),
            agent_id="nonexistent",
            input={"message": "test"},
        )

# Act & Assertwith pytest.raises(AgentNotFoundException):
            await use_case.execute(request)

```

### **Integration Tests**

```python
# tests/infrastructure/persistence/test_task_repository.pyimport pytest
from uuid import uuid4

from src.domain.entities import Task
from src.domain.value_objects import TaskStatus
from src.infrastructure.persistence.repositories import TaskRepository

pytestmark = [pytest.mark.asyncio, pytest.mark.integration]

async def test_create_task(db_session):
    """Test creating a task in database."""
# Arrange
    repo = TaskRepository(db_session)
    task = Task(
        conversation_id=uuid4(),
        agent_id="test_agent",
        input={"message": "test"},
    )

# Act
    created = await repo.create(task)

# Assertassert created.id is not None
    assert created.status == TaskStatus.PENDING

async def test_find_pending_for_agent(db_session):
    """Test finding pending tasks for agent."""
# Arrange
    repo = TaskRepository(db_session)
    task1 = Task(conversation_id=uuid4(), agent_id="agent1", input={})
    task2 = Task(conversation_id=uuid4(), agent_id="agent1", input={})
    task3 = Task(conversation_id=uuid4(), agent_id="agent2", input={})

    await repo.create(task1)
    await repo.create(task2)
    await repo.create(task3)

# Act
    pending = await repo.find_pending_for_agent("agent1")

# Assertassert len(pending) == 2
    assert all(t.agent_id == "agent1" for t in pending)

```

---

**Related Files:**

- [SKILL.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/SKILL.md) - Main guide
- [clean-architecture.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md) - Architecture overview
- [domain-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/domain-layer.md) - Domain patterns
- [application-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/application-layer.md) - Use case patterns
- [api-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/api-layer.md) - API patterns
- [testing-guide.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/testing-guide.md) - Testing strategies