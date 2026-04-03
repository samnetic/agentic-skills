# Toolchain and Project Setup

## Table of Contents

- [Project Structure](#project-structure)
- [pyproject.toml Configuration](#pyprojecttoml-configuration)
- [Modern Project Bootstrap with uv](#modern-project-bootstrap-with-uv)
- [Toolchain Commands](#toolchain-commands)
  - [Package Management with uv](#package-management-with-uv)
  - [uv Tool: Global CLI Tools](#uv-tool-global-cli-tools)
  - [uv Python: Version Management](#uv-python-version-management)
  - [Inline Script Dependencies PEP 723](#inline-script-dependencies-pep-723)
  - [Publishing and Distribution](#publishing-and-distribution)
  - [Linting and Formatting with ruff](#linting-and-formatting-with-ruff)
  - [Type Checking](#type-checking)
  - [Testing Commands](#testing-commands)

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

---

## pyproject.toml Configuration

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

---

## Modern Project Bootstrap with uv

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

## Toolchain Commands

### Package Management with uv

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
```

### uv Tool: Global CLI Tools

```bash
# uv tool: install and run CLI tools globally (replaces pipx)
uv tool install ruff            # Install a CLI tool globally
uv tool run black@latest .      # Run a tool without installing (like npx)
```

### uv Python: Version Management

```bash
# uv python: manage Python versions (replaces pyenv)
uv python install 3.13          # Install Python 3.13
uv python install 3.12 3.13     # Install multiple versions
uv python list                  # List available/installed versions
uv python pin 3.12              # Pin project to Python 3.12
```

### Inline Script Dependencies PEP 723

```bash
# Inline script dependencies (PEP 723) — run scripts without a project
uv init --script example.py --python 3.12    # Create script with metadata
uv add --script example.py requests rich     # Add deps to script
uv run example.py               # Auto-installs deps and runs
# Script header format:
# /// script
# requires-python = ">=3.12"
# dependencies = ["requests", "rich"]
# ///
```

### Publishing and Distribution

```bash
uv build                        # Build sdist + wheel into dist/
uv publish                      # Publish to PyPI (reads PYPI_TOKEN from env)
uv export --format requirements-txt > requirements.txt  # Export for legacy deploys/Docker
```

### Linting and Formatting with ruff

```bash
# Linting and formatting (ruff — replaces flake8+isort+black)
ruff check .                    # Lint
ruff check --fix .              # Lint with auto-fix
ruff format .                   # Format (like black)
```

### Type Checking

```bash
mypy src/                       # Strict type checking
pyright src/                    # Alternative (faster, stricter)
```

### Testing Commands

```bash
pytest                          # Run all tests
pytest -x                       # Stop on first failure
pytest --cov=src --cov-report=term-missing  # Coverage
pytest -k "test_create"         # Run matching tests
pytest --durations=10           # Show slowest tests
```
