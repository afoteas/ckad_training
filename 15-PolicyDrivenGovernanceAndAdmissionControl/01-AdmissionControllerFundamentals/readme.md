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

**Important:** No label triggers this webhook. The API server calls it because `rules` match **CREATE Pod**. Labels are usually what the webhook **adds**, not what enables it.

### Mutating webhook: step by step

```text
1. You: kubectl apply -f pod.yaml

2. API server: authentication OK (who are you?)
   API server: authorization OK (RBAC — are you allowed to create Pods?)

3. API server: request is CREATE Pod → matches MutatingWebhookConfiguration rules

4. API server → HTTPS POST → label-injector-svc.webhooks.svc/mutate
   Body: AdmissionReview { request.object = your Pod JSON }

5. Webhook server: reads Pod JSON, applies logic (add labels, sidecar, defaults, …)
   Responds: AdmissionReview { response.allowed: true, response.patch = … }
   (returns modified Pod — JSON Patch or equivalent)

6. API server: applies patch → now holds the MODIFIED Pod in memory
   (your pod.yaml file on disk is unchanged)

7. Validating webhooks run next (if any) — see below

8. API server: stores the MODIFIED Pod in etcd

9. Scheduler assigns Pod to a node → kubelet starts containers
```

**What the webhook returns (mutating):** `allowed: true` + **patched object** (not just true/false). It can also return `allowed: false` to block creation.

## Validating Webhook Configuration (Example)

A `ValidatingWebhookConfiguration` uses the same registration pattern, but the webhook **cannot change** the object — it only returns **allow** or **deny**. If deny, the API server rejects the request and nothing is stored in etcd.

Example: block privileged Pods on create:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: deny-privileged-pods
webhooks:
- name: deny-privileged.example.com
  clientConfig:
    service:
      name: policy-validator-svc
      namespace: webhooks
      path: /validate
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  admissionReviewVersions: ["v1"]
  sideEffects: None
  failurePolicy: Fail
```

| Field | What it means here |
|-------|-------------------|
| `kind: ValidatingWebhookConfiguration` | Register a **read-only** admission hook (no patching) |
| `path: /validate` | HTTP endpoint on the webhook server (convention; not fixed by Kubernetes) |
| `operations: ["CREATE", "UPDATE"]` | Run on new Pods **and** when an existing Pod is changed |
| `failurePolicy: Fail` | If the webhook is unreachable or errors, **reject** the request (strict) |

### Validating webhook: step by step (allowed)

```text
1. You: kubectl apply -f pod.yaml

2. API server: authentication + RBAC OK

3. Mutating webhooks run first (if any) — Pod may already be patched

4. API server: request matches ValidatingWebhookConfiguration rules

5. API server → HTTPS POST → policy-validator-svc.webhooks.svc/validate
   Body: AdmissionReview { request.object = Pod JSON (after mutations) }

6. Webhook server: reads Pod JSON, checks rules (e.g. not privileged, has limits)
   Policy passes.

7. Webhook responds: AdmissionReview { response.allowed: true }
   (no patched object — validating cannot modify)

8. API server: stores Pod in etcd (the version after mutating hooks, unchanged by validator)

9. Scheduler/kubelet: normal flow continues
```

### Validating webhook: step by step (denied)

```text
1. You: kubectl apply -f privileged-pod.yaml

2. API server: authentication + RBAC OK

3. Mutating webhooks run first (if any)

4. API server → POST Pod JSON → policy-validator-svc/validate

5. Webhook server: securityContext.privileged == true → policy fails

6. Webhook responds:
   response.allowed: false
   response.status.message: "Privileged containers are not allowed"

7. API server: rejects request → returns error to kubectl
   Nothing is stored in etcd

8. No Pod is scheduled or run
```

Example `kubectl` error:

```text
Error from server: admission webhook "deny-privileged.example.com" denied the request:
Privileged containers are not allowed
```

**What the webhook returns (validating):** `allowed: true` or `allowed: false` only — **no modified Pod JSON**.

### Combined flow (mutating + validating)

When both hooks are installed for Pod CREATE:

```text
kubectl apply Pod
    │
    ▼
auth + RBAC
    │
    ▼
┌─────────────────────────────────────┐
│  Mutating webhook(s)                │
│  POST /mutate → patch Pod JSON      │
└─────────────────────────────────────┘
    │
    ▼  (patched Pod in memory)
┌─────────────────────────────────────┐
│  Validating webhook(s)              │
│  POST /validate → allow / deny      │
└─────────────────────────────────────┘
    │
    ├── allowed: false ──► error to user, nothing in etcd
    │
    └── allowed: true ──► save to etcd → scheduler → kubelet
```

| Stage | HTTP body sent | Webhook returns | Stored in etcd? |
|-------|----------------|-----------------|-----------------|
| **Mutating** | Pod JSON (in `AdmissionReview`) | Patched Pod + `allowed: true` | Not yet |
| **Validating** | Pod JSON (after mutations) | `allowed: true` or `false` + message | Only if `true` |

### Mutating vs validating — same wiring, different outcome

| | Mutating | Validating |
|--|----------|------------|
| **Kind** | `MutatingWebhookConfiguration` | `ValidatingWebhookConfiguration` |
| **Can modify object?** | Yes | No |
| **Response** | Patched JSON | `allowed: true` or `allowed: false` |
| **Runs when** | Before validating | After all mutating hooks |
| **Typical use** | Inject labels, sidecars, defaults | Deny privileged Pods, require limits/labels |
| **If rule fails** | N/A (it patches) | Request rejected — nothing in etcd |

In practice, tools like **Kyverno** and **Gatekeeper** implement both patterns — see [02-CreatingASimpleMutatingWebhook](../02-CreatingASimpleMutatingWebhook/readme.md) and [06-BlockingPrivilegedPodsWithKyverno](../06-BlockingPrivilegedPodsWithKyverno/readme.md).

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
