# Blocking Privileged Pods with Kyverno

This lesson creates a Kyverno **validation** policy that denies any Pod with `securityContext.privileged: true` — a critical control against container escape and host compromise.

For Kyverno concepts and policy types, see [05-KyvernoPolicyLanguageAndCapabilities](../05-KyvernoPolicyLanguageAndCapabilities/readme.md).

## Demo Files

| File | Purpose |
|------|---------|
| `deny-privileged-policy.yaml` | Kyverno `ClusterPolicy` blocking privileged containers |
| `privileged-pod.yaml` | Pod with `privileged: true` — should be blocked |
| `unprivileged-pod.yaml` | Pod with `privileged: false` — should be created |

## Why Block Privileged Containers

A privileged container runs with nearly all host capabilities:

- Access to all host devices.
- Access to kernel modules and system calls.
- Can bypass many security mechanisms and potentially escape to the host.

Privileged containers are extremely dangerous in production and should be reserved for very specific system-level workloads.

## Prerequisites

- Docker Desktop, Minikube, `kubectl`
- Internet connection (to install Kyverno)

## Step 1: Start a Cluster

```bash
minikube start --driver=docker
```

## Step 2: Install Kyverno

```bash
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.12.0/install.yaml
kubectl get pods -n kyverno
```

Wait for the admission, background, cleanup, and reports controllers to be `1/1` Running.

## Step 3: Apply the Deny Policy

```bash
kubectl apply -f deny-privileged-policy.yaml
kubectl get clusterpolicy deny-privileged-containers
```

### How the policy works

```yaml
spec:
  validationFailureAction: Enforce   # block violations
  background: true                   # also scan existing resources
  rules:
  - name: privileged-not-allowed
    match:
      any:
      - resources:
          kinds: [Pod]
    validate:
      message: "Privileged containers are not allowed..."
      pattern:
        spec:
          containers:
          - =(securityContext):
              =(privileged): false
```

- `=(...)` is a Kyverno **conditional anchor**: the field is optional, but **if present it must match**. So `privileged` may be omitted, but if set it must be `false`.
- `validationFailureAction: Enforce` blocks violations at admission time.
- `background: true` audits existing resources too.

## Step 4: Test a Privileged Pod

```bash
kubectl apply -f privileged-pod.yaml
```

Expected — the request is denied:

```text
resource Pod/default/privileged-pod was blocked due to the following policies:
deny-privileged-containers:
  privileged-not-allowed: Privileged containers are not allowed. Set securityContext.privileged to false.
```

## Step 5: Test an Unprivileged Pod

```bash
kubectl apply -f unprivileged-pod.yaml
kubectl get pods
```

The unprivileged Pod is created and runs normally.

## Cleanup

```bash
kubectl delete -f unprivileged-pod.yaml --ignore-not-found
kubectl delete -f deny-privileged-policy.yaml
```

## CKAD Note

The Kyverno policy is a **CKS/platform** topic. The CKAD-relevant part is knowing that `securityContext.privileged: true` is dangerous and how to set `securityContext` fields on a Pod (see modules 11 and 13).

## Key Takeaway

A Kyverno validation `ClusterPolicy` with `validationFailureAction: Enforce` blocks privileged Pods at admission time, preventing containers from gaining host-level access.
