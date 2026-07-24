# Enforcing Restricted Policy in a Namespace

This lesson demonstrates how to label a namespace to enforce the `restricted` Pod Security Standard and test compliant vs non-compliant Pods.

For background on PSA modes and standards, see [01-PodSecurityAdmissionAndStandards](../01-PodSecurityAdmissionAndStandards/readme.md).

## Demo Files

- `restricted-namespace.yaml`
- `compliant-pod.yaml`
- `privileged-pod.yaml`

## Pod Security Standards Recap

PSS are built-in policies that define security restrictions for Pods. They replace the older PodSecurityPolicy (PSP) and help:

- Prevent Pods from running with excessive privileges
- Protect the cluster from compromised containers
- Enforce security best practices
- Reduce attack surface

| Level | Description |
|-------|-------------|
| `privileged` | Unrestricted — system-level and trusted workloads |
| `baseline` | Minimally restrictive — prevents known privilege escalations |
| `restricted` | Most secure — non-root, dropped capabilities, no privileged containers |

You can enable `enforce`, `audit`, and `warn` modes simultaneously on the same namespace.

## Step 1: Create an Unrestricted Namespace

Create a baseline namespace with no security restrictions (default behavior):

```bash
kubectl create namespace test-baseline
```

## Step 2: Create and Label a Restricted Namespace

Create the restricted namespace:

```bash
kubectl create namespace test-restricted
```

Label it with all three PSA modes set to `restricted`:

```bash
kubectl label namespace test-restricted \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

Or apply the YAML file:

```bash
kubectl apply -f restricted-namespace.yaml
```

| Label | Effect |
|-------|--------|
| `enforce=restricted` | Blocks non-compliant Pods |
| `audit=restricted` | Logs violations |
| `warn=restricted` | Warns users about violations |

## Step 3: Verify Namespace Labels

```bash
kubectl get namespace test-restricted -o yaml
kubectl get namespace test-restricted --show-labels
```

Expected output includes:

```text
pod-security.kubernetes.io/enforce=restricted
pod-security.kubernetes.io/audit=restricted
pod-security.kubernetes.io/warn=restricted
```

## Step 4: Deploy a Compliant Pod

```bash
kubectl apply -f compliant-pod.yaml -n test-restricted
kubectl get pods -n test-restricted
```

Expected behavior: Pod is **admitted** and reaches `Running` state.

Inspect the security settings:

```bash
kubectl get pod compliant-pod -n test-restricted -o yaml
```

Compliant `restricted` settings in this Pod:

| Setting | Value | Purpose |
|---------|-------|---------|
| `runAsNonRoot` | `true` | Pod must not run as root |
| `runAsUser` | `1000` | Runs as a non-root UID |
| `seccompProfile.type` | `RuntimeDefault` | Required by `restricted` — cannot use `Unconfined` |
| `allowPrivilegeEscalation` | `false` | Prevents gaining more privileges |
| `capabilities.drop` | `["ALL"]` | Drops all Linux capabilities |

This demo uses `busybox` with `sleep 3600` as a minimal workload. The focus is the `securityContext` fields required by `restricted`, not the application image itself.

### Why not `nginx:1.25`?

A manifest with the same `securityContext` but `image: nginx:1.25` is **admitted** by PSA — it satisfies all `restricted` admission rules. It will still fail at runtime with `CrashLoopBackOff`:

```text
mkdir() "/var/cache/nginx/client_temp" failed (13: Permission denied)
```

Stock nginx expects to run as root (or a dedicated `nginx` user with pre-created directories). With `runAsUser: 1000` and `capabilities.drop: ["ALL"]`, the container cannot:

1. **Write cache directories** — `/var/cache/nginx` is owned by root inside the image.
2. **Bind to port 80** — ports below 1024 require `CAP_NET_BIND_SERVICE`, which `restricted` forbids when all capabilities are dropped.

PSA checks the manifest at **admission time**; it does not validate whether the chosen image can actually start under those constraints.

For a real nginx workload under `restricted`, use an image built for non-root operation (for example `nginxinc/nginx-unprivileged`, which listens on port 8080 and runs as UID `101`) or add writable `emptyDir` volume mounts and configure nginx to listen on a high port.

## Step 5: Deploy a Non-Compliant Pod (Restricted Namespace)

```bash
kubectl apply -f privileged-pod.yaml -n test-restricted
```

Expected behavior: Pod creation is **forbidden**.

Example error:

```text
Error: pods "privileged-pod" is forbidden: violates PodSecurity "restricted:latest":
  privileged (container "app" must not set securityContext.privileged=true)
  allowPrivilegeEscalation != false (container "app" must set
  securityContext.allowPrivilegeEscalation=false)
```

The error tells you exactly which policy was violated and what to change in the YAML.

## Step 6: Deploy the Same Pod in the Unrestricted Namespace

```bash
kubectl apply -f privileged-pod.yaml -n test-baseline
kubectl get pods -n test-baseline
```

Expected behavior: Pod is **created successfully** — `test-baseline` has no PSA restrictions.

## Optional Cleanup

```bash
kubectl delete pod compliant-pod -n test-restricted
kubectl delete pod privileged-pod -n test-baseline
kubectl delete namespace test-baseline test-restricted
```

## CKAD Tips

- Create and label a namespace in two quick commands: `kubectl create ns test-restricted` then `kubectl label ns test-restricted pod-security.kubernetes.io/enforce=restricted`.
- Read the admission error carefully — it names the exact field to fix (e.g. `allowPrivilegeEscalation != false`, `privileged (container must not set ...)`). Fix the manifest to match.
- Confirm the labels stuck with `kubectl get ns <ns> --show-labels` before deploying test Pods.
- Remember PSA validates the **manifest at admission time**, not runtime — a `restricted`-compliant Pod can still `CrashLoopBackOff` (stock `nginx` can't write cache dirs or bind port 80 as non-root).
- Keep the compliant `restricted` `securityContext` block memorized so you can patch a rejected Pod quickly.

## Key Takeaway

Namespace labels enforce Pod Security Standards at admission time. Non-compliant Pods are blocked with clear error messages explaining exactly what must change in the manifest.
