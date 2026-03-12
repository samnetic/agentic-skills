---
name: bash-scripting
description: >-
  Modern Bash scripting and shell automation expertise. Use when writing shell scripts,
  automating tasks with bash, parsing command-line arguments, handling errors in scripts,
  processing text with awk/sed/jq, managing processes and signals, writing portable
  shell scripts, creating Docker entrypoints, writing CI/CD pipeline scripts, automating
  server provisioning, creating CLI tools in bash, file operations with proper quoting,
  using ShellCheck for linting, testing scripts with BATS, implementing retry logic,
  logging frameworks, color output, configuration file parsing, or reviewing shell script
  quality.
  Triggers: bash, shell, script, sh, zsh, awk, sed, jq, grep, find, xargs, cron,
  systemd timer, entrypoint, provisioning, automation, CLI tool, ShellCheck, BATS,
  heredoc, trap, signal, process, pipeline, pipe, redirect, subprocess.
---

# Bash Scripting Skill

Write shell scripts that are strict, quoted, readable, and testable.
Bash is a glue language — use it for automation and plumbing, not application logic.

---

## Core Principles

| Principle | Meaning |
|---|---|
| **Strict mode always** | `set -euo pipefail` in every script |
| **Quote everything** | `"$variable"` — unquoted variables are bugs |
| **Fail fast, fail loud** | Errors should stop execution with clear messages |
| **ShellCheck is mandatory** | Run on every script, fix all warnings |
| **Prefer readability** | Clear variable names, functions, comments for non-obvious logic |
| **Know when to stop** | If >100 lines or complex data structures, use Python |

---

## Script Template

Every new script starts from this template. Never write a script without strict mode and a cleanup trap.

```bash
#!/usr/bin/env bash
set -euo pipefail

# ── Constants ─────────────────────────────────────────────
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"

# ── Color helpers ─────────────────────────────────────────
USE_COLOR=true
[[ ! -t 1 ]] && USE_COLOR=false
[[ -n "${NO_COLOR:-}" ]] && USE_COLOR=false

color() { $USE_COLOR && printf '\033[%sm' "$1" || true; }
info()  { echo "$(color '0;32')info$(color 0) $*"; }
warn()  { echo "$(color '0;33')warn$(color 0) $*" >&2; }
err()   { echo "$(color '0;31')error$(color 0) $*" >&2; }
die()   { err "$@"; exit 1; }

# ── Cleanup trap ──────────────────────────────────────────
cleanup() {
  [[ -n "${TMPDIR_SCRIPT:-}" ]] && rm -rf "$TMPDIR_SCRIPT"
}
trap cleanup EXIT

# ── Usage ─────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [options] <argument>

Options:
  -v, --verbose    Enable verbose output
  -h, --help       Show this help
EOF
  exit 0
}

# ── Argument parsing ──────────────────────────────────────
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--verbose) VERBOSE=true; shift ;;
    -h|--help)    usage ;;
    --)           shift; break ;;
    -*)           die "Unknown option: $1" ;;
    *)            break ;;
  esac
done

# ── Main ──────────────────────────────────────────────────
main() {
  info "Starting $SCRIPT_NAME"
  # Your logic here
}

main "$@"
```

**Template rules:**
- `#!/usr/bin/env bash` — portable shebang (not `/bin/bash`)
- `set -euo pipefail` — always, no exceptions
- `readonly` for constants — prevent accidental mutation
- Color helpers respect `NO_COLOR` env and non-TTY output
- `cleanup` trap on `EXIT` — fires on normal exit, errors, and signals
- `main "$@"` at the bottom — keeps global scope clean

---

## Workflow: Writing a Bash Script

1. **Assess scope** — If >100 lines or needs complex data structures, use Python instead. See the Decision Tree below.
2. **Start from template** — Copy the Script Template above. Never write from scratch without `set -euo pipefail` and `trap cleanup EXIT`.
3. **Define interface** — Add argument parsing with `while/case` loop. Handle `--help`, unknown options, and `--` separator. For complex CLIs, use `getopt`. See `references/scripting-patterns.md` for all parsing patterns.
4. **Check dependencies** — Use `command -v` to verify required tools at startup. Fail fast with clear messages.
5. **Implement logic** — Use functions with `local` for all variables. Return data via stdout, status via return codes. See `references/scripting-patterns.md` for function patterns.
6. **Handle errors** — Add retry logic for network calls. Use `trap ERR` for line-number reporting. Wrap long operations with timeouts. See `references/scripting-patterns.md` for error handling.
7. **Process text safely** — Use `jq` for JSON, `awk` for field extraction, `sed` for substitution. Always quote variables and use `find -print0` with `xargs -0`. See `references/tools-and-recipes.md`.
8. **Lint with ShellCheck** — Run `shellcheck` on the script. Fix all warnings. Disable specific checks only with inline comments explaining why.
9. **Write BATS tests** — Test `--help` output, missing arguments, unknown options, and filenames with spaces. See `references/tools-and-recipes.md` for BATS patterns.
10. **Review against checklist** — Walk through the Checklist section below before merging.

---

## Decision Tree: When to Use Bash

```
Need a script?
├── Simple automation (<100 lines) .................. Bash
├── Glue between CLI tools (pipe, compose) .......... Bash
├── Docker entrypoint ............................... Bash (minimal)
├── CI/CD pipeline steps (simple) ................... Bash
├── File renaming, backup, cleanup .................. Bash
├── Server provisioning (simple) .................... Bash
│
├── Complex data structures (dicts, classes) ........ Python
├── Error handling beyond exit codes ................ Python
├── HTTP/JSON/API calls (complex) ................... Python (or curl + jq for simple)
├── Cross-platform requirement ...................... Python
├── >100 lines with business logic .................. Python
├── CI/CD pipeline steps (complex) .................. Python
├── Interactive TUI .................................. Python (rich) or Go
└── Performance-critical CLI tool ................... Go or Rust
```

