# Creating a Simple Mutating Webhook

This lesson demonstrates automatically injecting standard labels into **all Pods at admission time** using a Kyverno mutating policy — instead of manually adding labels to every Pod spec.

For the theory behind mutating vs validating admission, see [01-AdmissionControllerFundamentals](../01-AdmissionControllerFundamentals/readme.md).

## Demo Files

| File | Purpose |
|------|---------|
| `inject-labels-policy.yaml` | Kyverno `ClusterPolicy` that injects three standard labels into every Pod |
| `test-pod.yaml` | Simple nginx Pod with only an `app: nginx` label |

## Kyverno vs manual admission webhooks

Lesson [01](../01-AdmissionControllerFundamentals/readme.md) showed how **mutating admission webhooks** work: the API server POSTs object JSON to a webhook service, which returns a patched object before etcd. **Kyverno implements that same mechanism** — you just do not write the webhook server or `MutatingWebhookConfiguration` yourself.

### Same admission flow

```text
kubectl apply Pod
    │
    ▼
API server (auth + RBAC)
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Manual webhook (lesson 01)     │  Kyverno (this lesson)    │
│  POST → your-service/mutate     │  POST → kyverno-svc/…     │
│  your code patches Pod          │  ClusterPolicy patches Pod│
└─────────────────────────────────────────────────────────────┘
    │
    ▼
Modified Pod stored in etcd
```

Both paths end the same way: the cluster stores the **modified** Pod, not necessarily what was in your YAML file.

### What you build vs what Kyverno provides

| Piece | Manual webhook (lesson 01) | Kyverno (lesson 02) |
|-------|------------------------------|---------------------|
| **Webhook server** | You write and deploy an app (Go, Python, etc.) | Kyverno admission controller Pods (installed with Helm/manifest) |
| **Service** | You create `label-injector-svc` | Kyverno install creates `kyverno-svc` (etc.) |
| **`MutatingWebhookConfiguration`** | You write and apply YAML | Kyverno install registers this automatically |
| **TLS / certs** | You configure (or use cert-manager) | Handled by Kyverno install |
| **Policy logic** | Code in your webhook handler | **`ClusterPolicy` YAML** (`mutate`, `validate`, `generate`) |
| **Change policy** | Rebuild/redeploy webhook image | `kubectl apply` a new or updated policy |
| **Language** | Any (Rego optional) | **YAML** (+ small Kyverno-specific syntax like `+(key)`) |

### Example: inject labels

**Manual webhook** — three artifacts + code:

```text
1. Deployment (your webhook server)
2. Service (label-injector-svc)
3. MutatingWebhookConfiguration (rules: CREATE pods → /mutate)
4. Handler code: if Pod → add labels → return patch
```

**Kyverno** — one policy resource:

```yaml
# inject-labels-policy.yaml
kind: ClusterPolicy
spec:
  rules:
  - match: { kinds: [Pod] }
    mutate:
      patchStrategicMerge:
        metadata:
          labels:
            +(team): platform
```

Kyverno already listens on the API server's mutating webhook path; the `ClusterPolicy` tells it **what** to patch.

### Kyverno vs manual — when to use which

| Use manual webhook when… | Use Kyverno when… |
|--------------------------|-------------------|
| You need fully custom logic (complex APIs, external calls) | Standard validate/mutate/generate policies in YAML are enough |
| You already have a policy team writing Go/Rust services | Platform teams want Kubernetes-native policies without new languages |
| One-off integration with a proprietary system | Consistent governance across many rule types (labels, limits, images) |

Gatekeeper (OPA/Rego) is another common alternative — covered in lessons 03–04.

### Kyverno controllers (install creates more than admission)

| Controller | Role |
|------------|------|
| **Admission** | Mutating + validating at create/update — **same as lesson 01 webhooks** |
| **Background** | Scans **existing** resources when `background: true` on a policy (audit, not at admission) |
| **Reports / cleanup** | Policy reports and cleanup jobs |

This lesson's `inject-standard-labels` policy runs at **admission only** (no `background: true`). Labels are injected when the Pod is created, not by a background scan.

## Why Kyverno for Mutation

A **mutating admission webhook** changes objects before they are stored in etcd. Common uses: injecting sidecars, adding labels/annotations.

Kyverno is a Kubernetes-native policy engine:

- Policies are written as **Kubernetes resources (YAML)** — no new language to learn.
- It can validate, mutate, and generate resources.
- It **is** a mutating webhook under the hood — you write policies, not HTTP handlers.

## Why Inject Labels

Standard labels help with:

- Resource organization and filtering
- Cost allocation and tracking
- Operational consistency
- Multi-tenancy (label by team/project so shared clusters stay manageable)

## Prerequisites

- Docker Desktop
- Minikube
- `kubectl`
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

This deploys the admission, background, cleanup, and reports controllers into the `kyverno` namespace. Wait for all Pods to be `Running`.

## Step 3: Apply the Label Injection Policy

```bash
kubectl apply -f inject-labels-policy.yaml
kubectl get clusterpolicy inject-standard-labels
```

### How the policy works

```yaml
mutate:
  patchStrategicMerge:
    metadata:
      labels:
        +(app.kubernetes.io/managed-by): kyverno
        +(environment): demo
        +(team): platform
```

- The `+(...)` syntax is a Kyverno **anchor** meaning "add this key if it does not already exist."
- Each entry is a key/value pair — e.g. key `team`, value `platform`.
- The policy matches `Pod` resources, so every created Pod gets these labels.

## Step 4: Create a Test Pod

```bash
kubectl apply -f test-pod.yaml
kubectl get pod test-app --show-labels
```

Although `test-pod.yaml` only defines `app: nginx`, the running Pod also has:

```text
app=nginx
app.kubernetes.io/managed-by=kyverno
environment=demo
team=platform
```

The three extra labels were injected automatically at admission time.

## Cleanup

```bash
kubectl delete -f test-pod.yaml
kubectl delete -f inject-labels-policy.yaml
```

## CKAD Note

Mutating webhooks and Kyverno are **CKS/platform** topics, not CKAD. The transferable idea: a mutating admission step can add fields (like labels) to objects before they are stored.

## Key Takeaway

Kyverno is a **ready-made mutating admission webhook**: the API server still POSTs Pod JSON at admission time; your `ClusterPolicy` defines the patch instead of custom server code. Use it when YAML policies are enough; use manual webhooks when you need fully custom logic.
