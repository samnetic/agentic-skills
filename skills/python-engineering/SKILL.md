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

| # | Principle | Meaning |
|---|-----------|---------|
| 1 | **Type everything** | Every function signature, every class attribute |
| 2 | **Explicit over implicit** | The Zen of Python, rule #2 |
| 3 | **Composition over inheritance** | Protocols and dependency injection over deep class hierarchies |
| 4 | **Fail fast, fail loudly** | Validate inputs at boundaries with Pydantic |
| 5 | **Test behavior, not implementation** | pytest + fixtures, mock only external dependencies |
| 6 | **Modern toolchain** | uv for packages, ruff for lint+format, mypy/pyright for types |
| 7 | **Structured logging** | structlog with JSON output -- no `print()`, no `logging.info()` |
| 8 | **Use the stdlib** | `tomllib`, `asyncio.TaskGroup`, `ExceptionGroup` -- prefer built-ins |

---

## Workflow

### 1. Bootstrap the project

```bash
uv init my-project && cd my-project
uv add fastapi pydantic sqlalchemy httpx structlog
uv add --group dev pytest pytest-asyncio pytest-cov mypy ruff
```

Use `src/` layout with `pyproject.toml` as single config. See reference for full structure.

### 2. Define domain models

```python
from pydantic import BaseModel, Field, ConfigDict
from dataclasses import dataclass

# External data (API, config) -> Pydantic
class UserCreate(BaseModel):
    model_config = ConfigDict(strict=True)
    email: str = Field(..., pattern=r'^[\w.-]+@[\w.-]+\.\w+$')
    name: str = Field(..., min_length=1, max_length=100)

# Internal data structures -> dataclass
@dataclass(frozen=True, slots=True)
class Point:
    x: float
    y: float
```

### 3. Type every signature (PEP 695 for 3.12+)

```python
# Modern generic syntax
def first[T](items: Sequence[T]) -> T | None:
    return items[0] if items else None

type JSON = dict[str, "JSON"] | list["JSON"] | str | int | float | bool | None

# Protocols for structural typing
class Repository[T](Protocol):
    async def get(self, id: str) -> T | None: ...
    async def save(self, entity: T) -> T: ...
```

### 4. Write async code with structured concurrency

```python
async def fetch_all(urls: list[str]) -> list[Response]:
    results: list[Response] = []
    async with asyncio.TaskGroup() as tg:
        for url in urls:
            tg.create_task(fetch_one(url, results))
    return results
# Handle failures with except* for ExceptionGroup
```

### 5. Configure structured logging

```python
import structlog
logger = structlog.get_logger()
logger.info("user.created", user_id=user.id, email=user.email)
# Key-value pairs, not format strings. JSON in prod, console in dev.
```

### 6. Write tests

```python
@pytest.mark.parametrize("email,valid", [
    pytest.param("user@example.com", True, id="standard"),
    pytest.param("invalid", False, id="no-at-sign"),
])
def test_email_validation(email: str, valid: bool) -> None:
    if valid:
        assert UserCreate(email=email, name="Test")
    else:
        with pytest.raises(ValidationError):
            UserCreate(email=email, name="Test")
```

### 7. Run the toolchain

```bash
ruff check --fix . && ruff format .    # Lint + format
mypy src/                               # Type check
pytest --cov=src                        # Test with coverage
```

### 8. Build and publish

```bash
uv build                               # sdist + wheel
uv publish                             # PyPI (reads PYPI_TOKEN)
```

---

## Decision Tree

