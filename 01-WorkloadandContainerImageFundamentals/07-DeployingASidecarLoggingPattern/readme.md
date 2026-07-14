# Sidecar for Logging
```
kubectl apply -f sidecar-deployment.yaml
```

## What I did

### 1. Reproduced and inspected the failure
I first checked pod status and saw one container failing (`1/2 RunContainerError`).

```bash
kubectl get pods
```

Then I inspected the failing pod events and container state:

```bash
kubectl describe pod logging-sidecar-demo-7cf695b57-n6pmj
```

Root cause from `describe` output:

```text
exec: "/usr/bin/tail": stat /usr/bin/tail: no such file or directory
```

I also checked previous sidecar logs:

```bash
kubectl logs logging-sidecar-demo-7cf695b57-n6pmj -c log-collector --previous
```

### 2. Fix applied in manifest
The sidecar was using `/usr/bin/tail`, which does not exist in `busybox:latest`.
I changed the sidecar command to run via `/bin/sh -c` and tail the shared log file safely:

```yaml
command: ["/bin/sh", "-c"]
args: ["touch /mnt/logs/app.log && tail -f /mnt/logs/app.log"]
```

### 3. Applied and verified

```bash
kubectl apply -f ./sidecar-deployment.yaml
kubectl rollout status deployment/logging-sidecar-demo
kubectl get pods -l app=sidecar-demo -o wide
kubectl logs deployment/logging-sidecar-demo -c log-collector --tail=5
```

Verification result:
- New pod became `2/2 Running`.
- Sidecar logs showed live entries from `/mnt/logs/app.log`.