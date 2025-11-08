# **Repository Pattern - Generic Base Repository**

Complete guide to implementing the Repository pattern with generics in Clean Architecture.

## **Table of Contents**

- [Purpose and Rules](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/repository-pattern.md#purpose-and-rules)
- [Generic Base Repository](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/repository-pattern.md#generic-base-repository)
- [Concrete Repository](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/repository-pattern.md#concrete-repository)
- [ORM Models](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/repository-pattern.md#orm-models)
- [Repository Factory](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/repository-pattern.md#repository-factory)
- [Best Practices](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/repository-pattern.md#best-practices)

---

## **Purpose and Rules**

### **What is the Repository Pattern?**

The **Repository Pattern** abstracts data access, separating domain logic from persistence concerns.

**Location**: `src/infrastructure/persistence/repositories/`

**Purpose**:

- Implement domain repository interfaces
- Convert between domain entities and ORM models
- Handle database operations
- Provide a clean abstraction over SQLAlchemy

**Rules**:

- ✅ Implements domain `I*Repository` interfaces
- ✅ Uses SQLAlchemy for database access
- ✅ Converts ORM models ↔ domain entities
- ❌ No business logic (that's domain layer)

---

## **Generic Base Repository**

### **Why Generic Base Repository?**

- **Type Safety**: TypeVar ensures correct types
- **Code Reuse**: Common CRUD operations
- **Consistency**: All repositories follow same pattern
- **Less Boilerplate**: Write less code

### **Implementation**

```python
# src/infrastructure/persistence/repositories/base_repository.pyimport logging
from typing import Generic, TypeVar, Optional, List, Type
from uuid import UUID

from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import SQLAlchemyError, IntegrityError

from src.domain.exceptions import (
    EntityNotFoundError,
    EntityAlreadyExistsError,
)

logger = logging.getLogger(__name__)

# Type variables for generic repository
TModel = TypeVar('TModel')# SQLAlchemy ORM model type
TEntity = TypeVar('TEntity')# Domain entity typeclass BaseRepository(Generic[TModel, TEntity]):
    """
    Generic base repository providing common CRUD operations.

    Type Parameters:
        TModel: SQLAlchemy model class
        TEntity: Domain entity class

    Usage:
        class ConversationRepository(
            BaseRepository[ConversationModel, Conversation],
            IConversationRepository
        ):
            ...
    """

    def __init__(
        self,
        session: AsyncSession,
        model_class: Type[TModel],
        entity_name: str
    ):
        """
        Initialize base repository.

        Args:
            session: Async database session
            model_class: SQLAlchemy model class
            entity_name: Human-readable name for errors
        """
        self.session = session
        self.model_class = model_class
        self.entity_name = entity_name

    async def _get_by_id(self, entity_id: UUID) -> Optional[TModel]:
        """
        Get model by ID.

        Args:
            entity_id: Entity UUID

        Returns:
            Model instance or None
        """
        try:
            result = await self.session.get(self.model_class, entity_id)
            return result
        except SQLAlchemyError as e:
            logger.error(f"Error getting {self.entity_name} by ID {entity_id}: {e}")
            raise

    async def _create(self, model: TModel) -> TModel:
        """
        Create model in database.

        Args:
            model: SQLAlchemy model instance

        Returns:
            Created model with ID
        """
        try:
            self.session.add(model)
            await self.session.commit()
            await self.session.refresh(model)
            return model
        except IntegrityError as e:
            await self.session.rollback()
            logger.error(f"Integrity error creating {self.entity_name}: {e}")
            raise EntityAlreadyExistsError(
                self.entity_name,
                "Entity with these attributes already exists"
            )
        except SQLAlchemyError as e:
            await self.session.rollback()
            logger.error(f"Error creating {self.entity_name}: {e}")
            raise

    async def _update(self, model: TModel) -> TModel:
        """
        Update model in database.

        Args:
            model: SQLAlchemy model instance

        Returns:
            Updated model
        """
        try:
            await self.session.commit()
            await self.session.refresh(model)
            return model
        except SQLAlchemyError as e:
            await self.session.rollback()
            logger.error(f"Error updating {self.entity_name}: {e}")
            raise

    async def _delete(self, entity_id: UUID) -> bool:
        """
        Delete model by ID.

        Args:
            entity_id: Entity UUID

        Returns:
            True if deleted, False if not found
        """
        try:
            result = await self.session.execute(
                delete(self.model_class).where(self.model_class.id == entity_id)
            )
            await self.session.commit()
            return result.rowcount > 0
        except SQLAlchemyError as e:
            await self.session.rollback()
            logger.error(f"Error deleting {self.entity_name} {entity_id}: {e}")
            raise

    async def _find_many(
        self,
        filters: Optional[dict] = None,
        limit: int = 100,
        offset: int = 0
    ) -> List[TModel]:
        """
        Find many models with filters.

        Args:
            filters: Dictionary of field: value filters
            limit: Maximum results
            offset: Offset for pagination

        Returns:
            List of models
        """
        try:
            query = select(self.model_class)

            if filters:
                for field, value in filters.items():
                    query = query.where(getattr(self.model_class, field) == value)

            query = query.limit(limit).offset(offset)

            result = await self.session.execute(query)
            return list(result.scalars().all())
        except SQLAlchemyError as e:
            logger.error(f"Error finding {self.entity_name}: {e}")
            raise

# Abstract methods for concrete repositoriesdef _to_entity(self, model: TModel) -> TEntity:
        """
        Convert ORM model to domain entity.

        Must be implemented by concrete repository.
        """
        raise NotImplementedError

    def _to_model(self, entity: TEntity) -> TModel:
        """
        Convert domain entity to ORM model.

        Must be implemented by concrete repository.
        """
        raise NotImplementedError

```

---

## **Concrete Repository**

### **Implementation Example**

```python
# src/infrastructure/persistence/repositories/task_repository.pyimport logging
from typing import Optional, List
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.domain.entities import Task
from src.domain.interfaces import ITaskRepository
from src.domain.value_objects import TaskStatus
from src.domain.exceptions import EntityNotFoundError
from ..models import TaskModel
from .base_repository import BaseRepository

logger = logging.getLogger(__name__)

class TaskRepository(
    BaseRepository[TaskModel, Task],
    ITaskRepository
):
    """
    Repository for task persistence.

    Implements:
    - BaseRepository for common CRUD
    - ITaskRepository domain interface
    """

    def __init__(self, session: AsyncSession):
        """Initialize task repository."""
        super().__init__(session, TaskModel, "Task")

# Conversion methods (required by BaseRepository)def _to_entity(self, model: TaskModel) -> Task:
        """Convert SQLAlchemy model to domain entity."""
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
        """Convert domain entity to SQLAlchemy model."""
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

# Domain interface implementationasync def create(self, task: Task) -> Task:
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
# Get existing model
        existing = await self._get_by_id(task.id)
        if not existing:
            raise EntityNotFoundError("Task", task.id)

# Update fields
        existing.status = task.status.value
        existing.output = task.output
        existing.error = task.error
        existing.started_at = task.started_at
        existing.completed_at = task.completed_at
        existing.updated_at = task.updated_at

# Save
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

    async def get_subtasks(self, parent_task_id: UUID) -> List[Task]:
        """Get all subtasks of a parent task."""
        query = select(TaskModel).where(
            TaskModel.parent_task_id == parent_task_id
        ).order_by(TaskModel.created_at)

        result = await self.session.execute(query)
        models = list(result.scalars().all())
        return [self._to_entity(model) for model in models]

```

---

## **ORM Models**

### **SQLAlchemy Model**

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

# Primary keyid: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)

# Foreign keys
    conversation_id: Mapped[UUID] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE")
    )
    parent_task_id: Mapped[Optional[UUID]] = mapped_column(
        ForeignKey("tasks.id", ondelete="SET NULL"),
        nullable=True
    )

# Fields
    agent_id: Mapped[str] = mapped_column(String(255), nullable=False)
    status: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    input: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSON, nullable=True)
    output: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSON, nullable=True)
    error: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    metadata_: Mapped[Optional[Dict[str, Any]]] = mapped_column(
        "metadata",# Column name in DB
        JSON,
        nullable=True
    )

# Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
    )
    started_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )
    completed_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc)
    )

    def __repr__(self) -> str:
        return f"<TaskModel(id={self.id}, status={self.status})>"

