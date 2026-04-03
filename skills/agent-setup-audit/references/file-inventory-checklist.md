# File Inventory Checklist

Complete checklist of files to scan in an agentic project setup.

## Primary Instruction Files

- [ ] `CLAUDE.md` — main agent instructions (authoritative source)
- [ ] `AGENTS.md` — multi-agent compatibility
  - Check: is it a symlink to CLAUDE.md? (`ls -la AGENTS.md`)
  - If not symlinked: are contents identical? If different, flag as contradiction
- [ ] `codex.md` — Codex CLI instructions (legacy format)
- [ ] `.cursorrules` — Cursor rules (legacy single-file format)

## Configuration Files

- [ ] `.claude/settings.json` — tool permissions, hooks, model config
- [ ] `.claude/settings.local.json` — local overrides (gitignored)
- [ ] `~/.claude/settings.json` — global settings
  - Check: do global settings conflict with project settings?

## Skills & Agents

- [ ] `.claude/skills/` — all skill directories with SKILL.md files
  - Check: do any skills duplicate CLAUDE.md instructions?
- [ ] `.claude/agents/` — all agent .md files
  - Check: do agent personas conflict with CLAUDE.md conventions?
- [ ] `.codex/skills/` and `.codex/agents/` — Codex installations
- [ ] `.opencode/skills/` and `.opencode/agents/` — OpenCode installations
- [ ] `.cursor/rules/` — Cursor rule files

## Hooks

- [ ] `.claude/hooks/` — all .sh scripts
  - Check: does each hook have a matching event registration in settings.json?
  - Check: do hook behaviors conflict with CLAUDE.md instructions?
- [ ] `.opencode/plugins/` — OpenCode plugin bridge

## Project Context Files

- [ ] `CONTEXT.md` — current project context
  - Check: is it stale? (last modified > 2 weeks ago = warning)
- [ ] `SPEC.md` or `SPEC-*.md` — application specification
- [ ] `TASKS.md` — active task tracking
  - Check: are completed tasks archived or still cluttering?
- [ ] `DESIGN_SYSTEM.md` — UI/design system rules
- [ ] `RUNBOOK.md` — deployment and operations procedures

## Architecture & Documentation

- [ ] `docs/adr/` — Architecture Decision Records
  - Check: do ADRs align with CLAUDE.md conventions?
- [ ] `docs/pipeline/` — pipeline status files
  - Check: any stale in-progress pipelines?

## Memory & State

- [ ] `.claude/memory/` or `memory/` — memory files
  - Check: any stale or contradictory memories?
  - Check: does MEMORY.md index match actual files?

## Symlink Verification

```bash
# AGENTS.md should symlink to CLAUDE.md
ls -la AGENTS.md
# Expected: AGENTS.md -> CLAUDE.md
```

## Quick Inventory Command

```bash
# Find all instruction files in a project
find . -maxdepth 3 \( \
  -name "CLAUDE.md" -o -name "AGENTS.md" -o -name "codex.md" -o \
  -name ".cursorrules" -o -name "CONTEXT.md" -o -name "SPEC.md" -o \
  -name "TASKS.md" -o -name "DESIGN_SYSTEM.md" -o -name "RUNBOOK.md" -o \
  -name "settings.json" -o -name "settings.local.json" -o \
  -name "SKILL.md" -o -name "MEMORY.md" \
  \) -not -path "*/node_modules/*" 2>/dev/null
```
