# Trigger.dev Self-Hosting Runbook

## Deployment Path Decision

- Use Docker Compose only for local/dev evaluation.
- Use Kubernetes + official Helm chart for production.

If a production requirement exists, do not recommend Compose as the target runtime.

## Local/Dev With Docker Compose

```bash
curl -fsSL https://raw.githubusercontent.com/triggerdotdev/docker/main/docker-compose.yml -o docker-compose.yml
cp .env.example .env
docker compose up -d
```

Use local mode for:

- Developer onboarding.
- Small integration tests.
- Fast iteration before cluster rollout.

## Production With Kubernetes + Helm

```bash
helm repo add trigger https://triggerdotdev.github.io/charts
helm repo update
helm install trigger-stack trigger/trigger-stack --namespace trigger --create-namespace
```

Production baseline:

- Use managed or external PostgreSQL and Redis.
- Configure persistent storage and tested backup/restore.
- Put ingress behind TLS and private networking controls.
- Configure observability before go-live.
- Pin chart/app versions and roll out upgrades in stages.

## Capacity Baseline

From official chart guidance:

- Development minimum: 2 CPU / 4 GiB RAM.
- Production minimum: 8 CPU / 16 GiB RAM.

Treat this as a starting point. Re-size with real workload and queue depth data.

## Security And Operations Checklist

1. Scope access tokens and rotate them.
2. Store secrets in cluster secret management tooling.
3. Restrict network paths between app, database, and Redis.
4. Configure alerts for queue backlog, failure spikes, and service health.
5. Document rollback procedure for both chart and task deployments.
