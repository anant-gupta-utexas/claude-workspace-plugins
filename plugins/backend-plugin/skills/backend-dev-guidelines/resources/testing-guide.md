# **Testing Guide - pytest with Clean Architecture**

Complete guide to testing Python/FastAPI Clean Architecture projects with pytest.

## **Table of Contents**

- [Testing Setup](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/testing-guide.md#testing-setup)
- [pytest Custom Markers](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/testing-guide.md#pytest-custom-markers)
- [Domain Layer Tests](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/testing-guide.md#domain-layer-tests)
- [Application Layer Tests](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/testing-guide.md#application-layer-tests)
- [Infrastructure Layer Tests](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/testing-guide.md#infrastructure-layer-tests)
- [Integration Tests](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/testing-guide.md#integration-tests)
- [Testing Async Code](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/testing-guide.md#testing-async-code)
- [Fixtures and Mocking](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/testing-guide.md#fixtures-and-mocking)
- [Coverage and Best Practices](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/testing-guide.md#coverage-and-best-practices)

---

## **Testing Setup**

### **Install Testing Dependencies**

```bash
# Using uv
uv add --group test pytest pytest-asyncio pytest-mock pytest-cov

# Or add to pyproject.toml dependency group
[dependency-groups]
test = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "pytest-mock>=3.12.0",
    "pytest-cov>=4.1.0",
]

```

### **pytest Configuration**

**File:** `pytest.ini`

```
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
asyncio_mode = auto
pythonpath = . src
addopts =
    --verbose
    --color=yes
    --cov=src
    --cov-report=html
    --cov-report=term-missing
    --strict-markers
markers =
    unit: Domain unit tests (pure logic, no mocks)
    use_case: Application use case tests
    service: Application service tests
    integration: Infrastructure integration tests
    workflow: End-to-end workflow tests
env_files =
    .env.test
filterwarnings =
    ignore::DeprecationWarning

```

### **Test Directory Structure**

```
tests/
├── __init__.py
├── conftest.py                          # Shared fixtures
├── domain/                              # Domain tests (unit marker)
│   ├── __init__.py
│   ├── test_entities/
│   │   ├── test_conversation.py
│   │   └── test_task.py
│   └── test_services/
│       └── test_conversation_state_machine.py
├── application/                         # Application tests
│   ├── __init__.py
│   ├── use_cases/                      # use_case marker
│   │   ├── test_create_conversation.py
│   │   └── test_create_task.py
│   └── services/                       # service marker
│       └── test_orchestrator_service.py
├── infrastructure/                      # Infrastructure tests (integration marker)
│   ├── __init__.py
│   ├── persistence/
│   │   └── test_task_repository.py
│   └── api/
│       └── test_conversations_routes.py
├── integration/                         # E2E tests (workflow marker)
│   ├── __init__.py
│   └── workflows/
│       ├── test_conversation_lifecycle.py
│       └── test_delegation_workflow.py
├── factories/                           # Test factories
│   ├── __init__.py
│   └── entity_factories.py
└── mocks/                              # Mock implementations
    ├── __init__.py
    └── mock_repositories.py

```

---

## **pytest Custom Markers**

### **Available Markers**

| Marker | Purpose | No Mocks? | Fast? |
| --- | --- | --- | --- |
| `@pytest.mark.unit` | Domain tests | ✅ | ✅ |
| `@pytest.mark.use_case` | Use case tests | ❌ | ✅ |
| `@pytest.mark.service` | Service tests | ❌ | ✅ |
| `@pytest.mark.integration` | Infrastructure tests | ❌ | ❌ |
| `@pytest.mark.workflow` | E2E tests | ❌ | ❌ |

### **Running Tests by Marker**

```bash
# Run only domain tests (fast, no mocks)
pytest -m unit

# Run application layer tests
pytest -m "use_case or service"

# Run everything except slow integration tests
pytest -m "not integration and not workflow"

# Run only fast tests (unit + use_case)
pytest -m "unit or use_case"

# Run with coverage
pytest -m "unit or use_case" --cov=src/domain --cov=src/application

```

### **Using Markers in Tests**

```python
import pytest

# Single marker@pytest.mark.unit
def test_conversation_creation():
    ...

# Multiple markers
pytestmark = [pytest.mark.asyncio, pytest.mark.use_case]

class TestCreateConversationUseCase:
    async def test_success(self):
        ...

```

---

## **Domain Layer Tests**

### **Pure Domain Tests (NO MOCKS)**

Domain tests are **pure unit tests** - no mocks, no infrastructure, just business logic.

**File:** `tests/domain/test_entities/test_conversation.py`

```python
import pytest
from datetime import datetime
from uuid import uuid4

from src.domain.entities import Conversation
from src.domain.value_objects import ConversationStatus, ConversationPhase

# Mark as unit test
pytestmark = pytest.mark.unit

def test_conversation_creation():
    """Test conversation entity creation."""
    conversation = Conversation(user_id="user123")

    assert conversation.id is not None
    assert conversation.user_id == "user123"
    assert conversation.status == ConversationStatus.ACTIVE

def test_conversation_requires_user_id():
    """Test that conversation requires user_id."""
    with pytest.raises(ValueError, match="user_id is required"):
        Conversation(user_id="")

def test_conversation_phase_transition():
    """Test valid phase transition."""
    conversation = Conversation(user_id="user123")

    conversation.transition_phase(ConversationPhase.REQUIREMENTS_GATHERING)

    assert conversation.phase == ConversationPhase.REQUIREMENTS_GATHERING

def test_conversation_invalid_phase_transition():
    """Test invalid phase transition."""
    conversation = Conversation(user_id="user123")
    conversation.phase = ConversationPhase.EXECUTION

    with pytest.raises(ValueError, match="Invalid"):
        conversation.transition_phase(ConversationPhase.REQUIREMENTS_GATHERING)

```

---

## **Application Layer Tests**

### **Use Case Tests (WITH MOCKS)**

Use case tests mock infrastructure dependencies.

**File:** `tests/application/use_cases/test_create_conversation.py`

```python
import pytest
from unittest.mock import AsyncMock
from uuid import uuid4

from src.application.use_cases.conversation import CreateConversationUseCase
from src.application.dtos import CreateConversationRequest
from src.application.exceptions import AgentNotFoundException
from tests.factories import ConversationFactory, AgentFactory

# Mark as use case test
pytestmark = [pytest.mark.asyncio, pytest.mark.use_case]

@pytest.fixture
def conversation_repo():
    """Mock conversation repository."""
    return AsyncMock()

@pytest.fixture
def agent_repo():
    """Mock agent repository."""
    return AsyncMock()

@pytest.fixture
def messaging_gateway():
    """Mock messaging gateway."""
    return AsyncMock()

@pytest.fixture
def use_case(conversation_repo, agent_repo, messaging_gateway):
    """Create use case with mocked dependencies."""
    return CreateConversationUseCase(
        conversation_repo=conversation_repo,
        agent_repo=agent_repo,
        messaging=messaging_gateway,
    )

class TestCreateConversationUseCase:
    """Tests for CreateConversationUseCase."""

    async def test_create_conversation_successfully(
        self,
        use_case,
        conversation_repo,
        agent_repo,
        messaging_gateway,
    ):
        """Test successful conversation creation."""
# Arrange
        agent = AgentFactory.create(agent_id="test_agent")
        agent_repo.get_by_id.return_value = agent

        conversation = ConversationFactory.create()
        conversation_repo.create.return_value = conversation

        request = CreateConversationRequest(
            user_id="user123",
            initial_message="Hello",
            agent_id="test_agent",
        )

# Act
        result = await use_case.execute(request)

# Assertassert result.conversation.id == conversation.id
        agent_repo.get_by_id.assert_called_once_with("test_agent")
        conversation_repo.create.assert_called_once()
        messaging_gateway.publish_message.assert_called_once()

    async def test_create_conversation_agent_not_found(
        self,
        use_case,
        agent_repo,
    ):
        """Test conversation creation with invalid agent."""
# Arrange
        agent_repo.get_by_id.return_value = None

        request = CreateConversationRequest(
            user_id="user123",
            initial_message="Hello",
            agent_id="nonexistent",
        )

# Act & Assertwith pytest.raises(AgentNotFoundException):
            await use_case.execute(request)

@pytest.fixture
def user_service(mock_repository):
    """Create user service with mocked repository."""
    return UserService(mock_repository)

@pytest.fixture
def sample_user_create():
    """Sample user creation data."""
    return UserCreate(
        email="test@example.com",
        name="Test User",
        age=25,
    )

@pytest.fixture
def sample_user():
    """Sample user model."""
    return User(
        id=1,
        email="test@example.com",
        name="Test User",
        age=25,
        is_active=True,
    )

class TestUserService:
    """Tests for UserService."""

    @pytest.mark.asyncio
    async def test_create_user_success(
        self,
        user_service,
        mock_repository,
        sample_user_create,
        sample_user,
    ):
        """Test successful user creation."""
# Arrange
        mock_repository.find_by_email.return_value = None
        mock_repository.create.return_value = sample_user

# Act
        result = await user_service.create_user(sample_user_create)

# Assertassert result.id == sample_user.id
        assert result.email == sample_user_create.email
        mock_repository.find_by_email.assert_called_once_with(
            sample_user_create.email
        )
        mock_repository.create.assert_called_once()

    @pytest.mark.asyncio
    async def test_create_user_duplicate_email(
        self,
        user_service,
        mock_repository,
        sample_user_create,
        sample_user,
    ):
        """Test user creation with duplicate email."""
# Arrange
        mock_repository.find_by_email.return_value = sample_user

# Act & Assertwith pytest.raises(HTTPException) as exc_info:
            await user_service.create_user(sample_user_create)

        assert exc_info.value.status_code == 409
        assert "already registered" in exc_info.value.detail.lower()
        mock_repository.create.assert_not_called()

    @pytest.mark.asyncio
    async def test_create_user_underage(
        self,
        user_service,
        mock_repository,
    ):
        """Test user creation with age < 18."""
# Arrange
        user_data = UserCreate(
            email="young@example.com",
            name="Young User",
            age=16,
        )
        mock_repository.find_by_email.return_value = None

# Act & Assertwith pytest.raises(HTTPException) as exc_info:
            await user_service.create_user(user_data)

        assert exc_info.value.status_code == 400
        assert "18 or older" in exc_info.value.detail.lower()

    @pytest.mark.asyncio
    async def test_get_user_success(
        self,
        user_service,
        mock_repository,
        sample_user,
    ):
        """Test successful user retrieval."""
# Arrange
        mock_repository.find_by_id.return_value = sample_user

# Act
        result = await user_service.get_user(1)

# Assertassert result.id == sample_user.id
        assert result.email == sample_user.email
        mock_repository.find_by_id.assert_called_once_with(1)

    @pytest.mark.asyncio
    async def test_get_user_not_found(
        self,
        user_service,
        mock_repository,
    ):
        """Test user retrieval when user doesn't exist."""
# Arrange
        mock_repository.find_by_id.return_value = None

# Act & Assertwith pytest.raises(HTTPException) as exc_info:
            await user_service.get_user(999)

        assert exc_info.value.status_code == 404

```

---

## **Integration Testing**

### **API Endpoint Testing**

**File:** `tests/integration/test_api/test_users.py`

```python
import pytest
from httpx import AsyncClient
from app.main import app
from app.core.database import Base, engine
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from app.models.user import User

# Test database URL
TEST_DATABASE_URL = "postgresql+asyncpg://test:test@localhost/test_db"

@pytest.fixture
async def test_db():
    """Create test database."""
    test_engine = create_async_engine(TEST_DATABASE_URL, echo=True)

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)

    yield test_engine

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await test_engine.dispose()

@pytest.fixture
async def client(test_db):
    """Create test client."""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.fixture
async def auth_headers():
    """Create authorization headers."""
    token = create_test_token()
    return {"Authorization": f"Bearer {token}"}

class TestUserAPI:
    """Integration tests for user API."""

    @pytest.mark.asyncio
    async def test_create_user(self, client):
        """Test user creation endpoint."""
# Arrange
        user_data = {
            "email": "test@example.com",
            "name": "Test User",
            "age": 25,
        }

# Act
        response = await client.post("/api/v1/users", json=user_data)

# Assertassert response.status_code == 201
        data = response.json()
        assert data["email"] == user_data["email"]
        assert data["name"] == user_data["name"]
        assert "id" in data

    @pytest.mark.asyncio
    async def test_get_user(self, client):
        """Test get user endpoint."""
# Arrange - Create user first
        user_data = {"email": "test@example.com", "name": "Test", "age": 25}
        create_response = await client.post("/api/v1/users", json=user_data)
        user_id = create_response.json()["id"]

# Act
        response = await client.get(f"/api/v1/users/{user_id}")

# Assertassert response.status_code == 200
        data = response.json()
        assert data["id"] == user_id
        assert data["email"] == user_data["email"]

    @pytest.mark.asyncio
    async def test_get_user_not_found(self, client):
        """Test get user when user doesn't exist."""
# Act
        response = await client.get("/api/v1/users/999")

# Assertassert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_list_users(self, client):
        """Test list users endpoint."""
# Arrange - Create multiple users
        users = [
            {"email": f"user{i}@example.com", "name": f"User {i}", "age": 25}
            for i in range(3)
        ]
        for user in users:
            await client.post("/api/v1/users", json=user)

# Act
        response = await client.get("/api/v1/users")

# Assertassert response.status_code == 200
        data = response.json()
        assert len(data) == 3

    @pytest.mark.asyncio
    async def test_update_user(self, client, auth_headers):
        """Test update user endpoint."""
# Arrange
        user_data = {"email": "test@example.com", "name": "Test", "age": 25}
        create_response = await client.post("/api/v1/users", json=user_data)
        user_id = create_response.json()["id"]

        update_data = {"name": "Updated Name"}

# Act
        response = await client.put(
            f"/api/v1/users/{user_id}",
            json=update_data,
            headers=auth_headers,
        )

# Assertassert response.status_code == 200
        data = response.json()
        assert data["name"] == update_data["name"]
        assert data["email"] == user_data["email"]# Unchanged
```

---

## **Testing Async Code**

### **pytest-asyncio Configuration**

```python
import pytest
import asyncio

# Mark all tests as async
pytestmark = pytest.mark.asyncio

async def test_async_operation():
    """Test async operation."""
    result = await some_async_function()
    assert result is not None

async def test_async_with_timeout():
    """Test async operation with timeout."""
    async with asyncio.timeout(5):
        result = await slow_async_function()
        assert result is not None

```

---

## **Fixtures and Mocking**

### **Shared Fixtures**

**File:** `tests/conftest.py`

```python
import pytest
from unittest.mock import AsyncMock
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from app.core.database import Base
from app.core.config import Settings

@pytest.fixture
def test_settings():
    """Test settings."""
    return Settings(
        environment="testing",
        database_url="postgresql+asyncpg://test:test@localhost/test_db",
        secret_key="test-secret-key-for-testing",
        debug=True,
        otel_traces_enabled=False,
    )

@pytest.fixture
async def db_session():
    """Create database session for testing."""
    engine = create_async_engine(
        "postgresql+asyncpg://test:test@localhost/test_db",
        echo=True,
    )

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSession(engine) as session:
        yield session

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

    await engine.dispose()

@pytest.fixture
def mock_db_session():
    """Mock database session."""
    session = AsyncMock(spec=AsyncSession)
    return session

```

### **Mocking External Services**

```python
from unittest.mock import patch, AsyncMock

@pytest.mark.asyncio
@patch('app.services.email_service.send_email')
async def test_user_creation_sends_email(mock_send_email, user_service):
    """Test that user creation sends welcome email."""
# Arrange
    mock_send_email.return_value = True
    user_data = UserCreate(email="test@example.com", name="Test", age=25)

# Act
    user = await user_service.create_user(user_data)

# Assert
    mock_send_email.assert_called_once_with(
        to=user.email,
        subject="Welcome!",
    )

```

---

## **Testing Database Operations**

### **Repository Testing**

```python
import pytest
from app.repositories.user_repository import UserRepository
from app.schemas.user import UserCreate
from app.models.user import User

@pytest.mark.asyncio
async def test_repository_create(db_session):
    """Test repository create operation."""
# Arrange
    repository = UserRepository(db_session)
    user_data = UserCreate(
        email="test@example.com",
        name="Test User",
        age=25,
    )

# Act
    user = await repository.create(user_data)

# Assertassert user.id is not None
    assert user.email == user_data.email
    assert user.name == user_data.name

@pytest.mark.asyncio
async def test_repository_find_by_email(db_session):
    """Test repository find by email."""
# Arrange
    repository = UserRepository(db_session)
    user_data = UserCreate(email="test@example.com", name="Test", age=25)
    created_user = await repository.create(user_data)

# Act
    found_user = await repository.find_by_email("test@example.com")

# Assertassert found_user is not None
    assert found_user.id == created_user.id
    assert found_user.email == created_user.email

```

---

## **Coverage and Best Practices**

### **Run Tests with Coverage**

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/unit/test_services/test_user_service.py

# Run specific test
pytest tests/unit/test_services/test_user_service.py::TestUserService::test_create_user_success

# Run with markers
pytest -m unit# Only unit tests
pytest -m integration# Only integration tests
pytest -m "not slow"# Exclude slow tests
```

### **Coverage Targets**

- **Unit Tests**: 80%+ coverage
- **Integration Tests**: Critical paths covered
- **Overall**: 70%+ coverage

### **Test Best Practices**

```python
# ✅ GOOD: Descriptive test namesasync def test_create_user_with_duplicate_email_returns_409():
    ...

# ❌ BAD: Vague test namesasync def test_user():
    ...

# ✅ GOOD: Arrange, Act, Assert patternasync def test_something():
# Arrange
    user_data = UserCreate(...)

# Act
    result = await service.create_user(user_data)

# Assertassert result.id is not None

# ✅ GOOD: One assertion per test (when possible)async def test_user_email():
    user = await service.create_user(data)
    assert user.email == data.email

async def test_user_name():
    user = await service.create_user(data)
    assert user.name == data.name

```

---

**Related Files:**

- [SKILL.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/SKILL.md) - Main guide
- [services-and-repositories.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/services-and-repositories.md) - Testing services
- [database-patterns.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/database-patterns.md) - Testing repositories
- [complete-examples.md](https://file+.vscode-resource.vscode-cdn.net/Users/a0g0noy/PycharmProjects/constellation/backend-python-dev-guidelines/resources/complete-examples.md) - Full test examples