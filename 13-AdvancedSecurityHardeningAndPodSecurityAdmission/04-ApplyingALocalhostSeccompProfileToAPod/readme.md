# Applying a Localhost seccomp Profile to a Pod

This lesson demonstrates how to mount a custom seccomp profile on a node and apply it to a Pod using `type: Localhost`.

For background on seccomp profile types, see [03-SeccompAndAppArmorProfiles](../03-SeccompAndAppArmorProfiles/readme.md).

## Demo Files

- `custom-profile.json` — allows common syscalls but blocks network bind
- `restrictive-profile.json` — minimal syscall allow list
- `audit-profile.json` — logs denied syscalls instead of blocking
- `default-seccomp-pod.yaml` — uses `RuntimeDefault`
- `custom-seccomp-pod.yaml` — uses `Localhost` custom profile

## What seccomp Does

**seccomp** (secure computing mode) restricts which **syscalls** a process can make. Syscalls are how programs interact with the Linux kernel (read/write files, open sockets, create processes).

Benefits:

- **Reduce attack surface** — fewer syscalls means fewer vulnerabilities
- **Prevent privilege escalation** — block dangerous kernel interfaces
- **Limit damage** from compromised containers

## seccomp Profile Types

| Type | Description |
|------|-------------|
| `Unconfined` | No restrictions |
| `RuntimeDefault` | Container runtime's default profile |
| `Localhost` | Custom profile loaded from the node's filesystem |

### Preferred config: `securityContext` vs annotations

Always reference seccomp profiles via `securityContext.seccompProfile` — not annotations:

```yaml
# Preferred
securityContext:
  seccompProfile:
    type: Localhost
    localhostProfile: custom-profile.json
```

Legacy annotation form (`seccomp.security.alpha.kubernetes.io/...`) is deprecated and does not satisfy PSA `restricted`. See [03-SeccompAndAppArmorProfiles](../03-SeccompAndAppArmorProfiles/readme.md) for the full comparison.

## Profile JSON Structure

Custom profiles are JSON files with a syscall allow list and a default action for anything not listed:

```json
{
  "defaultAction": "ERRNO",
  "syscalls": [
    {
      "names": ["read", "write", "open", "close"],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

| Field | Purpose |
|-------|---------|
| `defaultAction` | What happens when a syscall is **not** in the allow list (`ERRNO` = return error, `LOG` = log only) |
| `syscalls[].names` | Syscalls explicitly allowed |
| `syscalls[].action` | `SCMP_ACT_ALLOW` permits the listed syscalls |

## Step 1: Inspect the Node seccomp Directory

Custom profiles must exist on **every node** that can run the Pod, at `/var/lib/kubelet/seccomp/`.

### kind

List kind node containers (replace `ckad` with your cluster name):

```bash
kind get nodes --name ckad
```

Inspect the seccomp directory on a node:

```bash
docker exec ckad-control-plane ls -la /var/lib/kubelet/seccomp
```

Initially this directory may be empty or missing. Create it before copying profiles.

### minikube

SSH into the node and list the seccomp directory:

```bash
minikube ssh -- sudo ls -la /var/lib/kubelet/seccomp
```

## Step 2: Copy Profiles to the Node

### kind

Copy each profile to **every** kind node (control-plane and workers). Pods can land on any worker:

```bash
CLUSTER=ckad   # change to your cluster name

for node in $(kind get nodes --name "$CLUSTER"); do
  docker exec "$node" mkdir -p /var/lib/kubelet/seccomp
  docker cp custom-profile.json "${node}:/var/lib/kubelet/seccomp/custom-profile.json"
  docker cp restrictive-profile.json "${node}:/var/lib/kubelet/seccomp/restrictive-profile.json"
  docker cp audit-profile.json "${node}:/var/lib/kubelet/seccomp/audit-profile.json"
done
```

Verify on one node:

```bash
docker exec ckad-control-plane ls -la /var/lib/kubelet/seccomp
docker exec ckad-control-plane cat /var/lib/kubelet/seccomp/custom-profile.json
```

### minikube

Copy each profile from your local machine to the minikube node:

```bash
minikube cp custom-profile.json /var/lib/kubelet/seccomp/custom-profile.json
minikube cp restrictive-profile.json /var/lib/kubelet/seccomp/restrictive-profile.json
minikube cp audit-profile.json /var/lib/kubelet/seccomp/audit-profile.json
```

Verify the files are present:

```bash
minikube ssh -- sudo ls -la /var/lib/kubelet/seccomp
minikube ssh -- sudo cat /var/lib/kubelet/seccomp/custom-profile.json
```

## Step 3: Test RuntimeDefault Profile

Deploy a Pod using the runtime's default seccomp profile:

```bash
kubectl apply -f default-seccomp-pod.yaml
kubectl get pod default-seccomp-pod
kubectl logs default-seccomp-pod
```

Expected behavior: all common operations succeed (list files, get date, etc.).

Verify the seccomp configuration:

```bash
kubectl get pod default-seccomp-pod -o jsonpath='{.spec.securityContext.seccompProfile}'
```

Expected output: `{"type":"RuntimeDefault"}`

Test syscalls interactively:

```bash
kubectl exec -it default-seccomp-pod -- sh
# Inside the container:
ls -la /
date
echo "hello"
exit
```

## Step 4: Test Localhost Custom Profile

Deploy a Pod referencing the custom profile:

```bash
kubectl apply -f custom-seccomp-pod.yaml
kubectl get pod custom-seccomp-pod
kubectl describe pod custom-seccomp-pod
```

The Pod spec uses:

```yaml
securityContext:
  seccompProfile:
    type: Localhost
    localhostProfile: custom-profile.json
```

`Localhost` tells Kubernetes to load the profile from `/var/lib/kubelet/seccomp/` on the node.

Verify configuration:

```bash
kubectl get pod custom-seccomp-pod -o jsonpath='{.spec.securityContext.seccompProfile}'
```

Expected output includes `localhostProfile: custom-profile.json`.

## Step 5: Observe Blocked Syscalls

The custom profile **does not include network bind syscalls**. The Pod tries to listen on port 8080 with `nc -l -p 8080`, which triggers blocked syscalls.

Expected behavior: Pod enters **CrashLoopBackOff** because the bind syscall is denied.

```bash
kubectl get pod custom-seccomp-pod
kubectl logs custom-seccomp-pod
```

This demonstrates the profile working — the container cannot perform operations outside its allow list.

## Optional Cleanup

```bash
kubectl delete -f default-seccomp-pod.yaml
kubectl delete -f custom-seccomp-pod.yaml
```

## Key Takeaway

`Localhost` seccomp profiles let you define fine-grained syscall restrictions beyond the runtime default. Copy the JSON to every node (all kind workers or the minikube node), reference it in `securityContext.seccompProfile`, and test thoroughly before enforcing in production.
