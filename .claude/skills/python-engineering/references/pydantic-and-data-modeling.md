# Pydantic v2 and Data Modeling

## Table of Contents

- [Pydantic v2 Patterns](#pydantic-v2-patterns)
  - [Model Definition with Validation](#model-definition-with-validation)
  - [Model Validator Modes](#model-validator-modes)
  - [Functional Validators with Annotated](#functional-validators-with-annotated)
  - [Computed Fields](#computed-fields)
  - [TypeAdapter for Non-BaseModel Types](#typeadapter-for-non-basemodel-types)
  - [JSON Schema Generation](#json-schema-generation)
  - [Discriminated Unions](#discriminated-unions)
  - [Settings from Environment](#settings-from-environment)
- [Dataclass vs Pydantic](#dataclass-vs-pydantic)
- [Error Handling Patterns](#error-handling-patterns)
  - [Exception Hierarchy](#exception-hierarchy)
  - [Catching Specific Exceptions](#catching-specific-exceptions)
- [Security Patterns](#security-patterns)

---

## Pydantic v2 Patterns

### Model Definition with Validation

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
```

### Model Validator Modes

```python
# mode='before': runs on raw input BEFORE field validation (dict -> dict)
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
```

### Functional Validators with Annotated

```python
# --- Functional validators (Annotated style — reusable, composable) ---
from pydantic import BeforeValidator, AfterValidator

def strip_whitespace(v: str) -> str:
    return v.strip()

def to_lower(v: str) -> str:
    return v.lower()

# Stack validators: applied right-to-left (strip first, then lower)
type CleanStr = Annotated[str, BeforeValidator(strip_whitespace), AfterValidator(to_lower)]

class Contact(BaseModel):
    email: CleanStr     # "  FOO@BAR.COM  " -> "foo@bar.com"
    name: Annotated[str, BeforeValidator(strip_whitespace)]
```

### Computed Fields

```python
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
```

### TypeAdapter for Non-BaseModel Types

```python
# --- TypeAdapter: validate without BaseModel ---
# Useful for validating raw types, lists, unions, etc.
list_adapter = TypeAdapter(list[int])
result = list_adapter.validate_python(["1", "2", "3"])  # [1, 2, 3]
json_bytes = list_adapter.dump_json(result)               # b'[1,2,3]'

# TypeAdapter for complex types
type UserList = list[UserResponse]
user_list_adapter = TypeAdapter(UserList)
users = user_list_adapter.validate_json(raw_json_bytes)
```

### JSON Schema Generation

```python
# --- model_json_schema(): generate JSON Schema ---
schema = UserCreate.model_json_schema()
# Returns full JSON Schema dict — useful for OpenAPI, form generation, LLM tool calls
```

### Discriminated Unions

```python
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
```

### Settings from Environment

```python
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

## Error Handling Patterns

### Exception Hierarchy

```python
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
```

### Catching Specific Exceptions

```python
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