**Rule of thumb:** If you are reaching for associative arrays, complex string parsing, or nested data structures in Bash, switch to Python.

---

## Anti-Patterns

| Anti-Pattern | Why It's Dangerous | Fix |
|---|---|---|
| No `set -euo pipefail` | Errors silently ignored, undefined vars expand to empty | Always set strict mode |
| Unquoted variables `$var` | Word splitting, glob expansion, security vulnerabilities | Always `"$var"` |
| Parsing `ls` output | Breaks on spaces, newlines, special chars in filenames | Use `find -print0` or globs |
| `cat file \| grep` | Useless use of cat | `grep pattern file` directly |
| `echo "$password"` | Visible in `ps`, process list, logs | Use files or env vars |
| `eval "$user_input"` | Code injection, arbitrary execution | Never eval untrusted input |
| `cd` without error check | Script continues in wrong directory | `cd /path \|\| die "cd failed"` |
| `kill -9` as first resort | No chance for graceful cleanup | SIGTERM first, SIGKILL after timeout |
| Backticks `` `cmd` `` | Hard to nest, hard to read | Use `$(cmd)` |
| `[ ]` single brackets | No regex, no glob, quoting pitfalls | Use `[[ ]]` in Bash |
| No cleanup trap | Temp files, lock files left behind | `trap cleanup EXIT` |
| `while read` without `IFS=` | Leading/trailing whitespace stripped | `while IFS= read -r line` |
| Hardcoded paths | Breaks across environments | Use `$SCRIPT_DIR`, variables, config |
| `for f in $(find ...)` | Breaks on whitespace in filenames | `find -print0 \| while read -d ''` |
| Ignoring ShellCheck warnings | Known bug patterns remain | Fix all, disable only with comment |
| `source .env` without validation | Arbitrary code execution from .env | Parse with `while read` + regex |
| `local var=$(cmd)` | `local` masks the exit code of `cmd` | Declare and assign on separate lines |
| `set -x` left in production | Leaks secrets to logs and stderr | Use only during debugging, remove after |

---

## Progressive Disclosure Map

| Topic | Reference | When to read |
|---|---|---|
| Strict mode details, caveats of `set -e` | `references/scripting-patterns.md` | When debugging why `set -e` did not catch a failure |
| Argument parsing (while/case, getopt, subcommands) | `references/scripting-patterns.md` | When building a CLI with options or subcommands |
| Error handling, retry, timeouts | `references/scripting-patterns.md` | When adding resilience to network calls or flaky commands |
| Variables, parameter expansion, arrays | `references/scripting-patterns.md` | When doing string manipulation or working with arrays |
| Functions, heredocs, string handling | `references/scripting-patterns.md` | When structuring a script with functions or generating config files |
| Text processing (jq, awk, sed, grep) | `references/tools-and-recipes.md` | When parsing JSON, extracting fields, or transforming text |
| File operations, atomic writes, find patterns | `references/tools-and-recipes.md` | When handling files with special characters or needing atomic writes |
| Process management, signals, locking | `references/tools-and-recipes.md` | When running parallel jobs or building a daemon-like script |
| Docker entrypoints | `references/tools-and-recipes.md` | When writing a container entrypoint script |
| BATS testing | `references/tools-and-recipes.md` | When writing or running tests for shell scripts |
| Cron, systemd timers | `references/tools-and-recipes.md` | When scheduling scripts for periodic execution |
| ShellCheck CI integration | `references/tools-and-recipes.md` | When adding shell linting to a CI pipeline |
| Portability (macOS vs Linux, POSIX vs Bash) | `references/tools-and-recipes.md` | When a script must run on both macOS and Linux |
| Common recipes (spinner, logging, .env loading) | `references/tools-and-recipes.md` | When implementing UX helpers or config loading |

---

## Checklist: Shell Script Review

- [ ] Shebang is `#!/usr/bin/env bash` (not `/bin/bash` or `/bin/sh`)
- [ ] `set -euo pipefail` is the first line after shebang
- [ ] All variables are quoted: `"$var"`, `"${array[@]}"`
- [ ] `readonly` used for constants, `local` used in functions
- [ ] `trap cleanup EXIT` handles temporary files and lock files
- [ ] Argument parsing handles `--help`, `-h`, unknown options, and `--`
- [ ] Error messages go to stderr (`>&2`)
- [ ] Functions use `local` for all variables
- [ ] `command -v` used to check for required tools at startup
- [ ] `find` uses `-print0` with `xargs -0` or `read -d ''`
- [ ] No parsing of `ls` output
- [ ] No `eval` with user-provided input
- [ ] ShellCheck passes with zero warnings
- [ ] BATS tests exist for critical paths
- [ ] Color output respects `NO_COLOR` env and non-TTY detection
- [ ] Secrets are never echoed or logged
- [ ] In-place `sed` is portable (`sed -i.bak ... && rm *.bak`)
- [ ] Exit codes are meaningful (0 = success, 1 = general error, 2 = usage error)
- [ ] Long scripts (>100 lines) have been evaluated for rewrite in Python
- [ ] Script works correctly when run from any working directory (uses `$SCRIPT_DIR`)
