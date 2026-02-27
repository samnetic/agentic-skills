---
name: python-engineering
description: >-
  Modern Python 3.13+ development expertise. Use when writing Python code, adding type
  hints, designing async/await patterns, structuring Python packages, writing pytest
  test suites, using Pydantic v2 for validation, implementing dependency injection,
  configuring ruff/mypy/pyright toolchain, using uv package manager, designing CLI
  applications with click/typer, writing FastAPI/Flask/Django applications, implementing
  dataclasses and protocols, managing virtual environments, publishing packages to PyPI,
  writing Pythonic code, using structlog for structured logging, or reviewing Python
  code quality.
  Triggers: Python, type hints, async, await, pytest, Pydantic, FastAPI, Flask, Django,
  ruff, mypy, uv, pip, dataclass, protocol, ABC, click, typer, poetry, packaging,
  virtualenv, decorator, context manager, generator, comprehension, structlog, tomllib,
  TypeAdapter, ExceptionGroup, TaskGroup, TypeIs, PEP 695, SQLAlchemy, free-threaded,
  template strings.
---

# Python Engineering Skill

Write Python that is typed, tested, and Pythonic. Modern Python (3.13+) with
type hints everywhere, Pydantic for validation, pytest for testing, uv for packaging,
structlog for logging.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Type everything** | Every function signature, every class attribute |
| **Explicit over implicit** | The Zen of Python, rule #2 |
| **Composition over inheritance** | Protocols and dependency injection over deep class hierarchies |
| **Fail fast, fail loudly** | Validate inputs at boundaries with Pydantic |
| **Test behavior, not implementation** | pytest + fixtures, mock only external dependencies |
| **Modern toolchain** | uv for packages, ruff for lint+format, mypy/pyright for types |
| **Structured logging** | structlog with JSON output — no `print()`, no `logging.info()` |
| **Use the stdlib** | `tomllib`, `asyncio.TaskGroup`, `ExceptionGroup` — prefer built-ins |

---

## Project Structure

```
my-project/
├── pyproject.toml              # Single config for everything
├── src/
│   └── my_project/
│       ├── __init__.py
│       ├── main.py             # Entry point
│       ├── config.py           # Settings with Pydantic
│       ├── domain/             # Business logic (no framework deps)
│       │   ├── models.py       # Domain entities
│       │   └── services.py     # Business logic
│       ├── api/                # HTTP layer
│       │   ├── routes.py
│       │   ├── deps.py         # Dependency injection
│       │   └── schemas.py      # Request/response models
│       ├── db/                 # Data access
│       │   ├── repository.py
│       │   └── models.py       # ORM models
│       └── shared/
│           ├── errors.py       # Exception hierarchy
│           └── types.py        # Shared type aliases
├── tests/
│   ├── conftest.py             # Shared fixtures
│   ├── unit/
│   │   └── test_services.py
│   ├── integration/
│   │   └── test_api.py
│   └── fixtures/
│       └── data.py
└── scripts/                    # One-off scripts, migrations
```

### pyproject.toml

```toml
[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.13"
dependencies = [
    "fastapi>=0.115",
    "pydantic>=2.0",
    "sqlalchemy>=2.0",
    "httpx>=0.27",
    "structlog>=24.0",
]

[dependency-groups]                     # PEP 735 (uv 0.5+) — replaces [project.optional-dependencies] for dev deps
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.24",
    "pytest-cov>=6.0",
    "mypy>=1.13",
    "ruff>=0.8",
]

[tool.ruff]
target-version = "py313"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "UP", "S", "B", "A", "C4", "PT", "SIM", "TC", "PERF", "PTH", "RUF"]
ignore = ["E501"]  # line length handled by formatter
# TC: flake8-type-checking — move imports behind TYPE_CHECKING
# SIM: flake8-simplify — simplify boolean/conditional expressions
# PERF: Perflint — unnecessary list()/dict() in loops, membership checks
# PTH: flake8-use-pathlib — prefer pathlib over os.path

[tool.ruff.lint.flake8-type-checking]
# Tell TC rules these base classes need runtime imports (not TYPE_CHECKING)
runtime-evaluated-base-classes = ["pydantic.BaseModel", "sqlalchemy.orm.DeclarativeBase"]

[tool.ruff.lint.isort]
known-first-party = ["my_project"]

[tool.mypy]
strict = true
plugins = ["pydantic.mypy"]

# Per-module overrides — relax strict for specific cases
[[tool.mypy.overrides]]
module = "tests.*"
disallow_untyped_defs = false       # Allow untyped test helpers

[[tool.mypy.overrides]]
module = "my_project.vendor.*"
ignore_errors = true                # Skip vendored code

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
filterwarnings = [
    "error",                         # Treat warnings as errors
    "ignore::DeprecationWarning:third_party_lib",  # Except known third-party deprecations
]
```

