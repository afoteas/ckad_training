# Running Go Integration Tests Against kind in CI

This guide shows a practical GitHub Actions workflow that creates a kind cluster, runs Go integration tests against that real cluster, and exports test results as JUnit XML.

## Why This CI Pattern

For Kubernetes workloads, integration tests catch issues that unit tests miss, such as:

- manifest wiring mistakes
- Service/Deployment selector mismatches
- readiness and rollout behavior
- runtime interactions between resources

kind is ideal in CI because it creates a disposable cluster quickly on the runner and can be deleted automatically after tests.

## End-to-End Workflow

The job sequence is:

1. trigger on push/pull request
2. checkout repository
3. install Go
4. install kind and kubectl
5. create kind cluster
6. build and load Docker image into kind
7. apply Kubernetes test manifests
8. run Go integration tests
9. export JUnit XML
10. collect cluster diagnostics on failure
11. always delete cluster

## Workflow Implementation Notes

The CI job should include these logical stages in order:

1. checkout code
2. setup Go toolchain
3. install kind and kubectl
4. create kind cluster
5. build and load image into cluster
6. apply test manifests
7. run integration tests and generate JUnit XML
8. publish test report artifact
9. collect diagnostics only on failure
10. always delete the kind cluster

## Local-to-CI Mapping

These CI steps mirror local commands exactly:

```bash
kind create cluster --name ci
docker build -t my-app:ci .
kind load docker-image my-app:ci --name ci
kubectl apply -f k8s/test-deployment.yaml
go test ./... -tags=integration -v -timeout=15m
kind delete cluster --name ci
```

## Operational Tips

- keep integration tests deterministic
- use explicit timeouts for rollout and tests
- upload JUnit artifacts for every run
- collect diagnostics only on failure to reduce noise
- always clean up to avoid flaky follow-up jobs

## Summary

This approach gives you reliable Kubernetes integration validation in GitHub Actions using an ephemeral kind cluster, real Go integration tests, standardized JUnit results, and guaranteed teardown.
