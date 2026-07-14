# Building Images, Linting Helm, and Deploying to kind in the CI Pipeline

This lesson shows a production-oriented CI/CD pattern using GitHub Actions that combines:

1. linting and testing early
2. Docker Buildx multi-architecture image builds
3. Helm chart validation
4. Kubernetes deployment and verification
5. environment promotion controls

The goal is to fail fast on bad changes and only promote verified artifacts.

## Complete CI/CD Model

A complete production pipeline typically includes:

1. Continuous Integration: lint, test, and build on every commit.
2. Continuous Delivery: automatic deploy to staging after checks pass.
3. Continuous Deployment: controlled production deploy (often tag-based + approvals).
4. Verification: smoke checks, health checks, and failure diagnostics.
5. Rollback strategy: fast revert if deployment validation fails.

## Why These Components Matter

- Buildx lets you publish one image supporting AMD64 and ARM64.
- Helm keeps Kubernetes packaging reusable and versioned.
- GitHub Environments enforce deployment protection and approvals.
- Immutable artifacts let you build once and deploy many times safely.

## Recommended Pipeline Job Flow

Use this dependency chain:

1. `lint-and-test` for application quality checks.
2. `helm-lint` for chart/template/schema validation.
3. `build-and-push` only after both quality jobs pass.
4. `deploy-staging` on main branch after successful build.
5. `deploy-production` on approved release tag (for example semver/prod tags).

This prevents invalid code or chart errors from reaching the registry or cluster.

## Why This Order Works

Use this order in CI:

1. Build image first so deployment artifacts are real and testable.
2. Lint and render Helm before deploy to catch obvious chart issues early.
3. Deploy only after static checks pass.
4. Run smoke checks immediately after deployment.

This reduces wasted CI minutes and makes failures easier to debug.

## Prerequisites

- Docker available in CI runner
- kubectl installed
- kind installed
- helm installed
- Docker Buildx available (or installed by workflow)
- container registry credentials stored in repository secrets
- repo contains:
  - application source and Dockerfile
  - Helm chart directory (example: chart/)

## Reference Project Layout

```text
.
├── Dockerfile
├── chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
└── .github/workflows/
```

## Step 1) Build the Image

Build and tag with CI metadata.

```bash
docker build -t my-app:${GITHUB_SHA} .
```

Optional local cache pattern:

```bash
docker build \
  --cache-from my-app:cache \
  -t my-app:${GITHUB_SHA} \
  -t my-app:cache \
  .
```

## Step 2) Lint and Render Helm

Lint chart structure and values:

```bash
helm lint ./chart
```

Render templates to validate final manifests before apply:

```bash
helm template my-app ./chart \
  --set image.repository=my-app \
  --set image.tag=${GITHUB_SHA} \
  > /tmp/rendered.yaml
```

Optional API validation against a cluster context:

```bash
kubectl apply --dry-run=server -f /tmp/rendered.yaml
```

## Step 3) Create kind and Load Image

Create an ephemeral cluster:

```bash
kind create cluster --name ci
kubectl cluster-info --context kind-ci
```

Load the locally built image into kind nodes:

```bash
kind load docker-image my-app:${GITHUB_SHA} --name ci
```

## Step 4) Deploy with Helm

Install or upgrade from chart:

```bash
helm upgrade --install my-app ./chart \
  --namespace demo \
  --create-namespace \
  --set image.repository=my-app \
  --set image.tag=${GITHUB_SHA}
```

## Step 5) Run Smoke Validation

Check resource status:

```bash
kubectl get pods -A
kubectl rollout status deployment/my-app -n demo --timeout=180s
kubectl get svc -n demo
```

Minimal endpoint check (if Service is reachable):

```bash
kubectl -n demo port-forward svc/my-app 8080:80 &
curl -fsS http://localhost:8080/healthz
```

## Workflow File

The full production-style GitHub Actions workflow for this lesson is provided as a separate file in this folder:

- `github-actions-production-cicd.yml`

Keeping workflow YAML in a dedicated file makes it easier to reuse, copy into `.github/workflows/`, and maintain without bloating lesson documentation.

## Buildx-Specific Notes

During `build-and-push`, include:

1. QEMU setup for cross-architecture emulation on amd64 runners.
2. Buildx setup for BuildKit-powered multi-platform builds.
3. Registry login via secrets.
4. Metadata/tag extraction for consistent image labeling.
5. Layer caching with cache-from/cache-to for faster rebuilds.

This enables one artifact to run on both Intel and ARM environments.

## Validation Strategy for Helm

Before deployment, validate Helm output with:

1. `helm lint` for chart quality checks.
2. `helm template` for rendered manifests.
3. `kubeconform` for schema validation.
4. `kubectl apply --dry-run=server` to test API applicability.

This catches chart and manifest issues before cluster deployment.

## Staging and Production Promotion

Recommended promotion model:

1. Deploy to staging automatically from main branch.
2. Run smoke and health checks.
3. Deploy to production from explicit release tags (for example `v1.0.1` or `prod-*`).
4. Protect production with GitHub Environment approval rules.

This provides progressive delivery with controlled risk.

## Failure Handling Tips

- If build fails, stop pipeline immediately.
- If helm lint/template fails, do not deploy.
- If rollout times out, collect diagnostics before failing:

```bash
kubectl get events -A --sort-by=.lastTimestamp
kubectl describe deploy my-app -n demo
kubectl logs -n demo deploy/my-app --all-containers=true
```

If production verification fails, use Helm rollback quickly:

```bash
helm history my-app -n demo
helm rollback my-app <REVISION> -n demo
```

## CI/CD Best Practices Recap

- test early and test often
- never build/push artifacts when quality gates fail
- build immutable artifacts once and promote forward
- use progressive staging-to-production delivery
- enforce protected environments for production
- keep rollback procedures automated and documented

## Summary

This CI/CD pattern combines Buildx multi-arch builds, Helm quality gates, and Kubernetes deployment verification in a deterministic flow. It catches problems early, improves deployment confidence, and supports safer production promotion.
