# Pod Lifecycle & Failure States

This lesson explains pod lifecycle, pod phases, container states, and common failure conditions you will see during day-to-day Kubernetes troubleshooting.

## Pod Lifecycle Basics

- a Pod is the smallest deployable unit in Kubernetes
- controllers and kubelet drive lifecycle transitions
- observability comes from status fields and cluster events

Typical flow:

1. Pod created
2. Pod scheduled to a node
3. Containers start
4. Pod runs or fails
5. Pod terminates

## Pod Phases

- `Pending`: accepted but not started yet (image pull, scheduling, or resource wait)
- `Running`: all containers created and at least one is running
- `Succeeded`: all containers completed successfully
- `Failed`: one or more containers terminated with error

## Container States

Each container in a pod has its own state:

- `Waiting`
- `Running`
- `Terminated`

## Common Failure Conditions

- `CrashLoopBackOff`: container starts, crashes, and restarts repeatedly
- `ImagePullBackOff`: image cannot be pulled
- `OOMKilled`: container exceeded memory limit
- `Pending` for long periods: scheduling/resource constraints
- unexpected `Completed`: workload type may be misconfigured

## Core Troubleshooting Commands

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl get events --sort-by='.lastTimestamp'
```

These three commands are the base toolkit for startup and runtime failure debugging.

## CKAD Tips

- Read the pod `phase` (`Pending`/`Running`/`Succeeded`/`Failed`) and per-container state (`Waiting`/`Running`/`Terminated`) separately — a `Running` pod can still hold a crashing container.
- `kubectl describe pod <pod>` shows the `Reason` (e.g. `CrashLoopBackOff`, `ImagePullBackOff`, `OOMKilled`) and recent events; it's your first stop under exam time pressure.
- Use `kubectl get events --sort-by='.lastTimestamp'` to get a chronological failure timeline instead of scrolling raw output.
- Add `-c <container-name>` to `kubectl logs` for multi-container pods, and `--previous` to see logs from the last crashed instance.
- `Pending` usually means scheduling/resource waits, while `OOMKilled` points to a too-low memory `limits` value — check the right signal for the right symptom.

## Key Takeaway

Kubernetes exposes failure through pod phases, container states, and events; mastering `describe`, `logs`, and sorted `events` lets you quickly map a symptom to its root cause.