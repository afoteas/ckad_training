# Creating a Simple Mutating Webhook

This lesson demonstrates automatically injecting standard labels into **all Pods at admission time** using a Kyverno mutating policy — instead of manually adding labels to every Pod spec.

For the theory behind mutating vs validating admission, see [01-AdmissionControllerFundamentals](../01-AdmissionControllerFundamentals/readme.md).

## Demo Files

| File | Purpose |
|------|---------|
| `inject-labels-policy.yaml` | Kyverno `ClusterPolicy` that injects three standard labels into every Pod |
| `test-pod.yaml` | Simple nginx Pod with only an `app: nginx` label |

## Why Kyverno for Mutation

A **mutating admission webhook** changes objects before they are stored in etcd. Common uses: injecting sidecars, adding labels/annotations.

Kyverno is a Kubernetes-native policy engine:

- Policies are written as **Kubernetes resources (YAML)** — no new language to learn.
- It can validate, mutate, and generate resources.

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

A Kyverno mutating `ClusterPolicy` enforces consistent metadata across every Pod automatically, removing reliance on developers to remember standard labels.
