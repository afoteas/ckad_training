# Integration Test Writing with kube-test-harness

This guide shows how to write integration tests against real Kubernetes clusters using testing patterns and harnesses.

## Overview

Integration tests verify that your application works correctly within a real Kubernetes environment, not just in unit test mocks. This requires proper cluster setup, fixture management, and cleanup.

## Test Structure

```go
package integration

import (
  "context"
  "testing"
  
  corev1 "k8s.io/api/core/v1"
  metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
  "k8s.io/client-go/kubernetes"
)

func TestMyApp(t *testing.T) {
  // Setup: Create test namespace
  namespace := "test-" + randomString()
  
  // Arrange: Deploy dependencies
  createNamespace(t, namespace)
  deployApp(t, namespace)
  
  // Act: Test functionality
  result := testAppBehavior(t, namespace)
  
  // Assert: Verify results
  if !result.Success {
    t.Fatalf("Expected success, got failure")
  }
  
  // Cleanup: Delete all resources
  deleteNamespace(t, namespace)
}
```

## Test Fixtures

```go
func setupTestFixture(t *testing.T, namespace string) {
  // Create ConfigMap
  cm := &corev1.ConfigMap{
    ObjectMeta: metav1.ObjectMeta{
      Name:      "app-config",
      Namespace: namespace,
    },
    Data: map[string]string{
      "key": "value",
    },
  }
  _, err := clientset.CoreV1().ConfigMaps(namespace).Create(context.Background(), cm, metav1.CreateOptions{})
  if err != nil {
    t.Fatalf("Failed to create configmap: %v", err)
  }
}
```

## Kubernetes Client Usage

```go
import (
  "k8s.io/client-go/kubernetes"
  "k8s.io/client-go/tools/clientcmd"
)

func getTestClient() (kubernetes.Interface, error) {
  kubeconfig := os.Getenv("KUBECONFIG")
  config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
  if err != nil {
    return nil, err
  }
  return kubernetes.NewForConfig(config)
}
```

## Best Practices

1. **Isolation**: Each test uses its own namespace
2. **Cleanup**: Always delete test resources after completion
3. **Timeouts**: Set reasonable timeouts for pod readiness
4. **Error Handling**: Log detailed errors for debugging
5. **Parallel Testing**: Use separate namespaces for parallel tests

## Resource Cleanup

```go
func cleanup(t *testing.T, clientset kubernetes.Interface, namespace string) {
  err := clientset.CoreV1().Namespaces().Delete(
    context.Background(),
    namespace,
    metav1.DeleteOptions{},
  )
  if err != nil {
    t.Logf("Warning: Failed to delete namespace: %v", err)
  }
}
```

## Common Patterns

- **Wait for readiness**: Poll pod status until ready
- **Port forwarding**: Test internal services
- **Log collection**: Capture logs for debugging
- **Resource validation**: Verify expected resources created
