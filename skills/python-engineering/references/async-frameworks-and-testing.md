# Async Patterns, Frameworks, and Testing

## Table of Contents

- [Async Patterns](#async-patterns)
  - [Structured Concurrency with TaskGroup](#structured-concurrency-with-taskgroup)
  - [Resilient Concurrent Fetching](#resilient-concurrent-fetching)
  - [Async Context Managers](#async-context-managers)
  - [Async Generators and Streaming](#async-generators-and-streaming)
  - [Rate Limiting with Semaphore](#rate-limiting-with-semaphore)
  - [Timeout Handling](#timeout-handling)
- [Structured Logging with structlog](#structured-logging-with-structlog)
- [FastAPI Modern Patterns](#fastapi-modern-patterns)
  - [Lifespan Events](#lifespan-events)
  - [Annotated Dependencies](#annotated-dependencies)
  - [Query Parameter Validation](#query-parameter-validation)
- [SQLAlchemy 2.0 Patterns](#sqlalchemy-20-patterns)
- [Testing with pytest](#testing-with-pytest)
  - [Fixtures](#fixtures)
  - [Parametrize with IDs and Marks](#parametrize-with-ids-and-marks)
  - [Async Tests](#async-tests)
  - [Mocking External Services](#mocking-external-services)
  - [Factory Fixtures](#factory-fixtures)
  - [Fixture Scopes](#fixture-scopes)
  - [monkeypatch](#monkeypatch)
  - [capsys and tmp_path](#capsys-and-tmp_path)

---

## Async Patterns

### Structured Concurrency with TaskGroup

```python
import asyncio
from contextlib import asynccontextmanager
from collections.abc import AsyncIterator

# Structured concurrency with TaskGroup (3.11+)
async def fetch_all(urls: list[str]) -> list[Response]:
    results: list[Response] = []
    async with asyncio.TaskGroup() as tg:
        for url in urls:
            tg.create_task(fetch_one(url, results))
    return results
# NOTE: If ANY task raises, TaskGroup cancels remaining tasks and raises
# ExceptionGroup containing all exceptions. Handle with except*:
```

### Resilient Concurrent Fetching

```python
async def fetch_resilient(urls: list[str]) -> tuple[list[Response], list[Exception]]:
    """Fetch all URLs, collecting both successes and failures."""
    results: list[Response] = []
    errors: list[Exception] = []
    try:
        async with asyncio.TaskGroup() as tg:
            for url in urls:
                tg.create_task(fetch_one(url, results))
    except* httpx.HTTPStatusError as eg:
        errors.extend(eg.exceptions)    # Collect HTTP errors
    except* httpx.ConnectError as eg:
        errors.extend(eg.exceptions)    # Collect connection errors
    return results, errors
```

### Async Context Managers

```python
@asynccontextmanager
async def get_db_session() -> AsyncIterator[AsyncSession]:
    session = AsyncSession(engine)
    try:
        yield session
        await session.commit()
    except Exception:
        await session.rollback()
        raise
    finally:
        await session.close()
```

### Async Generators and Streaming

```python
async def stream_records(query: str) -> AsyncIterator[Record]:
    async with get_db_session() as session:
        result = await session.stream(text(query))
        async for row in result:
            yield Record.model_validate(row)
```

### Rate Limiting with Semaphore

```python
sem = asyncio.Semaphore(10)  # Max 10 concurrent

async def rate_limited_fetch(url: str) -> Response:
    async with sem:
        return await httpx.get(url)
```

### Timeout Handling

```python
async def fetch_with_timeout(url: str) -> Response:
    async with asyncio.timeout(5.0):  # 3.11+
        return await httpx.get(url)
```

---

## Structured Logging with structlog

```python
import structlog

# Configure structlog once at application startup
structlog.configure(
    processors=[
        structlog.contextvars.merge_contextvars,       # Merge context vars (request_id, etc.)
        structlog.processors.add_log_level,
        structlog.processors.StackInfoRenderer(),
        structlog.dev.set_exc_info,
        structlog.processors.TimeStamper(fmt="iso"),
        # Dev: colorized console output. Prod: JSON lines.
        structlog.dev.ConsoleRenderer()
        if settings.debug
        else structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(settings.log_level),
    context_class=dict,
    logger_factory=structlog.PrintLoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Usage — structured key-value pairs, not format strings
logger.info("user.created", user_id=user.id, email=user.email)
logger.warning("rate_limit.exceeded", ip=request.client.host, limit=100)
logger.error("payment.failed", order_id=order.id, provider="stripe", exc_info=True)

# Bind context for all subsequent log calls (e.g., in middleware)
structlog.contextvars.clear_contextvars()
structlog.contextvars.bind_contextvars(request_id=request_id, user_id=user_id)

# Now all logs in this request context include request_id and user_id automatically
logger.info("order.placed", order_id="abc-123")
# => {"event": "order.placed", "order_id": "abc-123", "request_id": "...", "user_id": "..."}
```

---

## FastAPI Modern Patterns

### Lifespan Events

```python
from contextlib import asynccontextmanager
from typing import Annotated
from collections.abc import AsyncIterator
from fastapi import Depends, FastAPI, Query

# --- Lifespan events (replaces @app.on_event("startup") / "shutdown") ---
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    # Startup: initialize resources
    app.state.db_pool = await create_pool(settings.database_url)
    app.state.redis = await aioredis.from_url(settings.redis_url)
    logger.info("startup.complete")
    yield
    # Shutdown: cleanup resources
    await app.state.db_pool.close()
    await app.state.redis.close()
    logger.info("shutdown.complete")

app = FastAPI(lifespan=lifespan)
```

### Annotated Dependencies

```python
# --- Annotated dependencies (preferred over default param style) ---
async def get_db(request: Request) -> AsyncSession:
    async with AsyncSession(request.app.state.db_pool) as session:
        yield session

async def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    user = await authenticate(token, db)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user

# Reusable type aliases for common dependencies
type DB = Annotated[AsyncSession, Depends(get_db)]
type CurrentUser = Annotated[User, Depends(get_current_user)]

@app.get("/users/me")
async def read_current_user(user: CurrentUser, db: DB) -> UserResponse:
    return UserResponse.model_validate(user)
```

### Query Parameter Validation

```python
@app.get("/items")
async def list_items(
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    db: DB,
) -> list[ItemResponse]:
    return await item_repo.list(db, skip=skip, limit=limit)
```

---

## SQLAlchemy 2.0 Patterns

```python
from sqlalchemy import String, select, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, Session
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

class Base(DeclarativeBase):
    pass

class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(254), unique=True)
    name: Mapped[str] = mapped_column(String(100))
    is_active: Mapped[bool] = mapped_column(default=True)

# Query patterns (2.0 style — select() not query())
async def get_active_users(session: AsyncSession) -> list[User]:
    result = await session.execute(
        select(User).where(User.is_active == True).order_by(User.name)
    )
    return list(result.scalars().all())

async def count_by_domain(session: AsyncSession) -> list[tuple[str, int]]:
    result = await session.execute(
        select(
            func.split_part(User.email, '@', 2).label('domain'),
            func.count().label('count')
        )
        .group_by('domain')
        .order_by(func.count().desc())
    )
    return list(result.all())
```

---

## Testing with pytest

### Fixtures

```python
import pytest
from unittest.mock import AsyncMock, patch

@pytest.fixture
def user_data() -> dict[str, Any]:
    return {"email": "test@example.com", "name": "Test User", "role": "user"}

@pytest.fixture
async def db_session():
    async with get_test_db() as session:
        yield session
        await session.rollback()
```

### Parametrize with IDs and Marks

```python
@pytest.mark.parametrize("email,valid", [
    pytest.param("user@example.com", True, id="standard-email"),
    pytest.param("invalid-email", False, id="no-at-sign"),
    pytest.param("", False, id="empty-string"),
    pytest.param("a@b.c", True, id="minimal-valid"),
    pytest.param("a" * 255 + "@b.c", False, id="too-long", marks=pytest.mark.slow),
])
def test_email_validation(email: str, valid: bool) -> None:
    if valid:
        user = UserCreate(email=email, name="Test", age=25)
        assert user.email == email.lower()
    else:
        with pytest.raises(ValidationError):
            UserCreate(email=email, name="Test", age=25)
```

### Async Tests

```python
@pytest.mark.asyncio
async def test_create_user(db_session: AsyncSession) -> None:
    repo = UserRepository(db_session)
    user = await repo.create(UserCreate(email="new@test.com", name="New", age=25))
    assert user.id is not None
    assert user.email == "new@test.com"
```

### Mocking External Services

```python
async def test_send_notification() -> None:
    mock_client = AsyncMock()
    mock_client.post.return_value = Response(status_code=200)

    service = NotificationService(client=mock_client)
    await service.send("user_123", "Hello")

    mock_client.post.assert_called_once()
```

### Factory Fixtures

```python
@pytest.fixture
def make_user():
    def _make(
        email: str = "test@example.com",
        name: str = "Test",
        role: str = "user",
        **kwargs: Any,
    ) -> User:
        return User(email=email, name=name, role=role, **kwargs)
    return _make
```

### Fixture Scopes

```python
# Fixture scopes — control setup/teardown lifetime
@pytest.fixture(scope="session")             # Once per entire test run
def db_engine():
    engine = create_async_engine(TEST_DB_URL)
    yield engine
    engine.dispose()

@pytest.fixture(scope="module")              # Once per test file
async def db_tables(db_engine):
    async with db_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with db_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
```

### monkeypatch

```python
# monkeypatch — temporary attribute/env/dict patching (auto-reverted)
def test_api_key_from_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("API_KEY", "test-secret-key")
    monkeypatch.delenv("DEBUG", raising=False)    # Remove env var if exists
    config = Settings()
    assert config.api_key == "test-secret-key"

def test_override_constant(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr("my_project.config.MAX_RETRIES", 1)
    # All code importing MAX_RETRIES now sees 1
```

### capsys and tmp_path

```python
# capsys — capture stdout/stderr
def test_cli_output(capsys: pytest.CaptureFixture[str]) -> None:
    main(["--version"])
    captured = capsys.readouterr()
    assert "1.0.0" in captured.out
    assert captured.err == ""

# tmp_path — built-in temp directory (auto-cleaned)
def test_file_processing(tmp_path: Path) -> None:
    data_file = tmp_path / "input.json"
    data_file.write_text('{"key": "value"}')
    result = process_file(data_file)
    assert result.key == "value"
```