### Modern Project Bootstrap with uv

```bash
# Create a new project (generates pyproject.toml, src layout, .venv)
uv init my-project
cd my-project

# Create a workspace with multiple packages
uv init --lib my-lib          # Library package in workspace
uv init --app my-app          # Application package in workspace

# Workspace pyproject.toml (root)
# [tool.uv.workspace]
# members = ["my-lib", "my-app"]
```

---

## Type Hints — Complete Guide

```python
from collections.abc import Callable, Sequence, Mapping, AsyncIterator
from typing import Protocol, Self, overload, override, TypeIs

# --- Python 3.10+ ---
def greet(name: str | None = None) -> str:        # Union with |
    return f"Hello, {name or 'World'}"

# Collections (3.9+ built-in generics)
def process(items: list[str]) -> dict[str, int]:   # Not List, Dict
    return {item: len(item) for item in items}

# --- Python 3.12+ PEP 695: type alias syntax ---
type Point = tuple[int, int]                       # Replaces TypeAlias
type Handler = Callable[[Request], Response]
type AsyncHandler = Callable[[Request], Awaitable[Response]]
type JSON = dict[str, "JSON"] | list["JSON"] | str | int | float | bool | None

# --- Python 3.12+ PEP 695: type parameter syntax ---
def first[T](items: Sequence[T]) -> T | None:     # No more TypeVar()!
    return items[0] if items else None

class Stack[T]:                                    # Generic class — no Generic[T]
    def __init__(self) -> None:
        self._items: list[T] = []
    def push(self, item: T) -> None:
        self._items.append(item)
    def pop(self) -> T:
        return self._items.pop()

# Protocol (structural typing — duck typing with types)
class Repository[T](Protocol):                     # Generic protocol (3.12+)
    async def get(self, id: str) -> T | None: ...
    async def save(self, entity: T) -> T: ...
    async def delete(self, id: str) -> bool: ...

# Self type (3.11+)
class Builder:
    def with_name(self, name: str) -> Self:
        self.name = name
        return self

# typing.override decorator (3.12+) — catches incorrect overrides at type-check time
class Base:
    def process(self, data: str) -> str: ...

class Child(Base):
    @override
    def process(self, data: str) -> str:           # mypy/pyright error if Base.process removed
        return data.upper()

# typing.TypeIs (3.13+ stdlib, earlier versions via typing_extensions) — narrows types
def is_str_list(val: list[object]) -> TypeIs[list[str]]:
    return all(isinstance(x, str) for x in val)

items: list[object] = ["a", "b"]
if is_str_list(items):
    print(items[0].upper())  # type checker knows items is list[str]

# Overload for different return types
@overload
def parse(data: str) -> dict[str, Any]: ...
@overload
def parse(data: bytes) -> str: ...
def parse(data: str | bytes) -> dict[str, Any] | str:
    if isinstance(data, bytes):
        return data.decode()
    return json.loads(data)
```

---

## Python 3.12/3.13/3.14 Feature Highlights