```

---

## **Repository Factory**

### **Factory Pattern**

```python
# src/infrastructure/persistence/repository_factory.pyfrom sqlalchemy.ext.asyncio import AsyncSession

from src.domain.interfaces import (
    IConversationRepository,
    ITaskRepository,
    IAgentRepository,
)
from .repositories import (
    ConversationRepository,
    TaskRepository,
    AgentRepository,
)

class RepositoryFactory:
    """Factory for creating repository instances."""

    def __init__(self, session: AsyncSession):
        self.session = session

    def create_conversation_repository(self) -> IConversationRepository:
        """Create conversation repository."""
        return ConversationRepository(self.session)

    def create_task_repository(self) -> ITaskRepository:
        """Create task repository."""
        return TaskRepository(self.session)

    def create_agent_repository(self) -> IAgentRepository:
        """Create agent repository."""
        return AgentRepository(self.session)

# Convenience functionsdef create_task_repository(session: AsyncSession) -> ITaskRepository:
    """Create task repository directly."""
    return TaskRepository(session)

```

---

## **Best Practices**

### **1. Always Use Generic Base**

```python
# ✅ GOOD: Inherit from generic baseclass TaskRepository(
    BaseRepository[TaskModel, Task],
    ITaskRepository
):
    ...

# ❌ BAD: Duplicate CRUD operationsclass TaskRepository(ITaskRepository):
    async def create(self, task):
