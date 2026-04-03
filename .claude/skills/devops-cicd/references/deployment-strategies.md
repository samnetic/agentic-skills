# Deployment Strategies & Infrastructure as Code

## Table of Contents

- [Environment Promotion Strategy](#environment-promotion-strategy)
- [Rollback Strategy](#rollback-strategy)
- [Strategy Decision Tree](#strategy-decision-tree)
- [Rolling Update](#rolling-update)
- [Blue-Green Deployment](#blue-green-deployment)
- [Canary Deployment](#canary-deployment)
- [Terraform CI/CD Workflow](#terraform-cicd-workflow)
- [Infrastructure as Code (Terraform Essentials)](#infrastructure-as-code-terraform-essentials)
- [OpenTofu — BSL-Free Terraform Alternative](#opentofu--bsl-free-terraform-alternative)

---

## Environment Promotion Strategy

```
Feature Branch -> PR -> main -> staging -> production

PR:         Lint + Test + Security Scan (automated)
main:       Build image -> Push to registry -> Deploy to staging (automated)
staging:    Smoke tests -> Integration tests (automated)
production: Manual approval -> Deploy -> Health check -> Monitor (manual gate)
```

---

## Rollback Strategy

```bash
# Docker Compose — instant rollback to previous image
docker compose pull                    # Pull new images
docker compose up -d                   # Deploy new version

# If health check fails:
docker compose down
docker compose -f compose.yaml up -d   # Previous images still cached

# Image-based rollback (always possible)
TAG=v1.2.3 docker compose up -d       # Deploy specific version via env var
```

---

## Strategy Decision Tree

```
Traffic control available (load balancer, reverse proxy)?
├─ YES → Blue-green or canary
│   ├─ Need instant rollback, can afford 2x capacity? → Blue-green
│   └─ Want gradual rollout, minimize blast radius?   → Canary
└─ NO  → Rolling update (default for Compose / K8s)
```

---

## Rolling Update

```yaml
# compose.yaml — with docker-rollout plugin (zero-downtime)
# Install: docker plugin install ghcr.io/wowu/docker-rollout
services:
  app:
    image: myapp:${TAG:-latest}
    deploy:
      replicas: 2
      update_config:
        parallelism: 1           # Update one container at a time
        delay: 10s               # Wait between updates
        order: start-first       # Start new before stopping old
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 10s
      retries: 3
```

```bash
# Deploy with zero downtime
TAG=v1.2.3 docker rollout app     # Rolls one container at a time
```

---

## Blue-Green Deployment

```bash
#!/usr/bin/env bash
# blue-green-deploy.sh — swap between blue/green stacks
set -euo pipefail

CURRENT=$(docker compose -f compose.yaml ps --format json | jq -r '.[0].Name' | grep -o 'blue\|green')
NEXT=$([[ "$CURRENT" == "blue" ]] && echo "green" || echo "blue")

echo "Current: $CURRENT → Deploying: $NEXT"

# Start new stack
TAG="$1" docker compose -f "compose.${NEXT}.yaml" up -d --wait

# Health check new stack
for i in {1..10}; do
  if curl -sf "http://localhost:${NEXT_PORT}/health" > /dev/null; then
    echo "Health check passed"
    break
  fi
  [[ $i -eq 10 ]] && { echo "Health check failed"; docker compose -f "compose.${NEXT}.yaml" down; exit 1; }
  sleep 3
done

# Switch traffic (update reverse proxy upstream)
sed -i "s/${CURRENT}/${NEXT}/g" /etc/caddy/Caddyfile && caddy reload

# Stop old stack after drain period
sleep 30
docker compose -f "compose.${CURRENT}.yaml" down
echo "Deployed $NEXT successfully"
```

---

## Canary Deployment

```yaml
# Caddy / Traefik weighted routing for canary
# Route 5% of traffic to canary, 95% to stable
services:
  app-stable:
    image: myapp:v1.2.3
    deploy:
      replicas: 4
    labels:
      - "traefik.http.services.app.loadbalancer.server.weight=95"

  app-canary:
    image: myapp:v1.3.0-rc.1
    deploy:
      replicas: 1
    labels:
      - "traefik.http.services.app.loadbalancer.server.weight=5"
```

```bash
# Canary promotion: if error rate is OK after 30 min, scale up
# Monitor canary → if healthy: update stable image, remove canary
# If error rate spikes: kill canary immediately
```

---

## Terraform CI/CD Workflow

```yaml
# .github/workflows/terraform.yml — plan on PR, apply on merge
name: Terraform

on:
  pull_request:
    paths: ['terraform/**']
  push:
    branches: [main]
    paths: ['terraform/**']

permissions:
  id-token: write       # OIDC
  contents: read
  pull-requests: write   # Post plan as PR comment

env:
  TF_DIR: terraform/environments/production

jobs:
  plan:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.TF_ROLE_ARN }}
          aws-region: us-east-1
      - uses: hashicorp/setup-terraform@v3
      - run: terraform -chdir=$TF_DIR init -input=false
      - run: terraform -chdir=$TF_DIR plan -input=false -out=tfplan
      - run: terraform -chdir=$TF_DIR show -no-color tfplan > plan.txt
      - uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const plan = fs.readFileSync('plan.txt', 'utf8');
            const body = `#### Terraform Plan\n\`\`\`\n${plan.slice(0, 60000)}\n\`\`\``;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body,
            });

  apply:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production              # Requires approval
    steps:
      - uses: actions/checkout@v4
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.TF_ROLE_ARN }}
          aws-region: us-east-1
      - uses: hashicorp/setup-terraform@v3
      - run: terraform -chdir=$TF_DIR init -input=false
      - run: terraform -chdir=$TF_DIR apply -input=false -auto-approve
```

**Terraform CI rules:**
- Plan on every PR (post output as comment for review)
- Apply only on merge to main, behind an environment gate
- Use OIDC for cloud auth (no static keys)
- Lock state with DynamoDB/GCS to prevent concurrent applies
- Never `auto-approve` without an environment protection rule

---

## Infrastructure as Code (Terraform Essentials)

```hcl
# Minimal structure
terraform/
├── environments/
│   ├── production/
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   └── staging/
│       ├── main.tf
│       └── terraform.tfvars
├── modules/
│   ├── networking/
│   └── compute/
└── versions.tf

# State management — remote backend
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"  # State locking
    encrypt        = true
  }
}
```

---

## OpenTofu — BSL-Free Terraform Alternative

OpenTofu is a community fork of Terraform, created after HashiCorp switched to the Business Source License (BSL). It is a drop-in replacement maintained by the Linux Foundation.

```hcl
# Switch from Terraform to OpenTofu — just change the binary
# terraform init  -> tofu init
# terraform plan  -> tofu plan
# terraform apply -> tofu apply

# Same HCL syntax, same providers, same state format
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# OpenTofu-specific features:
# - Client-side state encryption (built-in, no wrapper needed)
# - Early variable/local evaluation
# - Provider-defined functions
```

| | Terraform | OpenTofu |
|---|---|---|
| License | BSL 1.1 (source-available) | MPL 2.0 (true open source) |
| Maintained by | HashiCorp/IBM | Linux Foundation |
| State encryption | Enterprise only | Built-in |
| Provider compatibility | Full | Full (same registry) |
| Migration | N/A | Drop-in replacement |

**When to choose OpenTofu:** If you need true open-source licensing, client-side state encryption without paying for Enterprise, or want community governance.
