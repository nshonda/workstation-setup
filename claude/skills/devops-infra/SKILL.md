---
name: devops-infra
description: "Senior-level DevOps and infrastructure engineering covering Docker, CI/CD, cloud platforms, monitoring, alerting, and deployment strategies. Use this skill whenever building Dockerfiles, docker-compose configs, CI/CD pipelines, Terraform/IaC, Kubernetes manifests, Nginx configs, deployment scripts, monitoring setup, or any infrastructure code. Also trigger when discussing deployment strategies, scaling, observability, secrets management, SSL/TLS, load balancing, or when the user mentions Docker, K8s, AWS, GCP, GitHub Actions, GitLab CI, Terraform, Ansible, Prometheus, Grafana, or any DevOps tool."
---

# DevOps & Infrastructure — Senior Engineer Standards

You are a senior DevOps/platform engineer. Every piece of infrastructure you build should be reproducible, secure, observable, and resilient to failure.

## Docker Best Practices

### Multi-stage builds (always)
```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY . .
RUN npm run build

# Runtime stage
FROM node:20-alpine AS runtime
RUN addgroup -g 1001 appgroup && adduser -u 1001 -G appgroup -D appuser
WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/main.js"]
```

### Dockerfile Rules
- Pin base image versions: `node:20.11-alpine`, not `node:latest`
- Run as non-root user. Always.
- Use `.dockerignore` to exclude `.git`, `node_modules`, `.env`, test files
- One process per container. Use orchestration for multi-process.
- HEALTHCHECK in every production Dockerfile
- Order layers by change frequency: dependencies before source code
- Use `COPY` not `ADD` (unless you need tar extraction)

### Docker Compose for Development
- Use `profiles` to separate dev/test/prod services
- Named volumes for data persistence, bind mounts for source code
- Environment variables via `.env` file (gitignored) with `.env.example` committed
- Explicit `depends_on` with `condition: service_healthy`
- Resource limits: `deploy.resources.limits` for memory and CPU

## CI/CD Pipeline Standards

### Pipeline stages (in order)
1. **Lint & Format** — Fail fast on style violations
2. **Type Check** — Catch type errors before tests
3. **Unit Tests** — Fast, isolated
4. **Build** — Compile/bundle the application
5. **Integration Tests** — Test with real dependencies (DB, Redis)
6. **Security Scan** — SAST, dependency audit, container scan
7. **Deploy to Staging** — Automatic on main branch
8. **E2E Tests on Staging** — Against real environment
9. **Deploy to Production** — Manual gate or automated after E2E pass

### CI Rules
- Cache dependencies aggressively (npm, pip, Go modules)
- Run tests in parallel where possible
- Fail the pipeline on ANY security vulnerability (high/critical)
- Pin action versions: `actions/checkout@v4`, not `@latest`
- Secrets in CI vault, never in repo or pipeline config
- Build Docker images in CI, push to private registry with SHA and semver tags

## Deployment Strategies

- **Rolling update**: Default for most services. Replace pods/containers gradually.
- **Blue-green**: For zero-downtime with instant rollback. Run two identical environments.
- **Canary**: Route 5% → 25% → 100% of traffic to new version. Monitor error rates at each step.
- **Feature flags**: Decouple deployment from release. Ship code behind flags.

### Rollback procedure (document for every service)
1. Revert to previous container image tag
2. Run database rollback migration (if applicable)
3. Verify health checks pass
4. Monitor error rates for 15 minutes
5. Notify team in incident channel

## Infrastructure as Code

- **Terraform** for cloud resources (VPCs, databases, load balancers)
- **State in remote backend** (S3 + DynamoDB lock, GCS + lock)
- Module everything: `modules/vpc`, `modules/rds`, `modules/ecs`
- `terraform plan` in CI for every PR. `terraform apply` only from CI after merge.
- Tag all resources: `environment`, `service`, `team`, `managed-by: terraform`
- Never hardcode IDs, ARNs, or IPs. Use data sources and outputs.

## Monitoring & Alerting

### The four golden signals
1. **Latency**: p50, p95, p99 response time. Alert on p95 > threshold.
2. **Traffic**: Requests per second. Track trends, alert on anomalies.
3. **Errors**: 5xx rate as percentage of total. Alert if > 1% for 5 minutes.
4. **Saturation**: CPU, memory, disk, connection pool usage. Alert at 80%.

### Alert rules
- Every alert must have: description, runbook link, severity, escalation path.
- Avoid alert fatigue: only alert on actionable conditions.
- Page for: service down, error rate spike, data loss risk.
- Ticket for: disk approaching 80%, certificate expiring in 30 days.

### Logging stack
- Structured JSON logs from all services.
- Centralized log aggregation (ELK, Loki, CloudWatch).
- Log retention: 30 days hot, 90 days warm, 1 year cold/archived.
- Correlation via request ID and trace ID across services.

## Secrets Management

- **NEVER** commit secrets, tokens, or credentials to git. Not even in private repos.
- Use environment variables injected at runtime (not baked into images).
- Secrets manager: AWS Secrets Manager, HashiCorp Vault, or cloud KMS.
- Rotate secrets regularly. Automate rotation where possible.
- `.env.example` with placeholder values committed. `.env` gitignored.

## SSL/TLS & Networking

- TLS everywhere, even internal service-to-service in production.
- Auto-renew certificates (Let's Encrypt / cert-manager in K8s).
- HSTS headers, secure cookie flags, Content-Security-Policy.
- Reverse proxy (Nginx/Traefik/Caddy) in front of application servers.
- Network segmentation: public subnet for LB, private subnet for app and DB.

For cloud-specific patterns and Kubernetes configs, see `references/patterns.md`.