# Duplicate code from other repos
        ...

```

### **2. Implement Required Conversions**

```python
# ✅ GOOD: Clear conversion methodsdef _to_entity(self, model: TaskModel) -> Task:
    """Convert model to entity."""
    return Task(
        id=model.id,
        status=TaskStatus.from_string(model.status),
        ...
    )

# ❌ BAD: No conversion, mixing concernsdef get_by_id(self, task_id: UUID) -> TaskModel:# Returns model!
    ...

```

### **3. Handle Errors Properly**

```python
# ✅ GOOD: Proper error handlingtry:
    model = await self._create(model)
except IntegrityError:
    raise EntityAlreadyExistsError(...)

# ❌ BAD: Silent failures
model = await self._create(model)# What if it fails?
```

---

## **Database Session Management**

### **Session Setup**

```python
# src/infrastructure/persistence/session.pyfrom sqlalchemy.ext.asyncio import (
    create_async_engine,
    AsyncSession,
    async_sessionmaker,
    AsyncEngine,
)
from typing import AsyncGenerator

_engine: AsyncEngine | None = None
_session_factory: async_sessionmaker[AsyncSession] | None = None

def create_engine(url: str, echo: bool = False) -> AsyncEngine:
    """Create async database engine."""
    return create_async_engine(
        url,
        echo=echo,
        pool_pre_ping=True,
        pool_size=10,
        max_overflow=20,
    )

def init_engine(url: str, echo: bool = False) -> None:
    """Initialize global engine and session factory."""
    global _engine, _session_factory

    _engine = create_engine(url, echo)
    _session_factory = async_sessionmaker(
        _engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )

