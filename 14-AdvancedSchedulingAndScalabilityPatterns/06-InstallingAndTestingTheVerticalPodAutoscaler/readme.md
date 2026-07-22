# Installing and Testing the Vertical Pod Autoscaler

This lesson walks through installing VPA on a local cluster, deploying a workload with undersized resource requests, and watching VPA automatically right-size CPU and memory based on actual usage.

For VPA theory and update modes, see module 12 [10-VerticalPodAutoscalingBasics](../../12-ResourceLimitsSchedulingAndAutoscaling/10-VerticalPodAutoscalingBasics/readme.md).

## Why VPA Matters

Developers often guess resource requests when deploying. This leads to:

- **Overprovisioning** — wasted cluster capacity and higher cloud costs.
- **Underprovisioning** — OOM kills, throttling, and outages.

Resource needs also change over time as traffic patterns shift. VPA observes actual usage and adjusts requests automatically.

## VPA Components

| Component | Role |
|-----------|------|
| **Recommender** | Analyzes resource usage and generates recommendations |
| **Updater** | Evicts Pods that need resource updates |
| **Admission Controller** | Injects recommended resources into newly created Pods |

## Update Modes

| Mode | Behavior |
|------|----------|
| `Off` | Recommendations only — no changes applied (good for testing) |
| `Initial` | Sets resources on Pod creation only; never updates running Pods |
| `Recreate` | Evicts and recreates Pods with new resources (common default) |
| `Auto` | Automatically chooses strategy — typically same as `Recreate` |

## How VPA Works (Step by Step)

1. Recommender monitors resource usage metrics.
2. It calculates optimal CPU and memory based on usage patterns.
3. In `Auto` or `Recreate` mode, the updater evicts Pods needing updates.
4. The admission controller injects new resource values when Pods recreate.
5. The cycle repeats continuously as workloads change.

## Prerequisites

- Docker, `kubectl`, Minikube, and `git`
- VPA is **not** included in core Kubernetes — install separately

## Step 1: Start Minikube

```bash
minikube start --driver=docker
```

## Step 2: Install VPA

```bash
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler
./hack/vpa-up.sh
```

This installs VPA CRDs, the recommender, updater, and admission controller.

Verify:

```bash
kubectl get pods -n kube-system | grep vpa
```

You should see the admission controller, recommender, and updater running.

## Step 3: Deploy Application with VPA

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hamster
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hamster
  template:
    metadata:
      labels:
        app: hamster
    spec:
      containers:
      - name: hamster
        image: registry.k8s.io/ubuntu-slim:0.14
        command: ["/bin/sh", "-c", "while true; do timeout 0.5 yes >/dev/null; sleep 0.5; done"]
        resources:
          requests:
            cpu: 100m
            memory: 50Mi
---
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: hamster-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: hamster
  updatePolicy:
    updateMode: "Auto"
```

```bash
kubectl apply -f vpa-demo-app.yaml
kubectl get pods -l app=hamster
```

Initial requests: `100m` CPU, `50Mi` memory.

## Step 4: Monitor Recommendations

VPA needs 1–3 minutes to gather metrics:

```bash
kubectl describe vpa hamster-vpa
```

Look for the **Recommendation** section:

```text
Container Recommendations:
  Container Name: hamster
    Lower Bound:
      cpu:     100m
      memory:  250Mi
    Target:
      cpu:     100m
      memory:  250Mi
    Upper Bound:
      cpu:     100m
      memory:  250Mi
```

In this demo, VPA recommends increasing memory from `50Mi` to `250Mi`.

## Step 5: Watch Automatic Updates

```bash
kubectl get pods -l app=hamster -w
```

VPA evicts Pods and recreates them with updated resources. Check events:

```bash
kubectl get events --sort-by='.lastTimestamp' | grep -i vpa
```

Verify updated requests:

```bash
kubectl get pods -l app=hamster -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].resources.requests}{"\n"}{end}'
```

Memory should now show `250Mi` instead of `50Mi`.

## VPA Recommendation Fields

| Field | Meaning |
|-------|---------|
| `Lower Bound` | Minimum safe resource value |
| `Target` | Recommended resource value |
| `Upper Bound` | Maximum safe resource value |
| `Uncapped Target` | What VPA would recommend without policy limits |

## Real-World Benefits

- Prevents overprovisioning — can reduce cloud costs by 20–50%.
- Prevents underprovisioning — fewer OOM kills and performance issues.
- Continuous optimization without manual intervention.
- Developers no longer need to guess resource values.

## Useful Commands

```bash
kubectl get vpa
kubectl describe vpa <vpa-name>
kubectl get pods -n kube-system | grep vpa
kubectl get events --sort-by='.lastTimestamp' | grep -i vpa
```

## CKAD Note

VPA is not a core CKAD hands-on topic. Know conceptually:

- VPA adjusts **requests/limits**, not replica count.
- Update modes: `Off`, `Initial`, `Recreate`, `Auto`.
- VPA requires separate installation — it is not built into Kubernetes.

## Key Takeaway

VPA observes actual resource usage and automatically right-sizes Pod requests. Install it separately, start with `Off` to review recommendations, then enable `Auto` for continuous optimization.
