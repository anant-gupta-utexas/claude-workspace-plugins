# **API Layer - FastAPI Routes and Middleware**

Complete guide to implementing the API layer in Clean Architecture.

## **Table of Contents**

- [Purpose and Rules](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/api-layer.md#purpose-and-rules)
- [FastAPI Routes](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/api-layer.md#fastapi-routes)
- [Request/Response Models](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/api-layer.md#requestresponse-models)
- [Dependency Injection](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/api-layer.md#dependency-injection)
- [Middleware](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/api-layer.md#middleware)
- [Error Handling](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/api-layer.md#error-handling)

---

## **Purpose and Rules**

### **What is the API Layer?**

The **API Layer** is part of the Infrastructure layer, handling HTTP concerns.

**Location**: `src/infrastructure/api/rest/`

**Purpose**:

- Handle HTTP requests/responses
- Validate API input with Pydantic
- Call use cases via dependency injection
- Transform use case results to API responses

**Rules**:

- ✅ Use **Pydantic BaseModel** for API validation
- ✅ Import from Application and Domain layers
- ✅ Call use cases, not repositories directly
- ✅ Handle HTTP-specific concerns (status codes, headers)
- ❌ NO business logic (that's in use cases)

---

## **FastAPI Routes**

### **Route Structure**

```python
# src/infrastructure/api/rest/routes/conversations.pyfrom fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from uuid import UUID
from typing import Optional

from ..dependencies import get_create_conversation_use_case
from src.application.use_cases.conversation import CreateConversationUseCase
from src.application.dtos import CreateConversationRequest
from src.application.exceptions import AgentNotFoundException
from ..auth import get_current_user

router = APIRouter()

# Pydantic models for API layerclass CreateConversationApiRequest(BaseModel):
    """API request model with Pydantic validation."""
    initial_message: str = Field(..., min_length=1, max_length=5000)
    agent_id: Optional[str] = Field(None, description="Optional agent ID")
    metadata: Optional[dict] = Field(default_factory=dict)

class ConversationApiResponse(BaseModel):
    """API response model."""
    id: str
    user_id: str
    agent_id: str
    status: str
    created_at: str

    class Config:
        from_attributes = True

@router.post(
    "",
    response_model=ConversationApiResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new conversation"
)
async def create_conversation(
    request: CreateConversationApiRequest,
    use_case: CreateConversationUseCase = Depends(get_create_conversation_use_case),
    current_user: str = Depends(get_current_user),
) -> ConversationApiResponse:
    """
    Create a new conversation.

    - **initial_message**: First message from user
    - **agent_id**: Optional specific agent (will discover if not provided)
    - **metadata**: Optional metadata dictionary
    """
    try:
# Convert API request to application DTO
        app_request = CreateConversationRequest(
            user_id=current_user,
            initial_message=request.initial_message,
            agent_id=request.agent_id,
        )

# Execute use case
        result = await use_case.execute(app_request)

# Convert application DTO to API responsereturn ConversationApiResponse(
            id=str(result.conversation.id),
            user_id=result.conversation.user_id,
            agent_id=result.primary_agent_id,
            status=result.status,
            created_at=result.conversation.created_at.isoformat(),
        )
    except AgentNotFoundException as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Agent not found: {e.agent_id}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to create conversation"
        )

```

### **Route Best Practices**

**✅ DO:**

- Use Pydantic for validation
- Call use cases via dependencies
- Convert between API models and application DTOs
- Handle application exceptions → HTTP status codes
- Add OpenAPI documentation

**❌ DON'T:**

- Put business logic in routes
- Call repositories directly
- Use application DTOs as API models

---

## **Request/Response Models**

### **Pydantic Models for API**

```python
# API layer uses Pydantic for validationfrom pydantic import BaseModel, Field, EmailStr, validator
from typing import Optional, List
from datetime import datetime

class TaskCreateRequest(BaseModel):
    """API request to create a task."""
    agent_id: str = Field(..., description="Agent to assign task")
    input: dict = Field(..., description="Task input data")
    parent_task_id: Optional[str] = Field(None, description="Parent task if subtask")

    @validator('agent_id')
    def agent_id_not_empty(cls, v):
        if not v or not v.strip():
            raise ValueError('agent_id cannot be empty')
        return v

class TaskResponse(BaseModel):
    """API response for task."""
    id: str
    conversation_id: str
    agent_id: str
    status: str
    input: dict
    output: Optional[dict]
    error: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class TaskListResponse(BaseModel):
    """Paginated task list response."""
    tasks: List[TaskResponse]
    total: int
    page: int
    page_size: int
    has_more: bool

```

### **Converting DTOs to API Models**

```python
from src.application.dtos import TaskDTO

def task_dto_to_response(dto: TaskDTO) -> TaskResponse:
    """Convert application DTO to API response."""
    return TaskResponse(
        id=str(dto.id),
        conversation_id=str(dto.conversation_id),
        agent_id=dto.agent_id,
        status=dto.status,
        input=dto.input,
        output=dto.output,
        error=dto.error,
        created_at=dto.created_at,
    )

```

---

## **Dependency Injection**

### **Dependency Setup**

```python
# src/infrastructure/api/rest/dependencies.pyfrom fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.application.use_cases.conversation import CreateConversationUseCase
from src.application.use_cases.task import CreateTaskUseCase
from src.infrastructure.persistence.repositories import (
    ConversationRepository,
    TaskRepository,
    AgentRepository,
)
from src.infrastructure.messaging.kafka_publisher import KafkaPublisher
from .session import get_session

# Repository dependenciesasync def get_conversation_repository(
    session: AsyncSession = Depends(get_session)
):
    """Get conversation repository."""
    return ConversationRepository(session)

async def get_task_repository(
    session: AsyncSession = Depends(get_session)
):
    """Get task repository."""
    return TaskRepository(session)

async def get_agent_repository(
    session: AsyncSession = Depends(get_session)
):
    """Get agent repository."""
    return AgentRepository(session)

# Messaging dependenciesasync def get_messaging_gateway():
    """Get messaging gateway."""
    return KafkaPublisher()

# Use case dependenciesasync def get_create_conversation_use_case(
    conversation_repo = Depends(get_conversation_repository),
    agent_repo = Depends(get_agent_repository),
    messaging = Depends(get_messaging_gateway),
) -> CreateConversationUseCase:
    """Get create conversation use case with dependencies."""
    return CreateConversationUseCase(
        conversation_repo=conversation_repo,
        agent_repo=agent_repo,
        messaging=messaging,
    )

async def get_create_task_use_case(
    task_repo = Depends(get_task_repository),
    agent_repo = Depends(get_agent_repository),
    messaging = Depends(get_messaging_gateway),
) -> CreateTaskUseCase:
    """Get create task use case with dependencies."""
    return CreateTaskUseCase(
        task_repository=task_repo,
        agent_repository=agent_repo,
        messaging_gateway=messaging,
        time_provider=RealTimeProvider(),
    )

```

---

## **Middleware**

### **Logging Middleware**

```python
# src/infrastructure/api/rest/middleware/logging_middleware.pyimport time
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from src.infrastructure.observability.logger import get_logger

logger = get_logger(__name__)

class LoggingMiddleware(BaseHTTPMiddleware):
    """Log all HTTP requests and responses."""

    async def dispatch(self, request: Request, call_next):
# Start timing
        start_time = time.time()

# Log request
        logger.info(
            "HTTP request received",
            extra={
                "method": request.method,
                "path": request.url.path,
                "client": request.client.host if request.client else None,
            }
        )

# Process request
        response = await call_next(request)

# Calculate duration
        duration = time.time() - start_time

# Log response
        logger.info(
            "HTTP request completed",
            extra={
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "duration_ms": round(duration * 1000, 2),
            }
        )

        return response

```

### **Context Middleware**

```python
# src/infrastructure/api/rest/middleware/context_middleware.pyimport uuid
from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

class ConversationContextMiddleware(BaseHTTPMiddleware):
    """Add request context to all requests."""

    async def dispatch(self, request: Request, call_next):
# Generate request ID
        request_id = str(uuid.uuid4())

# Add to request state
        request.state.request_id = request_id

# Process request
        response = await call_next(request)

# Add to response headers
        response.headers["X-Request-ID"] = request_id

        return response

```

### **Registering Middleware**

```python
# src/infrastructure/api/rest/main.pyfrom fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .middleware.logging_middleware import LoggingMiddleware
from .middleware.context_middleware import ConversationContextMiddleware
from .settings import settings

app = FastAPI(title="Constellation API")

# CORS (should be first)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=settings.CORS_ALLOW_CREDENTIALS,
    allow_methods=settings.CORS_ALLOW_METHODS,
    allow_headers=settings.CORS_ALLOW_HEADERS,
)

# Custom middleware (order matters!)
app.add_middleware(LoggingMiddleware)
app.add_middleware(ConversationContextMiddleware)

```

---

## **Error Handling**

### **Exception Handlers**

```python
# src/infrastructure/api/rest/main.pyfrom fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from src.application.exceptions import (
    ApplicationException,
    AgentNotFoundException,
    TaskNotFoundException,
)
from src.domain.exceptions import DomainException

app = FastAPI()

@app.exception_handler(AgentNotFoundException)
async def agent_not_found_handler(request: Request, exc: AgentNotFoundException):
    """Handle agent not found exceptions."""
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={
            "error": "agent_not_found",
            "detail": str(exc),
            "agent_id": exc.agent_id,
        }
    )

@app.exception_handler(TaskNotFoundException)
async def task_not_found_handler(request: Request, exc: TaskNotFoundException):
    """Handle task not found exceptions."""
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={
            "error": "task_not_found",
            "detail": str(exc),
            "task_id": str(exc.task_id),
        }
    )

@app.exception_handler(ApplicationException)
async def application_exception_handler(request: Request, exc: ApplicationException):
    """Handle generic application exceptions."""
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={
            "error": "application_error",
            "detail": str(exc),
        }
    )

@app.exception_handler(DomainException)
async def domain_exception_handler(request: Request, exc: DomainException):
    """Handle domain exceptions."""
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "domain_error",
            "detail": str(exc),
        }
    )

@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    """Handle all unhandled exceptions."""
    logger.error(
        "Unhandled exception",
        extra={"error": str(exc)},
        exc_info=True
    )
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "internal_server_error",
            "detail": "An unexpected error occurred",
        }
    )

```

### **Error Response Format**

```python
from pydantic import BaseModel

class ErrorResponse(BaseModel):
    """Standard error response."""
    error: str
    detail: str
    field: Optional[str] = None
    value: Optional[Any] = None

# Usage in routes@router.post("/tasks", responses={
    404: {"model": ErrorResponse, "description": "Agent not found"},
    422: {"model": ErrorResponse, "description": "Validation error"},
})
async def create_task(...):
    ...

```

---

## **Best Practices**

### **1. Separate API Models from DTOs**

```python
# ✅ GOOD: Clear separation# API layer (Pydantic)class CreateTaskApiRequest(BaseModel):
    agent_id: str
    input: dict

# Application layer (dataclass)@dataclass
class CreateTaskRequest:
    conversation_id: UUID
    agent_id: str
    input: Dict[str, Any]

# Route converts between themasync def create_task(api_request: CreateTaskApiRequest, ...):
    app_request = CreateTaskRequest(
        conversation_id=conversation_id,
        agent_id=api_request.agent_id,
        input=api_request.input,
    )
    result = await use_case.execute(app_request)

# ❌ BAD: Using application DTOs directlyasync def create_task(request: CreateTaskRequest, ...):# Wrong layer!
    ...

```

### **2. Use Dependency Injection**

```python
# ✅ GOOD: Dependencies injected@router.post("/tasks")
async def create_task(
    use_case: CreateTaskUseCase = Depends(get_create_task_use_case)
):
    return await use_case.execute(request)

# ❌ BAD: Creating instances in route@router.post("/tasks")
async def create_task():
    repo = TaskRepository(session)# Wrong!
    use_case = CreateTaskUseCase(repo)
    ...

```

### **3. Document with OpenAPI**

```python
# ✅ GOOD: Rich documentation@router.post(
    "/conversations",
    response_model=ConversationResponse,
    status_code=201,
    summary="Create a new conversation",
    description="Creates a new conversation with optional agent selection",
    responses={
        201: {"description": "Conversation created successfully"},
        404: {"description": "Agent not found"},
        422: {"description": "Invalid input"},
    }
)
async def create_conversation(...):
    """
    Create a new conversation.

    - **initial_message**: The first message from the user
    - **agent_id**: Optional agent ID (will discover if not provided)
    """
    ...

```

---

**Related Files:**

- [SKILL.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/SKILL.md) - Main guide
- [clean-architecture.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/clean-architecture.md) - Architecture overview
- [application-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/application-layer.md) - Use cases called by routes
- [validation-patterns.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/validation-patterns.md) - Pydantic validation