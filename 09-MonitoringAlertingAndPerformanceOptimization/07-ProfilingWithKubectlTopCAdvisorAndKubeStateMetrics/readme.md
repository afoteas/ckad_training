# Profiling with kubectl top, cAdvisor, and kube-state-metrics

Profiling measures how much CPU, memory, and network resources applications actually consume, enabling right-sizing and early detection of resource exhaustion.

## Three-Layer Toolchain

### 1. kubectl top — immediate snapshot

```bash
# Pod-level CPU and memory in the current namespace
kubectl top pod

# Node-level CPU and memory across all worker machines
kubectl top node

# Target a specific namespace
kubectl top pod --namespace my-app
```

Use `kubectl top` as the first command when a user reports slowness. If a node is at 95% CPU, you have a capacity problem before you need to dig any deeper.

### 2. cAdvisor — granular container metrics

cAdvisor (Container Advisor) runs natively inside the kubelet on every node. It introspects running containers using kernel-level cgroup statistics and reports:

- per-container CPU usage over time
- per-container memory consumption
- disk read/write rates

cAdvisor is the upstream data source for Metrics Server, which powers `kubectl top`. Query it directly via Prometheus for historical trends and multi-container pod analysis.

Key cAdvisor metrics in Prometheus:

```promql
# CPU rate for a specific container
rate(container_cpu_usage_seconds_total{container="myapp"}[5m])

# Memory usage
container_memory_usage_bytes{container="myapp"}

# Filesystem writes
rate(container_fs_writes_bytes_total{container="myapp"}[5m])
```

### 3. kube-state-metrics (KSM) — Kubernetes object state

KSM listens to the API server and converts object state into Prometheus metrics. It answers questions about *what* is configured, not how much resource is being used:

```promql
# Number of available replicas for a Deployment
kube_deployment_status_replicas_available{deployment="myapp"}

# Pod phase
kube_pod_status_phase{pod="myapp-abc123", phase="Running"}

# Configured memory request
kube_pod_container_resource_requests{resource="memory", container="myapp"}
```

## Diagnostic Workflow

1. **kubectl top** → identify the suspect pod or node
2. **cAdvisor metrics in Prometheus** → drill into historical CPU/memory trends for that container; identify spikes correlated with events
3. **kube-state-metrics** → correlate usage data with configured limits and requests; determine if a spike is a misconfigured limit or a genuine leak

## Right-sizing

Without profiling, developers over-provision. With the full workflow:

- use cAdvisor data to find the 95th percentile CPU and memory over a representative period
- set `resources.requests` to the typical usage and `resources.limits` slightly above the spike value
- re-evaluate after the next deployment
