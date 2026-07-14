# Cleanup and Resource Optimization in CI Clusters

This lesson focuses on keeping Kubernetes CI jobs fast, predictable, and cost-efficient by combining strict cleanup with practical optimization.

## Why Cleanup and Optimization Matter

CI clusters are ephemeral by design. If resources are not cleaned correctly, pipelines become flaky, slower, and more expensive.

Common failure patterns:

- leaked namespaces and workloads from previous runs
- disk pressure from unused images and layers
- noisy-neighbor behavior due to missing requests/limits
- long job times from avoidable rebuilds/downloads

## Core Principles

1. Always clean test resources, even on failure.
2. Prefer disposable clusters for isolation.
3. Cache dependencies and build layers where safe.
4. Set requests/limits for test workloads.
5. Collect diagnostics before teardown.

## Cleanup Strategy Levels

### Level 1: Namespace Cleanup

Best when one cluster is shared across multiple CI jobs.

```bash
kubectl delete namespace test-${RUN_ID} --wait=true --timeout=180s
```

Use labels for bulk cleanup:

```bash
kubectl delete ns -l ci-run=true
```

### Level 2: Full Cluster Teardown

Best for strongest isolation and repeatability.

```bash
kind delete cluster --name ci
```

This avoids cross-test contamination and keeps test environments deterministic.

## Always Cleanup on Failure

In CI, put cleanup in always-run steps.

GitHub Actions pattern:

```yaml
- name: Cleanup kind
  if: always()
  run: kind delete cluster --name ci
```

If using namespace-only cleanup:

```yaml
- name: Cleanup namespace
  if: always()
  run: kubectl delete ns test-${{ github.run_id }} --ignore-not-found=true --wait=true
```

## Capture Diagnostics Before Teardown

Collect useful data first, then clean up:

```bash
kubectl get all -A
kubectl get events -A --sort-by=.lastTimestamp
kubectl describe pods -A
kubectl logs -A --all-containers=true --tail=200
```

Store these logs as CI artifacts so failed runs are debuggable.

## Resource Optimization Techniques

### 1) Use Requests and Limits

Set conservative requests/limits in test manifests to avoid starvation.

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
```

### 2) Cache Build Layers

Use Docker Buildx cache in CI to reduce rebuild time.

```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3

- name: Build with cache
  uses: docker/build-push-action@v6
  with:
    context: .
    push: false
    tags: my-app:${{ github.sha }}
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### 3) Cache Language Dependencies

Cache module/package directories per lockfile hash.

Examples:

- Go module cache
- npm/pnpm cache
- pip cache

### 4) Right-Size kind Cluster

Avoid over-allocating nodes for small test suites.

- single-node kind for simple smoke tests
- multi-node kind only when scheduling/network behavior is under test

### 5) Parallelize Carefully

Parallel jobs speed up pipelines but can saturate runner resources.

- cap max parallel test jobs
- split suites by labels or tags
- monitor CPU/memory usage across jobs

## Example: CI Job Skeleton

```yaml
name: ci-optimized

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  integration:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Create kind cluster
        uses: helm/kind-action@v1.10.0
        with:
          cluster_name: ci

      - name: Run tests
        run: |
          kubectl create ns test-${{ github.run_id }}
          # apply manifests and run tests here

      - name: Collect diagnostics
        if: failure()
        run: |
          kubectl get all -A
          kubectl get events -A --sort-by=.lastTimestamp

      - name: Cleanup
        if: always()
        run: |
          kubectl delete ns test-${{ github.run_id }} --ignore-not-found=true --wait=true
          kind delete cluster --name ci
```

## Anti-Patterns to Avoid

- leaving clusters alive after job completion
- using default namespace for all CI tests
- missing timeouts on rollout and wait commands
- no limits on test pods
- skipping artifact collection on failures

## Summary

Reliable Kubernetes CI depends on two disciplines:

1. strict automated cleanup
2. intentional resource optimization

Together they shorten feedback cycles, lower infra cost, and improve test reliability.
