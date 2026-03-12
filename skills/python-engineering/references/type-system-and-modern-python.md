# Type System and Modern Python Features

## Table of Contents

- [Type Hints Complete Guide](#type-hints-complete-guide)
  - [Basic Types and Union Syntax](#basic-types-and-union-syntax)
  - [PEP 695 Type Alias and Parameter Syntax](#pep-695-type-alias-and-parameter-syntax)
  - [Protocols and Structural Typing](#protocols-and-structural-typing)
  - [Self Type and Override Decorator](#self-type-and-override-decorator)
  - [TypeIs for Type Narrowing](#typeis-for-type-narrowing)
  - [Function Overloads](#function-overloads)
- [Python 3.12/3.13/3.14 Feature Highlights](#python-312313314-feature-highlights)
  - [F-String Improvements](#f-string-improvements)
  - [ExceptionGroup and except*](#exceptiongroup-and-except)
  - [Free-Threaded Python](#free-threaded-python)
  - [Per-Interpreter GIL](#per-interpreter-gil)
  - [Template String Literals PEP 750](#template-string-literals-pep-750)
  - [Deferred Annotation Evaluation PEP 649](#deferred-annotation-evaluation-pep-649)
  - [Experimental JIT Compiler](#experimental-jit-compiler)
  - [tomllib Built-in TOML Parser](#tomllib-built-in-toml-parser)
- [Structural Pattern Matching](#structural-pattern-matching)
  - [Basic Value Matching](#basic-value-matching)
  - [Class Pattern Destructuring](#class-pattern-destructuring)
  - [Mapping Pattern](#mapping-pattern)
  - [OR Patterns and Guards](#or-patterns-and-guards)
  - [Sequence Pattern with Type Narrowing](#sequence-pattern-with-type-narrowing)

---

## Type Hints Complete Guide

### Basic Types and Union Syntax

```python
from collections.abc import Callable, Sequence, Mapping, AsyncIterator
from typing import Protocol, Self, overload, override, TypeIs

# --- Python 3.10+ ---
def greet(name: str | None = None) -> str:        # Union with |
    return f"Hello, {name or 'World'}"

# Collections (3.9+ built-in generics)
def process(items: list[str]) -> dict[str, int]:   # Not List, Dict
    return {item: len(item) for item in items}
```

### PEP 695 Type Alias and Parameter Syntax

```python
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
```

### Protocols and Structural Typing

```python
# Protocol (structural typing — duck typing with types)
class Repository[T](Protocol):                     # Generic protocol (3.12+)
    async def get(self, id: str) -> T | None: ...
    async def save(self, entity: T) -> T: ...
    async def delete(self, id: str) -> bool: ...
```

### Self Type and Override Decorator

```python
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
```

### TypeIs for Type Narrowing

```python
# typing.TypeIs (3.13+ stdlib, earlier versions via typing_extensions) — narrows types
def is_str_list(val: list[object]) -> TypeIs[list[str]]:
    return all(isinstance(x, str) for x in val)

items: list[object] = ["a", "b"]
if is_str_list(items):
    print(items[0].upper())  # type checker knows items is list[str]
```

### Function Overloads

```python
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

### F-String Improvements

```python
# --- f-string improvements (3.12+) ---
# Nested quotes, backslashes, and comments now allowed inside f-strings
items = ["a", "b", "c"]
print(f"joined: {"\n".join(items)}")               # Backslashes OK in f-strings
matrix = [[1, 2], [3, 4]]
flat = f"{[x for row in matrix for x in row]}"     # Nested comprehensions OK
```

### ExceptionGroup and except*

```python
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
```

### Free-Threaded Python

```python
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
```

### Per-Interpreter GIL

```python
# --- per-interpreter GIL (3.12+) ---
# Each sub-interpreter can have its own GIL — limited parallelism for isolated workloads
# Less impactful in practice than free-threaded builds; useful for embedding scenarios
# Currently experimental; use via C API or interpreters module
```

### Template String Literals PEP 750

```python
# --- Template string literals (PEP 750, Python 3.14) ---
from string.templatelib import Template
name = "world"
greeting: Template = t"Hello {name}"
# NOT a string — it's a Template object for safe interpolation
# Use for SQL, HTML, etc. to prevent injection
```

### Deferred Annotation Evaluation PEP 649

```python
# --- Deferred evaluation of annotations (PEP 649, Python 3.14) ---
# Annotations no longer eagerly evaluated at import time
# Reduces import overhead, eliminates need for `from __future__ import annotations`
```

### Experimental JIT Compiler

```python
# --- Experimental JIT compiler (3.13+) ---
# Build CPython with --enable-experimental-jit for copy-and-patch JIT
# Provides moderate speedups for hot loops; no code changes required
```

### tomllib Built-in TOML Parser

```python
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

## Structural Pattern Matching

### Basic Value Matching

```python
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
```

### Class Pattern Destructuring

```python
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
```

### Mapping Pattern

```python
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
```

### OR Patterns and Guards

```python
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
```

### Sequence Pattern with Type Narrowing

```python
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