```python
# --- f-string improvements (3.12+) ---
# Nested quotes, backslashes, and comments now allowed inside f-strings
items = ["a", "b", "c"]
print(f"joined: {"\n".join(items)}")               # Backslashes OK in f-strings
matrix = [[1, 2], [3, 4]]
flat = f"{[x for row in matrix for x in row]}"     # Nested comprehensions OK

# --- ExceptionGroup and except* (3.11+) ---
# Handle multiple concurrent exceptions (from TaskGroup, etc.)
async def fetch_all(urls: list[str]) -> list[str]:
    results: list[str] = []
    try:
        async with asyncio.TaskGroup() as tg:
            for url in urls:
                tg.create_task(fetch_one(url, results))
    except* ValueError as eg:
        for exc in eg.exceptions:
            logger.warning(f"Validation error: {exc}")
    except* OSError as eg:
        for exc in eg.exceptions:
            logger.error(f"Network error: {exc}")
    return results

# --- Free-threaded Python (no GIL) — 3.13 experimental, 3.14 production-ready ---
# Install: python3.14t (the 't' suffix indicates free-threaded build)
import sys
print(sys._is_gil_enabled())  # False on free-threaded build

# Use cases for free-threaded Python:
# - CPU-bound parallel processing (replaces multiprocessing for some cases)
# - Concurrent data processing pipelines
# - Scientific computing with shared memory

import threading
results = []
def compute(chunk):
    # True parallel execution on multiple cores
    results.append(heavy_computation(chunk))

threads = [threading.Thread(target=compute, args=(c,)) for c in chunks]
for t in threads: t.start()
for t in threads: t.join()

# --- per-interpreter GIL (3.12+) ---
# Each sub-interpreter can have its own GIL — limited parallelism for isolated workloads
# Less impactful in practice than free-threaded builds; useful for embedding scenarios
# Currently experimental; use via C API or interpreters module

# --- Template string literals (PEP 750, Python 3.14) ---
from string.templatelib import Template
name = "world"
greeting: Template = t"Hello {name}"
# NOT a string — it's a Template object for safe interpolation
# Use for SQL, HTML, etc. to prevent injection

# --- Deferred evaluation of annotations (PEP 649, Python 3.14) ---
# Annotations no longer eagerly evaluated at import time
# Reduces import overhead, eliminates need for `from __future__ import annotations`

# --- Experimental JIT compiler (3.13+) ---
# Build CPython with --enable-experimental-jit for copy-and-patch JIT
# Provides moderate speedups for hot loops; no code changes required

# --- tomllib (3.11+ built-in TOML parser) ---
import tomllib
from pathlib import Path

# Read TOML config without external dependencies
with Path("pyproject.toml").open("rb") as f:
    config = tomllib.load(f)

# Parse TOML strings
data = tomllib.loads("""
[tool.mypy]
strict = true
plugins = ["pydantic.mypy"]
""")
```

---

## Structural Pattern Matching (`match`/`case`)

```python
# --- Basic value matching ---
def handle_command(command: str) -> str:
    match command.split():
        case ["quit"]:
            return "Goodbye"
        case ["hello", name]:
            return f"Hello, {name}"
        case ["move", direction, *rest]:     # Star pattern captures remaining
            return f"Moving {direction} (extras: {rest})"
        case _:                              # Wildcard — always matches
            return "Unknown command"

# --- Class pattern (destructuring objects) ---
from dataclasses import dataclass

@dataclass
class Point:
    x: float
    y: float

@dataclass
class Circle:
    center: Point
    radius: float

@dataclass
class Rectangle:
    origin: Point
    width: float
    height: float

type Shape = Circle | Rectangle

def describe(shape: Shape) -> str:
    match shape:
        case Circle(center=Point(x=0, y=0), radius=r):
            return f"Circle at origin, radius {r}"
        case Circle(radius=r) if r > 100:    # Guard clause
            return f"Large circle, radius {r}"
        case Circle(center=c, radius=r):
            return f"Circle at ({c.x}, {c.y}), radius {r}"
        case Rectangle(width=w, height=h) if w == h:
            return f"Square, side {w}"
        case Rectangle(origin=o, width=w, height=h):
            return f"Rect at ({o.x}, {o.y}), {w}x{h}"

# --- Mapping pattern (dict matching) ---
def handle_event(event: dict[str, Any]) -> None:
    match event:
        case {"type": "click", "button": "left", "position": (x, y)}:
            handle_left_click(x, y)
        case {"type": "click", "button": "right"}:
            show_context_menu()
        case {"type": "keypress", "key": str(k)} if len(k) == 1:
            insert_char(k)
        case {"type": "keypress", "key": "Enter"}:
            submit()

# --- OR patterns and nested matching ---
def classify_status(code: int) -> str:
    match code:
        case 200 | 201 | 204:
            return "success"
        case 301 | 302 | 307 | 308:
            return "redirect"
        case 400 | 422:
            return "client_error"
        case 401 | 403:
            return "auth_error"
        case 404:
            return "not_found"
        case code if 500 <= code < 600:       # Guard with variable
            return "server_error"
        case _:
            return "unknown"

# --- Sequence pattern with type narrowing ---
def process_row(row: tuple[str, ...]) -> None:
    match row:
        case (name, age, email) if age.isdigit():
            create_user(name, int(age), email)
        case (name, email):
            create_user(name, email=email)
        case ():
            pass  # Skip empty rows
        case _:
            raise ValueError(f"Unexpected row format: {row}")
```

