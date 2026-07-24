# Using kubectl logs and Events to Debug Apps

This lesson covers a practical troubleshooting sequence for failing pods and deployments.

## Step-by-Step Debug Flow

### 1) Identify failing resources

```bash
kubectl get pods
kubectl get pods -A
```

### 2) Inspect details and events

```bash
kubectl describe pod <pod-name>
```

Look for `State`, `Reason`, and recent `Events`.

### 3) Inspect logs

```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
kubectl logs <pod-name> -c <container-name>
```

### 4) Check cluster events timeline

```bash
kubectl get events --sort-by=.metadata.creationTimestamp
```

This sequence quickly surfaces common causes such as image pull failures, probe failures, and scheduling/resource constraints.

## How to Run (This Lesson)

Deploy the demo workload:

```bash
kubectl apply -f deployment-with-startup-probes.yaml
kubectl get pods -l app=slow-start-app -w
```

Debug with logs and events:

```bash
kubectl describe pod -l app=slow-start-app
kubectl logs -l app=slow-start-app --tail=100
kubectl get events --sort-by=.metadata.creationTimestamp | tail -n 30
```

Cleanup:

```bash
kubectl delete -f deployment-with-startup-probes.yaml
```

## CKAD Tips

- Learn the debug loop by heart: `kubectl get pods` → `kubectl describe pod <name>` (read `State`, `Reason`, `Events`) → `kubectl logs <name>` → `kubectl get events`.
- `kubectl logs <pod> --previous` reveals why a container crashed and restarted — essential for diagnosing `CrashLoopBackOff`.
- Sort events chronologically with `kubectl get events --sort-by=.metadata.creationTimestamp` to build a failure timeline.
- The `Events` section of `kubectl describe` surfaces the most common exam causes: `ImagePullBackOff`, probe failures, and `FailedScheduling` due to resource/affinity constraints.
- Add `-c <container>` to `kubectl logs` for multi-container pods, and `-A` / `-n <ns>` when the failing pod is in another namespace.

## Key Takeaway

A disciplined `get → describe → logs → events` sequence is the fastest way to root-cause failing pods, and mastering it is directly tested by CKAD troubleshooting tasks.
