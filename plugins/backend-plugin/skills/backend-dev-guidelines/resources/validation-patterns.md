# **Validation Patterns - Dataclasses vs Pydantic**

Complete guide to validation patterns across Clean Architecture layers.

## **Table of Contents**

- [Overview](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/validation-patterns.md#overview)
- [Domain Layer Validation](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/validation-patterns.md#domain-layer-validation)
- [Application Layer DTOs](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/validation-patterns.md#application-layer-dtos)
- [Infrastructure API Layer](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/validation-patterns.md#infrastructure-api-layer)
- [When to Use What](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/validation-patterns.md#when-to-use-what)

---

## **Overview**

### **Validation by Layer**

| Layer | Tool | Purpose |
| --- | --- | --- |
| **Domain** | Python validation | Business rule enforcement |
| **Application** | Dataclasses | Simple data transfer |
| **Infrastructure (API)** | **Pydantic** | HTTP request/response validation |

**Key Rule**: Pydantic is ONLY for the API layer (HTTP boundary).

---

## **Domain Layer Validation**

### **Entity Validation**

Domain entities validate **business rules**, not data formats.

```python
# src/domain/entities/task.pyfrom dataclasses import dataclass, field
from datetime import datetime, timezone
from uuid import UUID, uuid4
from ..value_objects import TaskStatus

@dataclass
class Task:
    """
    Task entity with business rule validation.
    """
    id: UUID = field(default_factory=uuid4)
    conversation_id: UUID = field(default=None)
    agent_id: str = field(default="")
    status: TaskStatus = TaskStatus.PENDING

    def __post_init__(self):
        """Validate business rules."""
# Business rule: Task must have conversationif not self.conversation_id:
            raise ValueError("conversation_id is required")

# Business rule: Task must have agentif not self.agent_id:
            raise ValueError("agent_id is required")

    def start(self) -> None:
        """
        Mark task as started.

        Business rule: Can only start pending tasks.
        """
        if self.status != TaskStatus.PENDING:
            raise ValueError(
                f"Can only start pending tasks, current: {self.status}"
            )

        self.status = TaskStatus.RUNNING
        self.started_at = datetime.now(timezone.utc)

```

### **Value Object Validation**

```python
# src/domain/value_objects/agent_metadata.pyfrom dataclasses import dataclass

@dataclass(frozen=True)# Immutableclass AgentMetadata:
    """Agent metadata value object with validation."""
    agent_id: str
    name: str
    capabilities: tuple[str, ...]

    def __post_init__(self):
        """Validate value object."""
        if not self.agent_id:
            raise ValueError("agent_id is required")
        if not self.name:
            raise ValueError("name is required")
        if not self.capabilities:
            raise ValueError("at least one capability required")

# Business rule: agent_id formatif not self.agent_id.isalnum():
            raise ValueError("agent_id must be alphanumeric")

```

**Key Points**:

- ✅ Use Python's built-in validation
- ✅ Validate business rules
- ❌ NO Pydantic
- ❌ NO HTTP concerns

---

## **Application Layer DTOs**

### **Using Dataclasses**

Application DTOs use **dataclasses** for simplicity and performance.

```python
# src/application/dtos/task_dto.pyfrom dataclasses import dataclass
from datetime import datetime
from typing import Dict, Any, Optional
from uuid import UUID

@dataclass
class TaskDTO:
    """
    Data Transfer Object for tasks.

    Simple dataclass - no validation beyond types.
    """
    id: UUID
    conversation_id: UUID
    agent_id: str
    status: str
    input: Dict[str, Any]
    output: Optional[Dict[str, Any]]
    created_at: datetime

    @classmethod
    def from_entity(cls, entity) -> "TaskDTO":
        """Convert domain entity to DTO."""
        return cls(
            id=entity.id,
            conversation_id=entity.conversation_id,
            agent_id=entity.agent_id,
            status=entity.status.value,
            input=entity.input,
            output=entity.output,
            created_at=entity.created_at,
        )

@dataclass
class CreateTaskRequest:
    """Request DTO for creating a task."""
    conversation_id: UUID
    agent_id: str
    input: Dict[str, Any]
    parent_task_id: Optional[UUID] = None

@dataclass
class CreateTaskResponse:
    """Response DTO after creating a task."""
    task: TaskDTO
    status: str

```

### **Why Dataclasses?**

**Benefits**:

- ⚡ Fast (no validation overhead)
- 🎯 Simple (just data structures)
- 🔒 Type-safe (with type hints)
- 📦 Lightweight (standard library)

**Use When**:

- Transferring data between layers
- Internal application boundaries
- No external validation needed

---

## **Infrastructure API Layer**

### **Using Pydantic**

The API layer uses **Pydantic** for HTTP request/response validation.

```python
# src/infrastructure/api/rest/routes/tasks.pyfrom pydantic import BaseModel, Field, validator
from typing import Optional, Dict, Any
from uuid import UUID

class CreateTaskApiRequest(BaseModel):
    """
    API request model with Pydantic validation.

    Validates HTTP input from external clients.
    """
    agent_id: str = Field(
        ...,
        min_length=1,
        max_length=255,
        description="Agent ID to assign task"
    )
    input: Dict[str, Any] = Field(
        ...,
        description="Task input data"
    )
    parent_task_id: Optional[str] = Field(
        None,
        description="Parent task ID if this is a subtask"
    )

    @validator('agent_id')
    def agent_id_not_empty(cls, v):
        """Validate agent_id is not empty or whitespace."""
        if not v or not v.strip():
            raise ValueError('agent_id cannot be empty or whitespace')
        return v.strip()

    @validator('input')
    def input_not_empty(cls, v):
        """Validate input is not empty."""
        if not v:
            raise ValueError('input cannot be empty')
        return v

class TaskApiResponse(BaseModel):
    """API response model."""
    id: str
    conversation_id: str
    agent_id: str
    status: str
    input: Dict[str, Any]
    output: Optional[Dict[str, Any]]
    created_at: str

    class Config:
        from_attributes = True

class TaskListResponse(BaseModel):
    """Paginated list response."""
    tasks: list[TaskApiResponse]
    total: int
    page: int
    page_size: int

```

### **Route with Validation**

```python
from fastapi import APIRouter, Depends, HTTPException, status
from src.application.use_cases.task import CreateTaskUseCase
from src.application.dtos import CreateTaskRequest
from src.application.exceptions import AgentNotFoundException

router = APIRouter()

@router.post(
    "/tasks",
    response_model=TaskApiResponse,
    status_code=status.HTTP_201_CREATED
)
async def create_task(
    request: CreateTaskApiRequest,# Pydantic validates THIS
    conversation_id: UUID,
    use_case: CreateTaskUseCase = Depends(get_create_task_use_case),
):
    """
    Create a new task.

    Pydantic validates the HTTP request automatically.
    """
# Convert API model (Pydantic) to Application DTO (dataclass)
    app_request = CreateTaskRequest(
        conversation_id=conversation_id,
        agent_id=request.agent_id,
        input=request.input,
        parent_task_id=UUID(request.parent_task_id) if request.parent_task_id else None,
    )

# Execute use casetry:
        result = await use_case.execute(app_request)
    except AgentNotFoundException as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Agent not found: {e.agent_id}"
        )

# Convert Application DTO to API response (Pydantic)return TaskApiResponse(
        id=str(result.task.id),
        conversation_id=str(result.task.conversation_id),
        agent_id=result.task.agent_id,
        status=result.task.status,
        input=result.task.input,
        output=result.task.output,
        created_at=result.task.created_at.isoformat(),
    )

```

---

## **When to Use What**

### **Decision Tree**

```
Is this for HTTP API?
├─ YES → Use Pydantic (Infrastructure/API layer)
└─ NO → Is this a domain entity?
    ├─ YES → Use dataclass + __post_init__ validation (Domain)
    └─ NO → Is this transferring data between layers?
        ├─ YES → Use dataclass (Application DTOs)
        └─ NO → Use appropriate data structure

```

### **Comparison Table**

| Aspect | Dataclass | Pydantic |
| --- | --- | --- |
| **Layer** | Domain, Application | Infrastructure (API) |
| **Purpose** | Internal data | HTTP validation |
| **Validation** | Manual (`__post_init__`) | Automatic |
| **Performance** | Fast | Slower (validation overhead) |
| **Type Coercion** | No | Yes |
| **JSON** | Manual | Automatic |
| **When to Use** | Internal boundaries | External API |

### **Examples by Layer**

### **Domain Layer**

```python
# ✅ GOOD: Dataclass with business validation@dataclass
class Conversation:
    id: UUID
    user_id: str

    def __post_init__(self):
        if not self.user_id:
            raise ValueError("user_id is required")

# ❌ BAD: Pydantic in domainclass Conversation(BaseModel):# NO!
    ...

```

### **Application Layer**

```python
# ✅ GOOD: Simple dataclass DTOs@dataclass
class CreateConversationRequest:
    user_id: str
    initial_message: str
    agent_id: Optional[str] = None

# ❌ BAD: Pydantic in application layerclass CreateConversationRequest(BaseModel):# NO!
    ...

```

### **Infrastructure API Layer**

```python
# ✅ GOOD: Pydantic for API validationclass CreateConversationApiRequest(BaseModel):
    initial_message: str = Field(..., min_length=1)
    agent_id: Optional[str] = None

# ❌ BAD: Dataclass for API (no validation)@dataclass
class CreateConversationApiRequest:# Missing validation!
    ...

```

---

## **Advanced Patterns**

### **Custom Validators**

```python
from pydantic import BaseModel, validator, root_validator

class TaskUpdateRequest(BaseModel):
    status: Optional[str]
    output: Optional[Dict[str, Any]]
    error: Optional[str]

    @validator('status')
    def validate_status(cls, v):
        """Validate status is one of allowed values."""
        allowed = ['running', 'completed', 'failed', 'cancelled']
        if v not in allowed:
            raise ValueError(f'status must be one of {allowed}')
        return v

    @root_validator
    def validate_status_output_combination(cls, values):
        """Validate business rules across fields."""
        status = values.get('status')
        output = values.get('output')
        error = values.get('error')

        if status == 'completed' and not output:
            raise ValueError('output required when status is completed')

        if status == 'failed' and not error:
            raise ValueError('error required when status is failed')

        return values

```

### **Generic Response Wrapper**

```python
from typing import Generic, TypeVar, Optional
from pydantic import BaseModel

T = TypeVar('T')

class ApiResponse(BaseModel, Generic[T]):
    """Generic API response wrapper."""
    success: bool
    data: Optional[T]
    error: Optional[str]
    message: Optional[str]

# Usageclass UserData(BaseModel):
    id: str
    name: str

@router.get("/users/{id}")
async def get_user(id: str) -> ApiResponse[UserData]:
    return ApiResponse(
        success=True,
        data=UserData(id=id, name="John"),
        error=None,
        message="User retrieved successfully"
    )

```

### **Nested Validation**

```python
class AddressModel(BaseModel):
    """Nested address model."""
    street: str = Field(..., min_length=1)
    city: str = Field(..., min_length=1)
    country: str = Field(..., min_length=2, max_length=2)

class UserProfileRequest(BaseModel):
    """User profile with nested validation."""
    name: str = Field(..., min_length=1, max_length=100)
    email: EmailStr
    address: AddressModel# Nested validation    @validator('email')
    def email_domain_check(cls, v):
        """Validate email domain."""
        if not v.endswith('@company.com'):
            raise ValueError('must use company email')
        return v

```

---

## **Best Practices**

### **1. Convert at Boundaries**

```python
# ✅ GOOD: Convert between API and Application layers@router.post("/tasks")
async def create_task(
    api_request: TaskApiRequest,# Pydantic (API layer)
    use_case: CreateTaskUseCase = Depends(...)
):
# Convert Pydantic → Dataclass
    app_request = CreateTaskRequest(
        agent_id=api_request.agent_id,
        input=api_request.input,
    )

# Use case returns dataclass
    result = await use_case.execute(app_request)

# Convert Dataclass → Pydanticreturn TaskApiResponse(
        id=str(result.task.id),
        status=result.task.status,
    )

```

### **2. Keep Validation Appropriate**

```python
# ✅ GOOD: API validates format, Domain validates business rulesclass CreateTaskApiRequest(BaseModel):
    agent_id: str = Field(..., min_length=1)# Format validation# Domain validates business rules@dataclass
class Task:
    agent_id: str

    def __post_init__(self):
        if not self.agent_id:
            raise ValueError("agent_id required")# Business rule# ❌ BAD: Business rules in API modelclass CreateTaskApiRequest(BaseModel):
    @validator('agent_id')
    def check_agent_exists(cls, v):
# Database call in validator! Wrong layer!if not agent_repo.exists(v):
            raise ValueError("agent not found")
        return v

```

### **3. Don't Mix Concerns**

```python
# ✅ GOOD: Clear separation# API layerclass UserApiRequest(BaseModel):
    email: EmailStr# Format validation# Application layer@dataclass
class CreateUserRequest:
    email: str# Just data# Domain layer@dataclass
class User:
    email: str

    def __post_init__(self):
        if '@' not in self.email:# Business ruleraise ValueError("invalid email")

# ❌ BAD: Using API model in use caseclass CreateUserUseCase:
    async def execute(self, request: UserApiRequest):# Wrong!# Should use application DTO, not API model
        ...

```

---

**Related Files:**

- [SKILL.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/SKILL.md) - Main guide
- [clean-architecture.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md) - Layer separation
- [domain-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/domain-layer.md) - Domain validation
- [application-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/application-layer.md) - Application DTOs
- [api-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/api-layer.md) - Pydantic for API