---

## Decision Trees

```
Web Framework Selection:
├── Full-featured (ORM, admin, auth) → Django
├── High-performance async API → FastAPI
├── Minimal, flexible → Flask
├── Modern async alternative → Litestar
└── ML model serving → FastAPI or BentoML

Validation Library:
├── Runtime validation + serialization → Pydantic v2
├── Lightweight data classes + validation → attrs
├── Simple structured data (no validation) → dataclasses
└── Schema validation for external data → Pydantic v2

Async vs Sync:
├── I/O-bound (HTTP calls, DB queries) → async
├── CPU-bound processing → multiprocessing (or free-threaded 3.14t)
├── Simple scripts → sync
├── Mixed I/O + CPU → async for I/O, ProcessPool for CPU
└── Existing sync codebase → sync (don't mix without reason)

Type Checker:
├── Strictest, most features → pyright (default in VS Code)
├── Most configurable, plugins → mypy
├── Both (CI: mypy, IDE: pyright) → recommended for libraries
└── Quick project → pyright (zero-config in VS Code)

Package Manager:
├── New projects (2025+) → uv (fastest, replaces pip/poetry/pdm)
├── Existing poetry projects → keep poetry, migrate later
├── Existing pip projects → migrate to uv
└── Enterprise with lockfiles → uv or poetry
```

---

## Pydantic v2 Patterns

```python
from pydantic import BaseModel, Field, field_validator, model_validator, ConfigDict
from pydantic import TypeAdapter, Discriminator, Tag
from datetime import datetime
from typing import Annotated, Literal

class UserCreate(BaseModel):
    model_config = ConfigDict(strict=True)  # No type coercion

    email: str = Field(..., pattern=r'^[\w.-]+@[\w.-]+\.\w+$')
    name: str = Field(..., min_length=1, max_length=100)
    age: int = Field(..., ge=13, le=150)
    role: Literal['admin', 'user', 'viewer'] = 'user'

    @field_validator('email')
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.lower().strip()

    @model_validator(mode='after')
    def check_admin_age(self) -> Self:
        if self.role == 'admin' and self.age < 18:
            raise ValueError('Admins must be 18+')
        return self

class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)  # ORM mode

    id: str
    email: str
    name: str
    role: str
    created_at: datetime

# --- model_validator modes ---
# mode='before': runs on raw input BEFORE field validation (dict → dict)
class NormalizedUser(BaseModel):
    @model_validator(mode='before')
    @classmethod
    def normalize_input(cls, data: Any) -> Any:
        if isinstance(data, dict):
            # Normalize keys from camelCase to snake_case, strip whitespace, etc.
            return {k: v.strip() if isinstance(v, str) else v for k, v in data.items()}
        return data

    email: str
    name: str

# mode='wrap': wraps the entire validation — can intercept, transform, or short-circuit
class CachedModel(BaseModel):
    @model_validator(mode='wrap')
    @classmethod
    def check_cache(cls, data: Any, handler: Callable) -> Self:
        cache_key = str(data)
        if cached := _cache.get(cache_key):
            return cached
        result = handler(data)  # Run normal validation
        _cache[cache_key] = result
        return result

    id: str
    value: int

# --- Functional validators (Annotated style — reusable, composable) ---
from pydantic import BeforeValidator, AfterValidator

def strip_whitespace(v: str) -> str:
    return v.strip()

def to_lower(v: str) -> str:
    return v.lower()

# Stack validators: applied right-to-left (strip first, then lower)
type CleanStr = Annotated[str, BeforeValidator(strip_whitespace), AfterValidator(to_lower)]

class Contact(BaseModel):
    email: CleanStr     # "  FOO@BAR.COM  " → "foo@bar.com"
    name: Annotated[str, BeforeValidator(strip_whitespace)]

# --- Computed fields (derived properties included in serialization) ---
from pydantic import computed_field

class Order(BaseModel):
    items: list[LineItem]
    tax_rate: float = 0.1

    @computed_field                     # Included in .model_dump() and .model_dump_json()
    @property
    def subtotal(self) -> float:
        return sum(item.price * item.qty for item in self.items)

    @computed_field
    @property
    def total(self) -> float:
        return self.subtotal * (1 + self.tax_rate)

# --- TypeAdapter: validate without BaseModel ---
# Useful for validating raw types, lists, unions, etc.
list_adapter = TypeAdapter(list[int])
result = list_adapter.validate_python(["1", "2", "3"])  # [1, 2, 3]
json_bytes = list_adapter.dump_json(result)               # b'[1,2,3]'

# TypeAdapter for complex types
type UserList = list[UserResponse]
user_list_adapter = TypeAdapter(UserList)
users = user_list_adapter.validate_json(raw_json_bytes)

# --- model_json_schema(): generate JSON Schema ---
schema = UserCreate.model_json_schema()
# Returns full JSON Schema dict — useful for OpenAPI, form generation, LLM tool calls

# --- Discriminated Unions (tagged unions for performance) ---
class EmailNotification(BaseModel):
    channel: Literal['email']
    recipient: str
    subject: str

class SMSNotification(BaseModel):
    channel: Literal['sms']
    phone: str
    body: str

class PushNotification(BaseModel):
    channel: Literal['push']
    device_token: str
    title: str

# Pydantic uses 'channel' to pick the right model — O(1) instead of trying each
type Notification = Annotated[
    EmailNotification | SMSNotification | PushNotification,
    Field(discriminator='channel'),
]

notification_adapter = TypeAdapter(Notification)
notif = notification_adapter.validate_python({"channel": "sms", "phone": "+1234", "body": "Hi"})
# Returns SMSNotification instance directly

# Settings from environment
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    model_config = ConfigDict(env_file='.env', env_prefix='APP_')

    database_url: str
    redis_url: str = 'redis://localhost:6379'
    secret_key: str
    debug: bool = False
    allowed_origins: list[str] = ['http://localhost:3000']
```

