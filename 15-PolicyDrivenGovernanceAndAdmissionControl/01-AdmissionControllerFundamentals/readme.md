# Admission Controller Fundamentals

Admission controllers intercept requests to the Kubernetes API server **after authentication and authorization but before the object is stored in etcd**. Think of them as airport security for your cluster — nothing gets through until it is checked.

## Why Admission Controllers Matter

As clusters grow, many teams create many manifests, and configurations drift:

- Someone forgets resource limits.
- A privileged container is deployed by accident.
- Required labels are missing.

Admission controllers provide **governance, security, and consistency** automatically, so you do not rely on every developer remembering every rule. They let you extend cluster behavior without modifying core Kubernetes code.

Key benefits:

- Intercept API requests before anything is stored.
- Enforce policies cluster-wide.
- Extend cluster behavior.
- Provide governance and compliance without manual checking.

## Two Categories

| Type | Can change the request? | Purpose | Examples |
|------|-------------------------|---------|----------|
| **Mutating** | Yes — modifies before storage | Add defaults, inject data | Add default labels, inject sidecars, set missing fields (e.g. Istio proxy injection) |
| **Validating** | No — only approves or rejects | Enforce rules | Reject privileged Pods, require resource limits, require labels |

Mutating controllers run **first**, then validating controllers. They work together for reliable, secure clusters.

## API Request Flow

```text
1. User/CI sends request      (kubectl apply, GitOps deploy)
        │
2. Authentication & Authorization  (who are you? are you allowed?)
        │
3. Admission Control
        ├─ Mutating webhooks   (modify the request)
        └─ Validating webhooks (accept or reject)
        │
4. Object stored in etcd → scheduler picks it up
```

Admission control is the **last checkpoint** before an object officially enters the cluster. If a rule is violated (for example a Pod missing a required label), the request is rejected at step 3.

## Mutating Webhook Configuration (Example)

A `MutatingWebhookConfiguration` targets Pod creation, runs logic in an in-cluster Service, and modifies the Pod before it is stored — for example injecting standard labels:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: label-injector
webhooks:
- name: label-injector.example.com
  clientConfig:
    service:
      name: label-injector-svc
      namespace: webhooks
      path: /mutate
  rules:
  - operations: ["CREATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  admissionReviewVersions: ["v1"]
  sideEffects: None
```

The `rules` section says: on **CREATE** operations, in the **core** API group (`""`), for the **pods** resource, call this webhook. The Service holds your custom logic (here, injecting labels so Pods meet organizational requirements).

Injecting consistent metadata, applying defaults, and preparing workloads for service meshes are the most common uses of mutating webhooks.

## Production Best Practices

| Practice | Why |
|----------|-----|
| Keep the webhook highly available | If it is down, API requests can fail or stall |
| Monitor latency | Every matching request flows through the webhook — slow webhooks slow the API server |
| Choose `failurePolicy` carefully | `Ignore` improves resilience but may allow non-compliant resources; `Fail` is stricter |
| Scope rules narrowly | Do not run heavy logic on every resource type — reduces overhead |
| Audit the logs | Confirm the webhook actually does what you expect |

## CKAD Notes

Admission webhooks are largely a **CKS/platform** topic. For CKAD, focus on:

- The order: **authentication → authorization → admission → etcd**.
- **Mutating** changes requests; **validating** only accepts or rejects.
- Admission control is the final gate before an object is persisted.

## Key Takeaway

Admission controllers are the enforcement point for cluster governance. Mutating controllers adjust requests; validating controllers approve or reject them — together they keep clusters consistent, secure, and compliant.
