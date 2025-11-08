# **Domain Layer - Pure Business Logic**

Complete guide to implementing the Domain Layer in Clean Architecture.

## **Table of Contents**

- [Purpose and Rules](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/domain-layer.md#purpose-and-rules)
- [Entities](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/domain-layer.md#entities)
- [Value Objects](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/domain-layer.md#value-objects)
- [Domain Services](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/domain-layer.md#domain-services)
- [Interfaces (Ports)](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/domain-layer.md#interfaces-ports)
- [Domain Exceptions](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/domain-layer.md#domain-exceptions)

---

## **Purpose and Rules**

### **What is the Domain Layer?**

The **Domain Layer** contains pure business logic with **zero external dependencies**.

**Location**: `src/domain/`

**Rules**:

- ✅ Only standard library imports
- ✅ Pure Python (dataclasses, enums, typing)
- ✅ Only imports from other domain modules
- ❌ **NO** FastAPI, SQLAlchemy, Pydantic, or any framework
- ❌ **NO** imports from application/ or infrastructure/

### **Why Zero Dependencies?**

- **Testability**: Test business logic without infrastructure
- **Portability**: Move to different framework/database
- **Clarity**: Business rules are explicit and isolated
- **Speed**: Pure Python is fast to test

---

## **Entities**

### **What is an Entity?**

An **Entity** is an object with:

- **Identity** (unique ID)
- **Business behavior** (methods that enforce rules)
- **Mutable state** (can change over time)

### **Entity Template**

```python
# src/domain/entities/conversation.pyfrom dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Dict, Any, Optional
from uuid import UUID, uuid4

from ..value_objects import ConversationStatus, ConversationPhase

@dataclass
class Conversation:
    """
    Conversation entity representing a user interaction session.

    Business Rules:
    - Must have a user_id
    - Phase transitions must follow valid workflow
    - Status transitions must follow valid lifecycle
    """

# Identityid: UUID = field(default_factory=uuid4)

# Required fields
    user_id: str = field(default="")

# State
    status: ConversationStatus = ConversationStatus.ACTIVE
    phase: ConversationPhase = ConversationPhase.NONE

# Optional associations
    agent_id: Optional[str] = None
    current_agent: Optional[str] = None

# Metadata
    message_count: int = 0
    metadata: Dict[str, Any] = field(default_factory=dict)

# Timestamps
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    updated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def __post_init__(self):
        """Validate entity after initialization."""
        if not self.user_id:
            raise ValueError("user_id is required")

    def assign_primary_agent(self, agent_id: str) -> None:
        """
        Assign the primary agent for this conversation.

        Business Rule: agent_id cannot be empty
        """
        if not agent_id:
            raise ValueError("agent_id cannot be empty")

        self.agent_id = agent_id
        self.current_agent = agent_id
        self.updated_at = datetime.now(timezone.utc)

    def transition_phase(self, new_phase: ConversationPhase) -> None:
        """
        Transition to a new conversation phase.

        Business Rule: Phase transitions must be valid
        """
        if not self._is_valid_phase_transition(self.phase, new_phase):
            raise ValueError(f"Invalid phase transition: {self.phase} -> {new_phase}")

        self.phase = new_phase
        self.updated_at = datetime.now(timezone.utc)

    def increment_message_count(self) -> None:
        """Increment the message counter."""
        self.message_count += 1
        self.updated_at = datetime.now(timezone.utc)

    def _is_valid_phase_transition(self, from_phase: ConversationPhase, to_phase: ConversationPhase) -> bool:
        """
        Check if phase transition is valid.

        Valid transitions:
        - NONE -> any phase
        - Any phase -> COMPLETE
        - Specific workflow transitions
        """
        if from_phase == ConversationPhase.NONE:
            return True
        if to_phase == ConversationPhase.COMPLETE:
            return True

# Define valid workflow transitions
        valid_transitions = {
            ConversationPhase.REQUIREMENTS_GATHERING: [
                ConversationPhase.PLANNING,
            ],
            ConversationPhase.PLANNING: [
                ConversationPhase.EXECUTION,
            ],
            ConversationPhase.EXECUTION: [
                ConversationPhase.REVIEW,
            ],
        }

        allowed = valid_transitions.get(from_phase, [])
        return to_phase in allowed

```

### **Entity Best Practices**

**✅ DO:**

- Use `@dataclass` for simplicity
- Add `__post_init__` for validation
- Use type hints for all fields
- Use `field(default_factory=...)` for mutable defaults
- Create methods that enforce business rules
- Make private helper methods for validation

**❌ DON'T:**

- Import from application/ or infrastructure/
- Use SQLAlchemy or Pydantic
- Include database concerns
- Include HTTP concerns

---

## **Value Objects**

### **What is a Value Object?**

A **Value Object** is an immutable object defined by its attributes (no identity).

**Characteristics**:

- Immutable
- Equality based on values
- Often implemented as Enum

### **Value Object Examples**

```python
# src/domain/value_objects/conversation_status.pyfrom enum import Enum

class ConversationStatus(str, Enum):
    """Conversation lifecycle status."""

    ACTIVE = "active"
    PAUSED = "paused"
    COMPLETE = "complete"
    ARCHIVED = "archived"

    @classmethod
    def from_string(cls, value: str) -> "ConversationStatus":
        """Convert string to enum."""
        try:
            return cls(value)
        except ValueError:
            raise ValueError(f"Invalid conversation status: {value}")

    def is_terminal(self) -> bool:
        """Check if this is a terminal status."""
        return self in {self.COMPLETE, self.ARCHIVED}

```

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

    def can_transition_to(self, new_status: "TaskStatus") -> bool:
        """Check if transition to new status is valid."""
        valid_transitions = {
            self.PENDING: {self.RUNNING, self.CANCELLED},
            self.RUNNING: {
                self.COMPLETED,
                self.FAILED,
                self.WAITING_FOR_USER,
                self.WAITING_FOR_SUBTASK,
            },
            self.WAITING_FOR_USER: {self.RUNNING, self.CANCELLED},
            self.WAITING_FOR_SUBTASK: {self.RUNNING, self.FAILED},
        }

        allowed = valid_transitions.get(self, set())
        return new_status in allowed

```

### **Complex Value Objects**

```python
# src/domain/value_objects/agent_metadata.pyfrom dataclasses import dataclass
from typing import List, Dict, Any

@dataclass(frozen=True)# Immutableclass AgentMetadata:
    """
    Immutable metadata describing an agent's capabilities.

    Value Object: Defined by its values, not identity.
    """
    agent_id: str
    name: str
    description: str
    capabilities: tuple[str, ...]# Use tuple for immutability
    agent_type: str
    client_facing: bool
    endpoint: str
    protocol: str
    version: str
    tags: tuple[str, ...]

    def __post_init__(self):
        """Validate metadata."""
        if not self.agent_id:
            raise ValueError("agent_id is required")
        if not self.name:
            raise ValueError("name is required")
        if not self.capabilities:
            raise ValueError("at least one capability required")

    def has_capability(self, capability: str) -> bool:
        """Check if agent has specific capability."""
        return capability in self.capabilities

    def matches_tags(self, required_tags: List[str]) -> bool:
        """Check if agent matches all required tags."""
        return all(tag in self.tags for tag in required_tags)

```

---

## **Domain Services**

### **What is a Domain Service?**

A **Domain Service** contains business logic that:

- Doesn't naturally fit in a single entity
- Operates on multiple entities
- Implements domain-wide rules

### **Domain Service Example**

```python
# src/domain/services/conversation_state_machine.pyfrom typing import Optional
from ..entities import Conversation
from ..value_objects import ConversationPhase, ConversationStatus

class ConversationStateMachine:
    """
    Domain service for managing conversation state transitions.

    Business Rules:
    - Enforce valid phase transitions
    - Enforce valid status transitions
    - Initialize conversations correctly
    """

    @staticmethod
    def start_conversation(user_id: str, agent_id: str) -> Conversation:
        """
        Start a new conversation with initial state.

        Business Rules:
        - New conversations start in ACTIVE status
        - Phase starts as NONE
        - Agent is assigned immediately
        """
        conversation = Conversation(
            user_id=user_id,
            agent_id=agent_id,
            current_agent=agent_id,
            status=ConversationStatus.ACTIVE,
            phase=ConversationPhase.NONE,
        )
        return conversation

    @staticmethod
    def can_pause(conversation: Conversation) -> bool:
        """Check if conversation can be paused."""
        return (
            conversation.status == ConversationStatus.ACTIVE
            and conversation.phase not in {ConversationPhase.COMPLETE}
        )

    @staticmethod
    def pause(conversation: Conversation) -> None:
        """
        Pause a conversation.

        Business Rule: Can only pause active conversations
        """
        if not ConversationStateMachine.can_pause(conversation):
            raise ValueError(
                f"Cannot pause conversation in status={conversation.status}, "
                f"phase={conversation.phase}"
            )

        conversation.status = ConversationStatus.PAUSED
        conversation.updated_at = datetime.now(timezone.utc)

    @staticmethod
    def resume(conversation: Conversation) -> None:
        """
        Resume a paused conversation.

        Business Rule: Can only resume paused conversations
        """
        if conversation.status != ConversationStatus.PAUSED:
            raise ValueError(
                f"Cannot resume conversation in status={conversation.status}"
            )

        conversation.status = ConversationStatus.ACTIVE
        conversation.updated_at = datetime.now(timezone.utc)

    @staticmethod
    def complete(conversation: Conversation) -> None:
        """
        Complete a conversation.

        Business Rule: Can complete from any active state
        """
        if conversation.status not in {ConversationStatus.ACTIVE, ConversationStatus.PAUSED}:
            raise ValueError(
                f"Cannot complete conversation in status={conversation.status}"
            )

        conversation.status = ConversationStatus.COMPLETE
        conversation.phase = ConversationPhase.COMPLETE
        conversation.updated_at = datetime.now(timezone.utc)

```

---

## **Interfaces (Ports)**

### **What are Interfaces?**

**Interfaces** (Ports) define contracts for infrastructure to implement.

**Purpose**:

- Define what the domain needs from infrastructure
- Enable dependency inversion
- Allow infrastructure to be swapped

### **Interface Examples**

```python
# src/domain/interfaces/repositories.pyfrom abc import ABC, abstractmethod
from typing import List, Optional
from uuid import UUID

from ..entities import Conversation, Task

class IConversationRepository(ABC):
    """Interface for conversation persistence."""

    @abstractmethod
    async def create(self, conversation: Conversation) -> Conversation:
        """Create a new conversation."""
        pass

    @abstractmethod
    async def get_by_id(self, conversation_id: UUID) -> Optional[Conversation]:
        """Get conversation by ID."""
        pass

    @abstractmethod
    async def update(self, conversation: Conversation) -> Conversation:
        """Update an existing conversation."""
        pass

    @abstractmethod
    async def find_active_for_user(self, user_id: str) -> List[Conversation]:
        """Find all active conversations for a user."""
        pass

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

```python
# src/domain/interfaces/gateways.pyfrom abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Dict, Any, Optional

@dataclass
class AgentRequest:
    """Request to invoke an agent."""
    agent_id: str
    task_id: str
    input: Dict[str, Any]
    context: Dict[str, Any]

@dataclass
class AgentResponse:
    """Response from agent invocation."""
    status: str
    output: Optional[Dict[str, Any]]
    expects_user_input: bool
    hitl_checkpoint: Optional[Dict[str, Any]]
    error: Optional[str]

class IAgentGateway(ABC):
    """Interface for agent invocation."""

    @abstractmethod
    async def invoke(self, request: AgentRequest) -> AgentResponse:
        """Invoke an agent with request."""
        pass

```

---

## **Domain Exceptions**

### **Custom Exceptions**

```python
# src/domain/exceptions/domain_exceptions.pyfrom typing import Optional
from uuid import UUID

class DomainException(Exception):
    """Base exception for all domain errors."""
    pass

class EntityNotFoundError(DomainException):
    """Raised when an entity is not found."""

    def __init__(self, entity_type: str, entity_id: UUID):
        self.entity_type = entity_type
        self.entity_id = entity_id
        super().__init__(f"{entity_type} not found: {entity_id}")

class InvalidStateTransitionError(DomainException):
    """Raised when attempting an invalid state transition."""

    def __init__(self, message: str, current_state: Optional[str] = None):
        self.current_state = current_state
        super().__init__(message)

class BusinessRuleViolationError(DomainException):
    """Raised when a business rule is violated."""

    def __init__(self, rule: str, details: Optional[str] = None):
        self.rule = rule
        self.details = details
        message = f"Business rule violated: {rule}"
        if details:
            message += f" - {details}"
        super().__init__(message)

```

---

**Related Files:**

- [SKILL.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/SKILL.md) - Main guide
- [clean-architecture.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md) - Architecture overview
- [application-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/application-layer.md) - Application layer details
- [repository-pattern.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/repository-pattern.md) - Implementing repositories