---

## Dataclass vs Pydantic

```python
# Use dataclass when:
# - Internal data structures, no external input
# - Performance-critical (less overhead)
# - Simple attribute storage

from dataclasses import dataclass, field

@dataclass(frozen=True, slots=True)
class Point:
    x: float
    y: float

@dataclass(slots=True)
class CacheEntry:
    key: str
    value: bytes
    ttl: int = 300
    tags: list[str] = field(default_factory=list)

# Use Pydantic when:
# - Validating external input (API, config, files)
# - Need serialization (JSON, dict)
# - Complex validation rules

from pydantic import BaseModel, EmailStr, Field

class UserCreate(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)
```

---

## Async Patterns

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

# Async context manager
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

# Async generator (streaming)
async def stream_records(query: str) -> AsyncIterator[Record]:
    async with get_db_session() as session:
        result = await session.stream(text(query))
        async for row in result:
            yield Record.model_validate(row)

# Semaphore for rate limiting
sem = asyncio.Semaphore(10)  # Max 10 concurrent

async def rate_limited_fetch(url: str) -> Response:
    async with sem:
        return await httpx.get(url)

# Timeout
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

## FastAPI Modern Patterns (0.115+)

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

# --- Annotated for query params with validation ---
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

```python
import pytest
from unittest.mock import AsyncMock, patch

# Fixtures
@pytest.fixture
def user_data() -> dict[str, Any]:
    return {"email": "test@example.com", "name": "Test User", "role": "user"}

@pytest.fixture
async def db_session():
    async with get_test_db() as session:
        yield session
        await session.rollback()

# Parametrize with pytest.param for readable IDs and marks
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

# Async tests
@pytest.mark.asyncio
async def test_create_user(db_session: AsyncSession) -> None:
    repo = UserRepository(db_session)
    user = await repo.create(UserCreate(email="new@test.com", name="New", age=25))
    assert user.id is not None
    assert user.email == "new@test.com"

# Mocking external services
async def test_send_notification() -> None:
    mock_client = AsyncMock()
    mock_client.post.return_value = Response(status_code=200)

    service = NotificationService(client=mock_client)
    await service.send("user_123", "Hello")

    mock_client.post.assert_called_once()

# Factory fixtures
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

# monkeypatch — temporary attribute/env/dict patching (auto-reverted)
def test_api_key_from_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("API_KEY", "test-secret-key")
    monkeypatch.delenv("DEBUG", raising=False)    # Remove env var if exists
    config = Settings()
    assert config.api_key == "test-secret-key"

def test_override_constant(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr("my_project.config.MAX_RETRIES", 1)
    # All code importing MAX_RETRIES now sees 1

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

---

## Error Handling

```python
# Exception hierarchy
class AppError(Exception):
    """Base application error."""
    def __init__(self, message: str, code: str = "INTERNAL_ERROR") -> None:
        super().__init__(message)
        self.code = code

