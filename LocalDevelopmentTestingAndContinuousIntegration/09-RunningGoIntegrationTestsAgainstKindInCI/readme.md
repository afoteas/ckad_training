# Running Go Integration Tests Against kind in CI

This guide demonstrates how to set up and run Go integration tests against a kind cluster in CI/CD pipelines.

## CI Pipeline Setup

```yaml
# GitHub Actions example
name: Integration Tests

on: [push, pull_request]

jobs:
  integration-tests:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Create kind cluster
      uses: helm/kind-action@v1.7.0
      with:
        cluster_name: test-cluster
        
    - name: Build image
      run: docker build -t my-app:test .
      
    - name: Load image into kind
      run: kind load docker-image my-app:test --name test-cluster
      
    - name: Run integration tests
      run: go test ./... -tags=integration -v -timeout=10m
```

## Kind Cluster Creation

```bash
# Create cluster in CI
kind create cluster --name ci-test

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

## Load Docker Image Into kind

```bash
# Build image locally
docker build -t my-app:test .

# Load into kind cluster
kind load docker-image my-app:test --name ci-test

# Verify image availability
kubectl describe nodes
```

## Go Test Tags

```go
// +build integration

package integration

import "testing"

func TestWithRealCluster(t *testing.T) {
  // This test only runs with -tags=integration
}
```

## Run Tests in CI

```bash
# Run only integration tests
go test ./... -tags=integration -v

# With timeout
go test ./... -tags=integration -v -timeout=10m

# With coverage
go test ./... -tags=integration -v -coverprofile=coverage.out

# Specific test function
go test ./... -tags=integration -run TestSpecific -v
```

## CI Best Practices

1. **Resource limits**: Set memory/CPU limits for kind
2. **Timeout handling**: Include generous timeouts for pod startup
3. **Image preloading**: Load common images before tests run
4. **Log capture**: Collect cluster logs on failure
5. **Cleanup**: Always delete cluster after tests

## Capture Cluster Logs on Failure

```bash
#!/bin/bash
if [ $? -ne 0 ]; then
  echo "Tests failed, collecting logs..."
  kubectl logs -A --all-containers=true > /tmp/cluster-logs.txt
  kind export logs /tmp/kind-logs
fi
```

## Example CI Configuration

```yaml
test:
  stage: test
  script:
    - kind create cluster --config kind-config.yaml
    - docker build -t app:test .
    - kind load docker-image app:test
    - go test ./... -tags=integration -v -timeout=15m
  after_script:
    - kind delete cluster
```

## Debugging Failed Tests

```bash
# Check pod status
kubectl get pods -A

# View pod logs
kubectl logs <pod-name> -n <namespace>

# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>

# Check cluster events
kubectl get events -A
```
