# Attaching an Ephemeral Container to Inspect Environment

This lesson demonstrates a practical debugging workflow with BusyBox sidecar-style inspection patterns and shell-based checks.

## Sidecar Debug Pattern

Use an extra container in the same pod to inspect shared files and network namespace.

Benefits:

- shared network namespace (`localhost` communication)
- access to shared mounted volumes
- low-overhead troubleshooting tools with BusyBox

## Example Verification Steps

```bash
kubectl apply -f myapp-with-sidecar.yaml
kubectl get pod myapp-with-sidecar
kubectl get pod myapp-with-sidecar -o jsonpath='{.spec.containers[*].name}'
kubectl get pod myapp-with-sidecar -o jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}'
kubectl exec -it myapp-with-sidecar -c busybox-sidecar -- sh
```

Inside container, inspect:

```bash
ls -la /
env
wget -qO- http://localhost
ps aux
```

## Important Behavior

- process visibility remains container-scoped unless explicitly shared
- if the debug container is not in pod spec, it cannot be exec'd directly
- for existing pods, use `kubectl debug` to inject ephemeral container

## Sidecar vs Ephemeral Debug

Both approaches help troubleshoot workloads, but they are used at different times.

| Topic | Sidecar Debug Container | Ephemeral Debug Container |
|---|---|---|
| When added | Defined in pod spec before pod starts | Injected into an already running pod |
| Lifetime | Runs as long as the pod runs | Temporary, for active troubleshooting |
| Restart behavior | Restarted by normal pod restart policy | Not restarted automatically after exit |
| Resource overhead | Continuous overhead (CPU/memory reservation) | Minimal long-term overhead |
| Best use case | Repeated/always-on inspection and helper tasks | One-off live debugging of existing pods |
| Requires pod rollout | Yes, if not already present in spec | No rollout needed |
| Can be exec'd directly | Yes (`kubectl exec -c <name>`) | Yes, after injection via `kubectl debug` |

Typical commands:

```bash
# Sidecar approach (predefined in manifest)
kubectl exec -it myapp-with-sidecar -c busybox-sidecar -- sh

# Ephemeral approach (inject into existing pod)
kubectl debug -it myapp-with-sidecar --image=busybox:latest --target=nginx -- sh
```

Rule of thumb:

- use sidecar when you want persistent helper/debug capability
- use ephemeral container for fast, temporary diagnostics on live pods

## CKAD Tips

- Exec into a specific container by name: `kubectl exec -it <pod> -c <container> -- sh` — the `-c` flag is required for multi-container pods.
- List container names quickly with `kubectl get pod <pod> -o jsonpath='{.spec.containers[*].name}'` when you're unsure which `-c` value to use.
- Containers in the same pod share the network namespace (talk over `localhost`) and mounted volumes, but process visibility stays container-scoped unless `shareProcessNamespace` is set.
- If a container isn't in the pod spec, you can't `exec` into it — inject one with `kubectl debug -it <pod> --image=busybox --target=<container> -- sh`.
- Inside a debug shell, `env`, `ls -la /`, `wget -qO-`, and `ps aux` cover most quick environment inspections.

## Key Takeaway

Sidecar containers (declared in the spec, always-on) and ephemeral debug containers (injected on demand) both leverage shared pod namespaces to inspect a running app — choose sidecars for persistent helpers and ephemeral containers for one-off live diagnostics.