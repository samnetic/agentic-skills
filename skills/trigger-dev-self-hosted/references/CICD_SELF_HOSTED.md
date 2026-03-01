# Trigger.dev Self-Hosted CI/CD

## CI Authentication Model

In CI, Trigger CLI profiles are typically unavailable. Use environment variables:

- `TRIGGER_API_URL`
- `TRIGGER_ACCESS_TOKEN`

## Deploy Template

```bash
export TRIGGER_API_URL="https://trigger.example.com"
export TRIGGER_ACCESS_TOKEN="$TRIGGER_ACCESS_TOKEN"

# Standard deployment
npx trigger.dev@latest deploy

# Use only when your self-hosted setup requires explicit image push behavior
npx trigger.dev@latest deploy --self-hosted --push
```

## Promotion Strategy

1. Build once per commit SHA.
2. Promote the same artifact through `staging` then `production`.
3. Run smoke workflows after each environment deployment.
4. Keep previous known-good release available for rollback.

## Post-Deploy Verification

- Trigger a lightweight canary workflow.
- Verify run success and latency in dashboard/metrics.
- Confirm no sudden retry storm or queue depth anomaly.
- Verify error rate and logs for the first production window.

## Rollback Pattern

- Roll back chart/app version if platform issue exists.
- Re-deploy last known-good Trigger tasks if task bundle caused regression.
- Keep rollback commands and release references in the runbook, not in memory.