class NotFoundError(AppError):
    def __init__(self, resource: str, id: str) -> None:
        super().__init__(f"{resource} not found: {id}", code="NOT_FOUND")

class ValidationError(AppError):
    def __init__(self, message: str, fields: dict[str, list[str]] | None = None) -> None:
        super().__init__(message, code="VALIDATION_ERROR")
        self.fields = fields or {}

class AuthenticationError(AppError):
    def __init__(self, message: str = "Authentication required") -> None:
        super().__init__(message, code="UNAUTHENTICATED")

# Usage — catch specific, not broad
try:
    user = await repo.get(user_id)
except NotFoundError:
    return JSONResponse(status_code=404, content={"error": "User not found"})
except AppError as e:
    return JSONResponse(status_code=400, content={"error": str(e), "code": e.code})
# Never: except Exception — let unexpected errors crash loudly
```

---

## Security Patterns

```python
# Never use eval/exec with user input
# Never use pickle to deserialize untrusted data
# Never use string formatting for SQL queries

# Safe subprocess calls
import subprocess
result = subprocess.run(
    ["ls", "-la", user_provided_path],  # List form, not string
    capture_output=True, text=True,
    timeout=30,
    check=True,
)
# NEVER: subprocess.run(f"ls {user_input}", shell=True)

# Safe temporary files
import tempfile
with tempfile.NamedTemporaryFile(delete=True, suffix='.json') as f:
    f.write(data)
    f.flush()
    process(f.name)

# SQL injection prevention — always use parameterized queries
from sqlalchemy import text
# Good: parameterized
result = await session.execute(text("SELECT * FROM users WHERE id = :id"), {"id": user_id})
# NEVER: f"SELECT * FROM users WHERE id = {user_id}"

# Secret management
import os
secret = os.environ["API_KEY"]  # From environment, never hardcoded
# NEVER: API_KEY = "sk-1234..."
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| `def f(x):` without type hints | No IDE help, no static analysis | Type every signature |
| Mutable default `def f(x=[])` | Shared between calls, causes bugs | `def f(x: list | None = None)` |
| Bare `except:` or `except Exception:` | Swallows KeyboardInterrupt, hides bugs | Catch specific exceptions |
| `import *` | Namespace pollution, unclear imports | Explicit imports |
| God class with 20+ methods | Impossible to test, understand, maintain | Decompose into focused classes |
| Using `dict` for everything | No type safety, no autocompletion | Pydantic models or dataclasses |
| Sync calls in async code | Blocks the event loop | Use `asyncio.to_thread()` for sync I/O |
| No virtual environment | System Python pollution | `uv venv` or `python -m venv` |
| `print()` for debugging/logging | No levels, no structure, no rotation | `structlog` with JSON output |
| `logging.info(f"...")` format strings | No structure, hard to parse/query | `structlog` with key-value pairs |
| `T = TypeVar("T")` in 3.12+ code | Verbose, old-style generics | `def f[T]()` PEP 695 syntax |
| `TypeAlias = ...` in 3.12+ code | Verbose, old-style aliases | `type X = ...` PEP 695 syntax |
| `import toml` / `import tomli` | Unnecessary dependency since 3.11 | `import tomllib` (stdlib) |
| `@app.on_event("startup")` in FastAPI | Deprecated lifecycle hooks | `lifespan` async context manager |
| Not using context managers | Resource leaks (files, connections) | `with` / `async with` |
| Class when function suffices | OOP cargo cult | Functions for stateless operations |
| Nested dicts 3+ levels deep | Unreadable, fragile | Pydantic models |
| `asyncio.run()` inside running loop | Raises RuntimeError, nesting not allowed | Use `await` directly or `loop.create_task()` |
| No `__slots__` on hot-path classes | Higher memory, slower attribute access | Add `__slots__` or use `@dataclass(slots=True)` |
| Circular imports | ImportError at runtime, tangled architecture | Reorganize modules, use local imports or protocols |
| Mutable default arguments in classes | `def __init__(self, items=[])` shares list | Use `field(default_factory=list)` or `None` sentinel |
| `if/elif` chains for value dispatch | Verbose, error-prone | `match`/`case` structural pattern matching |
| `# type: ignore` without error code | Silences ALL mypy errors on that line | `# type: ignore[specific-code]` — target specific errors |
| `[project.optional-dependencies]` for dev deps | Not designed for dev-only groups | `[dependency-groups]` (PEP 735) with `uv add --group dev` |
| Pydantic validator that mutates + validates | Hard to test, unclear order | Separate `BeforeValidator` (transform) + field constraints (validate) |