```
Web Framework Selection:
├── Full-featured (ORM, admin, auth) -> Django
├── High-performance async API -> FastAPI
├── Minimal, flexible -> Flask
├── Modern async alternative -> Litestar
└── ML model serving -> FastAPI or BentoML

Validation Library:
├── Runtime validation + serialization -> Pydantic v2
├── Lightweight data classes + validation -> attrs
├── Simple structured data (no validation) -> dataclasses
└── Schema validation for external data -> Pydantic v2

Async vs Sync:
├── I/O-bound (HTTP calls, DB queries) -> async
├── CPU-bound processing -> multiprocessing (or free-threaded 3.14t)
├── Simple scripts -> sync
├── Mixed I/O + CPU -> async for I/O, ProcessPool for CPU
└── Existing sync codebase -> sync (don't mix without reason)

Type Checker:
├── Strictest, most features -> pyright (default in VS Code)
├── Most configurable, plugins -> mypy
├── Both (CI: mypy, IDE: pyright) -> recommended for libraries
└── Quick project -> pyright (zero-config in VS Code)

Package Manager:
├── New projects (2025+) -> uv (fastest, replaces pip/poetry/pdm)
├── Existing poetry projects -> keep poetry, migrate later
├── Existing pip projects -> migrate to uv
└── Enterprise with lockfiles -> uv or poetry

Dataclass vs Pydantic:
├── External input (API, config, files) -> Pydantic BaseModel
├── Internal data, no validation needed -> @dataclass
├── Immutable value objects -> @dataclass(frozen=True, slots=True)
├── Need JSON serialization + validation -> Pydantic BaseModel
└── Validating non-model types (lists, unions) -> TypeAdapter
```

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| `def f(x):` without type hints | No IDE help, no static analysis | Type every signature |
| Mutable default `def f(x=[])` | Shared between calls, causes bugs | `def f(x: list \| None = None)` |
| Bare `except:` or `except Exception:` | Swallows KeyboardInterrupt, hides bugs | Catch specific exceptions |
| `import *` | Namespace pollution, unclear imports | Explicit imports |
| God class with 20+ methods | Impossible to test, maintain | Decompose into focused classes |
| Using `dict` for everything | No type safety, no autocompletion | Pydantic models or dataclasses |
| Sync calls in async code | Blocks the event loop | Use `asyncio.to_thread()` |
| No virtual environment | System Python pollution | `uv venv` or `python -m venv` |
| `print()` for logging | No levels, no structure, no rotation | `structlog` with JSON output |
| `logging.info(f"...")` | No structure, hard to parse | `structlog` with key-value pairs |
| `T = TypeVar("T")` in 3.12+ | Verbose, old-style generics | `def f[T]()` PEP 695 syntax |
| `TypeAlias = ...` in 3.12+ | Verbose, old-style aliases | `type X = ...` PEP 695 syntax |
| `import toml` / `import tomli` | Unnecessary dep since 3.11 | `import tomllib` (stdlib) |
| `@app.on_event("startup")` | Deprecated FastAPI hooks | `lifespan` async context manager |
| Not using context managers | Resource leaks | `with` / `async with` |
| Class when function suffices | OOP cargo cult | Functions for stateless ops |
| Nested dicts 3+ levels | Unreadable, fragile | Pydantic models |
| `asyncio.run()` inside running loop | RuntimeError | Use `await` or `loop.create_task()` |
| No `__slots__` on hot-path classes | Higher memory, slower access | `@dataclass(slots=True)` |
| Circular imports | ImportError at runtime | Reorganize, use protocols |
| `if/elif` chains for dispatch | Verbose, error-prone | `match`/`case` pattern matching |
| `# type: ignore` without code | Silences ALL mypy errors | `# type: ignore[specific-code]` |
| `[project.optional-dependencies]` for dev | Not for dev-only groups | `[dependency-groups]` PEP 735 |
| Pydantic validator mutates + validates | Hard to test, unclear order | Separate `BeforeValidator` + constraints |

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|-------|-----------|--------------|
| Type hints, PEP 695, Protocols, overloads, TypeIs | `references/type-system-and-modern-python.md` | Adding type hints, using generics, writing protocols |
| Python 3.12-3.14 features, f-strings, free-threaded, template strings, JIT | `references/type-system-and-modern-python.md` | Using new Python features, evaluating version upgrades |
| Structural pattern matching (`match`/`case`) | `references/type-system-and-modern-python.md` | Replacing if/elif chains, destructuring objects |
| Pydantic v2 models, validators, discriminated unions, TypeAdapter | `references/pydantic-and-data-modeling.md` | Validating external input, building API schemas |
| Dataclass vs Pydantic decision, computed fields, Settings | `references/pydantic-and-data-modeling.md` | Choosing data modeling approach |
| Error handling patterns, exception hierarchy, security | `references/pydantic-and-data-modeling.md` | Designing error handling, security review |
| Async patterns, TaskGroup, semaphores, streaming | `references/async-frameworks-and-testing.md` | Writing concurrent code, async generators |
| structlog configuration and usage | `references/async-frameworks-and-testing.md` | Setting up logging for the first time |
| FastAPI lifespan, Annotated deps, SQLAlchemy 2.0 | `references/async-frameworks-and-testing.md` | Building web APIs, database access layer |
| pytest fixtures, parametrize, mocking, scopes | `references/async-frameworks-and-testing.md` | Writing or reviewing test suites |
| Project structure, pyproject.toml, ruff/mypy config | `references/toolchain-and-project-setup.md` | Bootstrapping a new project |
| uv commands, Python version management, publishing | `references/toolchain-and-project-setup.md` | Package management, CI/CD setup, releasing |

---

## Checklist

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
- [ ] No `print()` -- use `structlog` with JSON output
- [ ] Context managers for resource management
- [ ] TOML parsing uses built-in `tomllib` (not `toml` or `tomli`)
- [ ] FastAPI uses `Annotated[T, Depends()]` style and `lifespan` events
- [ ] SQLAlchemy uses 2.0 `select()` style (not legacy `query()`)
- [ ] `__slots__` on performance-critical classes or `@dataclass(slots=True)`
- [ ] No circular imports; clean module dependency graph
- [ ] No `eval()`, `exec()`, or `pickle.loads()` on untrusted data
- [ ] Subprocess calls use list form, never `shell=True` with user input
- [ ] `match`/`case` used instead of `if/elif` chains for value/type dispatch
- [ ] `# type: ignore` comments include specific error code
- [ ] mypy per-module overrides for tests and vendored code
- [ ] ruff + mypy pass with no errors
- [ ] `pyproject.toml` is the single config file (with `[dependency-groups]` for dev deps)
- [ ] uv manages dependencies and Python versions
