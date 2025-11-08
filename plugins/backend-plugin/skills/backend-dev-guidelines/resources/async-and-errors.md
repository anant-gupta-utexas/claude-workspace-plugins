# **Async Patterns and Error Handling**

Complete guide to async/await patterns and custom error handling in Python/FastAPI.

## **Table of Contents**

- [Async/Await Best Practices](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/async-and-errors.md#asyncawait-best-practices)
- [Concurrent Operations](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/async-and-errors.md#concurrent-operations)
- [Custom Error Types](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/async-and-errors.md#custom-error-types)
- [Error Propagation](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/async-and-errors.md#error-propagation)
- [Common Async Pitfalls](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/async-and-errors.md#common-async-pitfalls)
- [Context Managers](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/async-and-errors.md#context-managers)

---

## **Async/Await Best Practices**

### **Always Use Try-Except with Async**

```python
# ❌ NEVER: Unhandled async errorsasync def fetch_data():
    data = await database.query()# If throws, unhandled!return data

# ✅ ALWAYS: Wrap in try-exceptasync def fetch_data():
    try:
        data = await database.query()
        return data
    except Exception as e:
        capture_exception(e)
        raise

```

### **Proper Async Function Definition**

```python
# ✅ Async functionasync def get_user(user_id: int) -> User:
    user = await db.execute(select(User).where(User.id == user_id))
    return user.scalar_one_or_none()

# ✅ Calling async function
user = await get_user(123)

# ❌ Calling async function without await
user = get_user(123)# Returns coroutine, not User!
```

### **Async with FastAPI Routes**

```python
from fastapi import APIRouter

router = APIRouter()

# ✅ Async route handler@router.get("/users/{user_id}")
async def get_user(user_id: int) -> UserResponse:
    user = await user_service.get_user(user_id)
    return user

# ✅ Sync route handler (if no async operations)@router.get("/health")
def health_check():
    return {"status": "ok"}

```

---

## **Concurrent Operations**

### **Parallel Operations with asyncio.gather**

```python
import asyncio

# ✅ Run operations in parallelasync def get_user_dashboard(user_id: int):
# All run concurrently
    user, posts, comments = await asyncio.gather(
        user_repo.find_by_id(user_id),
        post_repo.find_by_user(user_id),
        comment_repo.find_by_user(user_id),
    )

    return {
        "user": user,
        "posts": posts,
        "comments": comments,
    }

# ❌ Sequential operations (slower)async def get_user_dashboard_slow(user_id: int):
    user = await user_repo.find_by_id(user_id)
    posts = await post_repo.find_by_user(user_id)
    comments = await comment_repo.find_by_user(user_id)
    return {"user": user, "posts": posts, "comments": comments}

```

### **Error Handling with asyncio.gather**

```python
# ✅ Handle errors in gatherasync def fetch_multiple_resources():
    try:
        results = await asyncio.gather(
            fetch_users(),
            fetch_posts(),
            fetch_comments(),
            return_exceptions=False,# Raise first exception
        )
        return results
    except Exception as e:
        capture_exception(e)
        raise

# ✅ Continue on errors with return_exceptions=Trueasync def fetch_with_fallback():
    results = await asyncio.gather(
        fetch_users(),
        fetch_posts(),
        fetch_comments(),
        return_exceptions=True,# Returns exceptions instead of raising
    )

# Process resultsfor i, result in enumerate(results):
        if isinstance(result, Exception):
            capture_exception(result)
            print(f"Operation {i} failed: {result}")
        else:
            print(f"Operation {i} succeeded")

    return [r for r in results if not isinstance(r, Exception)]

```

### **Timeout Control**

```python
import asyncio

async def fetch_with_timeout(url: str, timeout: float = 5.0):
    """Fetch with timeout protection."""
    try:
        async with asyncio.timeout(timeout):
            response = await http_client.get(url)
            return response
    except asyncio.TimeoutError:
        capture_message(f"Request to {url} timed out after {timeout}s")
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail="Request timed out",
        )

```

### **Background Tasks**

```python
from fastapi import BackgroundTasks

@router.post("/users")
async def create_user(
    user_data: UserCreate,
    background_tasks: BackgroundTasks,
):
# Create user
    user = await user_service.create_user(user_data)

# Send welcome email in background
    background_tasks.add_task(send_welcome_email, user.email)

# Log analytics in background
    background_tasks.add_task(log_user_creation, user.id)

    return user

async def send_welcome_email(email: str):
    """Background task to send welcome email."""
    try:
        await email_service.send(email, "Welcome!")
    except Exception as e:
        capture_exception(e)

```

---

## **Custom Error Types**

### **Define Custom Exceptions**

**File:** `app/core/exceptions.py`

```python
from fastapi import HTTPException, status

class AppException(Exception):
    """Base exception for application errors."""

    def __init__(self, message: str, status_code: int = 500):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)

class NotFoundError(AppException):
    """Resource not found exception."""

    def __init__(self, message: str = "Resource not found"):
        super().__init__(message, status_code=status.HTTP_404_NOT_FOUND)

class ConflictError(AppException):
    """Resource conflict exception."""

    def __init__(self, message: str = "Resource already exists"):
        super().__init__(message, status_code=status.HTTP_409_CONFLICT)

class ValidationError(AppException):
    """Validation error exception."""

    def __init__(self, message: str = "Validation failed"):
        super().__init__(message, status_code=status.HTTP_400_BAD_REQUEST)

class ForbiddenError(AppException):
    """Permission denied exception."""

    def __init__(self, message: str = "Permission denied"):
        super().__init__(message, status_code=status.HTTP_403_FORBIDDEN)

class UnauthorizedError(AppException):
    """Authentication required exception."""

    def __init__(self, message: str = "Authentication required"):
        super().__init__(message, status_code=status.HTTP_401_UNAUTHORIZED)

```

### **Usage**

```python
from app.core.exceptions import NotFoundError, ConflictError

class UserService:
    async def get_user(self, user_id: int) -> User:
        user = await self.repository.find_by_id(user_id)

        if not user:
            raise NotFoundError(f"User with id {user_id} not found")

        return user

    async def create_user(self, data: UserCreate) -> User:
# Check if email exists
        existing = await self.repository.find_by_email(data.email)

        if existing:
            raise ConflictError("Email already registered")

        return await self.repository.create(data)

```

### **Global Exception Handler**

```python
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from opentelemetry import trace
from opentelemetry.trace import Status, StatusCode
from app.core.exceptions import AppException
import logging

logger = logging.getLogger(__name__)
app = FastAPI()

@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    """Handle custom application exceptions."""
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.message},
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle all unhandled exceptions."""
# Record exception in trace
    span = trace.get_current_span()
    span.record_exception(exc)
    span.set_status(Status(StatusCode.ERROR, str(exc)))
    span_context = span.get_span_context()

# Log error
    logger.error(
        "Unhandled exception",
        extra={
            "error": str(exc),
            "trace_id": format(span_context.trace_id, '032x'),
        },
        exc_info=True
    )

    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "trace_id": format(span_context.trace_id, '032x'),
        },
    )

```

---

## **Error Propagation**

### **Proper Error Chains**

```python
# ✅ Propagate errors up the stackclass UserRepository:
    async def create(self, data: UserCreate) -> User:
        try:
            user = User(**data.model_dump())
            self.db.add(user)
            await self.db.commit()
            return user
        except IntegrityError as e:
            await self.db.rollback()
            capture_exception(e)
            raise ConflictError("Email already exists")
        except Exception as e:
            await self.db.rollback()
            capture_exception(e)
            raise

class UserService:
    async def create_user(self, data: UserCreate) -> User:
        try:
            return await self.repository.create(data)
        except ConflictError:
# Let it propagate to routerraise
        except Exception as e:
            capture_exception(e)
            raise

@router.post("/users")
async def create_user(user_data: UserCreate):
    try:
        user = await user_service.create_user(user_data)
        return user
    except ConflictError as e:
# FastAPI converts to proper HTTP responseraise HTTPException(status_code=409, detail=str(e))

```

---

## **Common Async Pitfalls**

### **Fire and Forget (Bad)**

```python
# ❌ NEVER: Fire and forgetasync def process_request(request_data):
# Fires async, errors unhandled!
    asyncio.create_task(send_notification(request_data))
    return {"status": "ok"}

# ✅ ALWAYS: Await or handle with background tasksfrom fastapi import BackgroundTasks

async def process_request(request_data, background_tasks: BackgroundTasks):
# Use FastAPI background tasks
    background_tasks.add_task(send_notification, request_data)
    return {"status": "ok"}

# ✅ OR: Explicit error handlingasync def process_request(request_data):
    async def safe_send():
        try:
            await send_notification(request_data)
        except Exception as e:
            capture_exception(e)

    asyncio.create_task(safe_send())
    return {"status": "ok"}

```

### **Blocking Operations in Async Code**

```python
import asyncio
from concurrent.futures import ThreadPoolExecutor

# ❌ NEVER: Blocking call in async functionasync def bad_function():
# This blocks the event loop!
    result = time.sleep(5)
    return result

# ✅ Use asyncio.sleep for async delayasync def good_async_function():
    await asyncio.sleep(5)
    return "done"

# ✅ Run blocking code in thread poolasync def good_blocking_function():
    loop = asyncio.get_event_loop()
    result = await loop.run_in_executor(
        None,# Use default executor
        blocking_operation,
    )
    return result

def blocking_operation():
    """CPU-intensive or I/O blocking operation."""
    time.sleep(5)
    return "done"

```

### **Not Awaiting Coroutines**

```python
# ❌ WRONG: Not awaiting coroutineasync def bad():
    user = get_user(123)# Returns coroutine, not User!print(user.name)# AttributeError!# ✅ CORRECT: Await coroutineasync def good():
    user = await get_user(123)
    print(user.name)

```

---

## **Context Managers**

### **Async Context Managers**

```python
# ✅ Async context manager for resource managementclass DatabaseConnection:
    async def __aenter__(self):
        self.conn = await create_connection()
        return self.conn

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.conn.close()

# Usageasync def query_database():
    async with DatabaseConnection() as conn:
        result = await conn.execute("SELECT * FROM users")
        return result

```

### **Transaction Context Manager**

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def transaction(db: AsyncSession):
    """Context manager for database transactions."""
    try:
        async with db.begin():
            yield db
# Commit happens automaticallyexcept Exception as e:
        await db.rollback()
        capture_exception(e)
        raise

# Usageasync def transfer_funds(from_id: int, to_id: int, amount: float):
    async with transaction(db) as session:
# Deduct from sender
        sender = await session.get(Account, from_id)
        sender.balance -= amount

# Add to recipient
        recipient = await session.get(Account, to_id)
        recipient.balance += amount

# Commit happens automatically at end of context
```

### **Timing Context Manager**

```python
from contextlib import asynccontextmanager
import time

@asynccontextmanager
async def timing(operation: str):
    """Context manager to time async operations."""
    start = time.time()
    try:
        yield
    finally:
        duration = time.time() - start
        print(f"{operation} took {duration:.2f}s")

# Log to monitoringif duration > 1.0:
            capture_message(
                f"Slow operation: {operation} took {duration:.2f}s",
                level="warning",
            )

# Usageasync def fetch_data():
    async with timing("fetch_user_data"):
        users = await db.execute(select(User))
        return users.scalars().all()

```

---

**Related Files:**

- [SKILL.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/SKILL.md) - Main guide
- [observability.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/observability.md) - OpenTelemetry error tracking
- [application-layer.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/application-layer.md) - Async in use cases
- [complete-examples.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/complete-examples.md) - Full async examples