---

## Toolchain Commands

```bash
# Package management (uv — 10-100x faster than pip)
uv init my-project              # Create new project (pyproject.toml + src layout)
uv init --lib my-lib            # Create library package
uv add fastapi pydantic         # Add dependencies
uv add --group dev pytest ruff mypy  # Add to dependency group (PEP 735)
uv sync                         # Install from lock file
uv sync --group dev             # Install with specific dependency group
uv run pytest                   # Run command in project venv (auto-creates venv)
uv run python script.py         # Run script in project venv

# uv tool: install and run CLI tools globally (replaces pipx)
uv tool install ruff            # Install a CLI tool globally
uv tool run black@latest .      # Run a tool without installing (like npx)

# uv python: manage Python versions (replaces pyenv)
uv python install 3.13          # Install Python 3.13
uv python install 3.12 3.13     # Install multiple versions
uv python list                  # List available/installed versions
uv python pin 3.12              # Pin project to Python 3.12

# Inline script dependencies (PEP 723) — run scripts without a project
uv init --script example.py --python 3.12    # Create script with metadata
uv add --script example.py requests rich     # Add deps to script
uv run example.py               # Auto-installs deps and runs
# Script header format:
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests", "rich"]
# ///

# Publishing and distribution
uv build                        # Build sdist + wheel into dist/
uv publish                      # Publish to PyPI (reads PYPI_TOKEN from env)
uv export --format requirements-txt > requirements.txt  # Export for legacy deploys/Docker

# Linting and formatting (ruff — replaces flake8+isort+black)
ruff check .                    # Lint
ruff check --fix .              # Lint with auto-fix
ruff format .                   # Format (like black)

# Type checking
mypy src/                       # Strict type checking
pyright src/                    # Alternative (faster, stricter)

# Testing
pytest                          # Run all tests
pytest -x                       # Stop on first failure
pytest --cov=src --cov-report=term-missing  # Coverage
pytest -k "test_create"         # Run matching tests
pytest --durations=10           # Show slowest tests
```

---

## Checklist: Python Code Review

- [ ] Type hints on all function signatures and class attributes
- [ ] Uses PEP 695 syntax (`type X = ...`, `def f[T]()`) for 3.12+ projects
- [ ] No `Any` types except at serialization boundaries
- [ ] Pydantic models for all external data (API input, config, DB results)
- [ ] `TypeAdapter` for validating non-BaseModel types (lists, unions, primitives)
- [ ] Discriminated unions use `Field(discriminator=...)` for performance
- [ ] No mutable default arguments (functions or class `__init__`)
- [ ] Async code uses `asyncio.TaskGroup` for concurrency
- [ ] `ExceptionGroup` / `except*` used when TaskGroup can raise multiple errors
- [ ] No `asyncio.run()` inside an already-running event loop
- [ ] Specific exception handling (no bare `except`)
- [ ] Tests exist with meaningful assertions
- [ ] No `print()` — use `structlog` with JSON output
- [ ] Context managers for resource management
- [ ] TOML parsing uses built-in `tomllib` (not `toml` or `tomli`)
- [ ] FastAPI uses `Annotated[T, Depends()]` style and `lifespan` events
- [ ] SQLAlchemy uses 2.0 `select()` style (not legacy `query()`)
- [ ] `__slots__` on performance-critical classes or `@dataclass(slots=True)`
- [ ] No circular imports; clean module dependency graph
- [ ] No `eval()`, `exec()`, or `pickle.loads()` on untrusted data
- [ ] Subprocess calls use list form, never `shell=True` with user input
- [ ] `match`/`case` used instead of `if/elif` chains for value/type dispatch
- [ ] `# type: ignore` comments include specific error code (e.g., `# type: ignore[override]`)
- [ ] mypy per-module overrides for tests and vendored code (not blanket `# type: ignore`)
- [ ] ruff + mypy pass with no errors
- [ ] `pyproject.toml` is the single config file (with `[dependency-groups]` for dev deps)
- [ ] uv manages dependencies and Python versions
