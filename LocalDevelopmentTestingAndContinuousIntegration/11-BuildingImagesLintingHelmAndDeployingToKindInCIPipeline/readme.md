# Building Images, Linting Helm, and Deploying to kind in the CI Pipeline

This lesson shows a practical CI sequence for Kubernetes delivery:

1. build image
2. lint and template Helm chart
3. deploy to a disposable kind cluster
4. run smoke validation

The goal is to fail fast on packaging or manifest errors before runtime failures.

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

## GitHub Actions Example

```yaml
name: ci-kind-helm

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  validate-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Install kind
        uses: helm/kind-action@v1.10.0
        with:
          cluster_name: ci

      - name: Install Helm
        uses: azure/setup-helm@v4

      - name: Build image
        run: docker build -t my-app:${{ github.sha }} .

      - name: Helm lint
        run: helm lint ./chart

      - name: Helm template
        run: |
          helm template my-app ./chart \
            --set image.repository=my-app \
            --set image.tag=${{ github.sha }} > rendered.yaml

      - name: Load image into kind
        run: kind load docker-image my-app:${{ github.sha }} --name ci

      - name: Deploy
        run: |
          helm upgrade --install my-app ./chart \
            --namespace demo --create-namespace \
            --set image.repository=my-app \
            --set image.tag=${{ github.sha }}

      - name: Smoke checks
        run: |
          kubectl rollout status deployment/my-app -n demo --timeout=180s
          kubectl get pods -n demo
```

## Failure Handling Tips

- If build fails, stop pipeline immediately.
- If helm lint/template fails, do not deploy.
- If rollout times out, collect diagnostics before failing:

```bash
kubectl get events -A --sort-by=.lastTimestamp
kubectl describe deploy my-app -n demo
kubectl logs -n demo deploy/my-app --all-containers=true
```

## Summary

This CI pattern combines image build, Helm checks, and real cluster deployment validation in one deterministic flow. It catches problems earlier and gives fast, actionable feedback.