async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency to get database session."""
    if _session_factory is None:
        raise RuntimeError("Database not initialized. Call init_engine() first.")

    async with _session_factory() as session:
        try:
            yield session
        finally:
            await session.close()

```

### **Usage in FastAPI**

```python
# src/infrastructure/api/rest/dependencies.pyfrom fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from src.infrastructure.persistence.session import get_session

async def get_task_repository(
    session: AsyncSession = Depends(get_session)
):
    """Get task repository with session."""
    return TaskRepository(session)

```

---

## **Query Optimization**

### **Eager Loading (Avoid N+1)**

```python
from sqlalchemy.orm import selectinload, joinedload

# ❌ BAD: N+1 queriesasync def get_conversations_with_tasks(self, user_id: str):
    conversations = await self.find_by_user(user_id)# 1 queryfor conv in conversations:
        tasks = await self.task_repo.find_by_conversation(conv.id)# N queries!# ✅ GOOD: Single query with eager loadingasync def find_with_tasks(self, user_id: str):
    query = select(ConversationModel).where(
        ConversationModel.user_id == user_id
    ).options(
        selectinload(ConversationModel.tasks)# Load tasks in single query
    )

    result = await self.session.execute(query)
    models = list(result.scalars().all())
    return [self._to_entity(m) for m in models]

```

### **Complex Filtering**

```python
from sqlalchemy import and_, or_, func

async def search_tasks(
    self,
    conversation_id: UUID,
    agent_id: Optional[str] = None,
    status: Optional[str] = None,
    search_term: Optional[str] = None,
) -> List[Task]:
    """Search tasks with multiple filters."""
    query = select(TaskModel)

# Required filter
    conditions = [TaskModel.conversation_id == conversation_id]

# Optional filtersif agent_id:
        conditions.append(TaskModel.agent_id == agent_id)

    if status:
        conditions.append(TaskModel.status == status)

    if search_term:
# Search in JSON input field
        conditions.append(
            func.cast(TaskModel.input, String).ilike(f"%{search_term}%")
        )

    query = query.where(and_(*conditions))
    query = query.order_by(TaskModel.created_at.desc())

    result = await self.session.execute(query)
    models = list(result.scalars().all())
    return [self._to_entity(m) for m in models]

```

### **Pagination**

```python
async def find_paginated(
    self,
    page: int = 1,
    page_size: int = 50,
    filters: Optional[dict] = None
) -> tuple[List[Task], int]:
    """Find tasks with pagination."""
# Build query
    query = select(TaskModel)

    if filters:
        for field, value in filters.items():
            query = query.where(getattr(TaskModel, field) == value)

# Count total
    count_query = select(func.count()).select_from(query.subquery())
    total = await self.session.scalar(count_query)

# Apply pagination
    offset = (page - 1) * page_size
    query = query.offset(offset).limit(page_size)

# Execute
    result = await self.session.execute(query)
    models = list(result.scalars().all())
    tasks = [self._to_entity(m) for m in models]

    return tasks, total

```

---

## **Transaction Patterns**

### **Automatic Transactions**

```python
# BaseRepository._create already handles transactionsasync def create(self, task: Task) -> Task:
    """Create with automatic transaction."""
    model = self._to_model(task)
    created_model = await self._create(model)# Commits automaticallyreturn self._to_entity(created_model)

```

### **Manual Transaction Control**

```python
async def create_conversation_with_task(
    self,
    conversation: Conversation,
    task: Task,
) -> tuple[Conversation, Task]:
    """Create conversation and task in single transaction."""
    try:
        async with self.session.begin():
# Create conversation
            conv_model = self._to_model(conversation)
            self.session.add(conv_model)
            await self.session.flush()# Get ID without committing# Create task with conversation_id
            task.conversation_id = conv_model.id
            task_model = self._to_model(task)
            self.session.add(task_model)

# Commit happens automatically at end of 'async with'# Refresh to get latest dataawait self.session.refresh(conv_model)
        await self.session.refresh(task_model)

        return (
            self._to_entity(conv_model),
            self._to_entity(task_model)
        )
    except Exception as e:
# Rollback happens automatically
        logger.error(f"Transaction failed: {e}")
        raise

```

---

## **Migrations with Alembic**

### **Setup**

```bash
# Add to dependency group
uv add --group persistence alembic

# Initialize alembic
alembic init alembic

```

### **Configuration**

```python
# alembic/env.pyfrom src.infrastructure.persistence.models import Base
from src.infrastructure.api.rest.settings import settings

# Set database URL
config.set_main_option("sqlalchemy.url", str(settings.DATABASE_URL))

# Set target metadata
target_metadata = Base.metadata

```

### **Create Migrations**

```bash
# Auto-generate from models
alembic revision --autogenerate -m "Create tasks table"

# Run migrations
alembic upgrade head

# Rollback
alembic downgrade -1

# Check current version
alembic current

```

---

**Related Files:**

- [SKILL.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/SKILL.md) - Main guide
- [clean-architecture.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md) - Architecture overview
- [domain-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/domain-layer.md) - Domain interfaces
- [application-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/application-layer.md) - Using repositories