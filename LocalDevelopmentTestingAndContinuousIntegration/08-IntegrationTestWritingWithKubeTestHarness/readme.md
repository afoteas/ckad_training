# Integration Test Writing with Kube Test Harness

This guide explains why Kubernetes integration tests matter and how to run them with a kube test harness approach.

## Why Integration Tests on Kubernetes

Unit tests are valuable, but they validate components in isolation. Kubernetes behavior often depends on how resources interact inside a real cluster.

Examples of issues unit tests typically miss:

- Deployment, Service, and Pod wiring mistakes
- label/selector mismatches
- manifest misconfigurations
- readiness or rollout behavior problems
- ConfigMap and runtime environment wiring issues

Integration tests validate the full manifest flow end-to-end in a real cluster so these errors are detected before production.

## What Kube Test Harness Gives You

A kube test harness framework helps you automate Kubernetes integration testing by:

- creating a temporary test cluster programmatically
- applying manifests under test
- running assertions on cluster state
- cleaning up the cluster automatically after the test run

The key advantage is repeatability: every run starts from a clean, isolated environment.

## Core Testing Workflow

A typical flow looks like this:

1. Start a temporary cluster (often kind).
2. Apply manifests under test (Deployments, Services, and related resources).
3. Assert resource state (for example, pods running, rollout successful).
4. Tear down the cluster when tests complete.

This model works well for local development and CI pipelines.

## Example Test Flow

The following example shows the pattern described in this lesson: create harness, apply manifest, wait for pods, then clean up.

```go
package integration

import (
  "testing"
)

func TestDeploymentComesUp(t *testing.T) {
  h := NewHarness(t) // Creates and manages an ephemeral test cluster lifecycle

  // Apply manifests under test (for example, testdata/deployment.yaml)
  if err := h.ApplyFile("testdata/deployment.yaml"); err != nil {
    t.Fatalf("apply failed: %v", err)
  }

  // Assert expected runtime behavior in the cluster
  if err := h.WaitForPodsRunning("default", 3); err != nil {
    t.Fatalf("pods not running as expected: %v", err)
  }
}
```

Notes:

- `ApplyFile` loads and applies manifests from test data.
- `WaitForPodsRunning` validates that expected pods reach Running state.
- Harness teardown ensures each test run starts fresh.

## Benefits

- catches Kubernetes wiring mistakes before production
- validates real cluster behavior, not static assumptions
- automates cluster setup and teardown in tests
- fits naturally into CI/CD pipelines

## Trade-Offs

Integration tests require more resources and runtime than unit tests.

- cluster startup takes time
- assertions may need polling and timeouts
- CI jobs require extra CPU/memory

For Kubernetes workloads, this cost is usually worth it because confidence and reliability increase significantly.

## CI/CD Usage Pattern

In CI (for example, GitHub Actions), the common pattern is:

1. spin up ephemeral cluster
2. run integration test suite
3. collect logs/artifacts on failures
4. tear down cluster automatically

This prevents manual intervention and keeps every pipeline run deterministic.

## Recommended Use Cases

Use these tests especially for:

- critical workloads
- custom controllers/operators
- services with strict availability or rollout requirements
- changes touching manifests, probes, labels/selectors, or networking

## Summary

Kubernetes integration tests with a kube test harness help you catch real cluster issues early, improve deployment safety, and reduce costly production failures.
