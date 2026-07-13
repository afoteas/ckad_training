# Choose the Right Local Cluster: Minikube and kind

This guide helps you decide between minikube and kind based on your local development needs.

## Comparison

| Feature | kind | minikube |
|---------|------|----------|
| **Startup Time** | Very fast (seconds) | Slower (minutes) |
| **Resource Usage** | Lightweight (Docker) | Heavier (VMs) |
| **Addons** | Minimal | Many built-in addons |
| **Best For** | CI/CD, quick testing | Full dev environment |
| **Networking** | Container-based | VM-based |
| **Node Count** | Easy multi-node | Can be multi-node |

## When to Use kind

- Running integration tests in CI pipelines
- Rapid cluster creation and teardown
- Testing multi-node scenarios quickly
- Container-first development workflow

## When to Use minikube

- Need ingress controller out-of-the-box
- Want metrics-server for HPA testing
- Prefer VM isolation
- Need stable, feature-rich local environment

## Verify Your Cluster

Always verify your current context before applying manifests:

```bash
# Check current context
kubectl config current-context

# List available contexts
kubectl config get-contexts

# Get cluster info
kubectl get nodes
kubectl get pods -A
```

## Workflow Tips

1. Set a default context to avoid mistakes
2. Always verify cluster before deploying
3. Use namespace isolation for testing
4. Clean up resources after testing
