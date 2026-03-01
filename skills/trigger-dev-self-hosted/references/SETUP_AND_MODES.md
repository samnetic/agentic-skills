# Trigger.dev Setup And Modes

## Mode Selection

Choose mode before writing code or deployment docs:

- `cloud`: managed Trigger.dev platform.
- `self-host-local`: Docker Compose for local/dev evaluation.
- `self-host-production`: Kubernetes + Helm + managed dependencies.

If a user says both "self-hosted" and "production", default to `self-host-production`.

## Install Official Trigger Guidance

Install both upstream skill content and Trigger rules:

```bash
npx skills add triggerdotdev/skills
npx trigger.dev@latest install-rules
```

If using Claude Code and prompted, include the `trigger-dev-expert` subagent.

## Bootstrap Commands

```bash
# Verify CLI version
npx trigger.dev@latest --version

# Cloud login
npx trigger.dev@latest login

# Self-hosted login to custom Trigger.dev API
npx trigger.dev@latest login -a https://trigger.example.com --profile self-hosted

# Verify identity and profile
npx trigger.dev@latest whoami --profile self-hosted

# Initialize Trigger.dev in current repo
npx trigger.dev@latest init
```

## Profile Strategy

Use one profile per environment:

- `dev-selfhost`
- `staging-selfhost`
- `prod-selfhost`

Never mix production credentials with development profile names.

## Project Structure Baseline

```txt
trigger/
  tasks/
    billing/
      sync-customer.ts
    media/
      transcode-video.ts
  shared/
    schemas.ts
    queues.ts
trigger.config.ts
```

Guidelines:

- Group tasks by domain.
- Keep each task file focused on one main workflow.
- Keep top-level task files readable; extract helpers before they become hard to review.
- Keep shared schema modules close to task usage.
