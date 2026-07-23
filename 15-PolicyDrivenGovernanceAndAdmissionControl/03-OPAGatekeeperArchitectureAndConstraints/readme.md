# OPA Gatekeeper Architecture and Constraints

OPA Gatekeeper is a policy engine that lets you declare **policies as code** and enforces them automatically at admission time — bringing consistency and governance to the cluster.

For admission webhook theory, see [01-AdmissionControllerFundamentals](../01-AdmissionControllerFundamentals/readme.md). For Kyverno's YAML-based approach, see [02-CreatingASimpleMutatingWebhook](../02-CreatingASimpleMutatingWebhook/readme.md). For a hands-on Gatekeeper demo, see [04-EnforcingResourceLimitsWithGatekeeper](../04-EnforcingResourceLimitsWithGatekeeper/readme.md).

## What is OPA?

**OPA** (Open Policy Agent) is a general-purpose **policy engine**. It is not Kubernetes-specific — you can use it for APIs, CI/CD, Terraform, SSH access, and more.

The model is always the same:

```text
Input (JSON)  +  Policy (Rego)  →  Decision (allow / deny + message)
```

| Piece | What it is |
|-------|------------|
| **Input** | Data to evaluate — e.g. a Pod manifest converted to JSON |
| **Rego** | OPA's policy language — rules like "deny if privileged" |
| **Output** | `allow` or `deny` (and optional violation messages) |

### Minimal Rego example (concept)

**Question:** Should this Pod be allowed?

```json
{
  "kind": "Pod",
  "spec": {
    "containers": [{
      "name": "app",
      "securityContext": { "privileged": true }
    }]
  }
}
```

**Rego policy (simplified):**

```rego
deny[msg] {
  input.spec.containers[_].securityContext.privileged == true
  msg := "privileged containers are not allowed"
}
```

**Result:** `deny` — "privileged containers are not allowed."

You do not run OPA by hand on every `kubectl apply`. **Gatekeeper** embeds OPA and calls it automatically from the admission webhook.

## OPA vs Gatekeeper vs Kyverno vs manual webhooks

| | **OPA** | **Gatekeeper** | **Kyverno** | **Manual webhook** |
|--|---------|----------------|-------------|-------------------|
| **What it is** | Policy engine + Rego | Kubernetes integration for OPA | Kubernetes policy engine (YAML) | Custom app you build |
| **Policy language** | **Rego** | Rego (in ConstraintTemplate) | **YAML** | Any (Go, Python, …) |
| **K8s admission** | Via Gatekeeper (or other integrators) | **Validating** webhook (+ audit) | Mutate + validate + generate | Mutate and/or validate |
| **You typically write** | Rego policies | ConstraintTemplate + Constraint | ClusterPolicy | Server code + WebhookConfiguration |

**Mental model:**

```text
OPA        = brain (Rego evaluation)
Gatekeeper = Kubernetes adapter (webhook + CRDs + audit) that feeds Pod JSON into OPA
Kyverno    = alternative adapter — YAML policies instead of Rego
```

All three sit in the same place in the [admission flow](../01-AdmissionControllerFundamentals/readme.md): after auth/RBAC, before etcd.

### Gatekeeper admission flow (validating)

Gatekeeper is primarily a **validating** webhook — it does not patch objects like Kyverno mutate policies; it **allows or denies**:

```text
1. You: kubectl apply -f pod.yaml

2. API server: authentication + RBAC OK

3. Mutating webhooks run first (if any — e.g. Kyverno inject labels)

4. API server → POST Pod JSON (AdmissionReview) → Gatekeeper webhook

5. Gatekeeper: finds matching Constraints → runs Rego in OPA engine

6. OPA returns: allow OR deny (+ message)

7a. allowed: true  → Pod stored in etcd → scheduler/kubelet
7b. allowed: false → error to kubectl, nothing in etcd
```

Same **true/false** pattern as a manual validating webhook in lesson 01 — Gatekeeper + OPA replace your custom `/validate` handler and Rego replaces your Go `if` statements.

## Why Gatekeeper

Without policy enforcement, clusters become inconsistent:

- Teams set different labels or forget resource limits.
- Unsafe workloads get deployed by accident.
- Configuration drifts, creating security gaps and manual review overhead.

Gatekeeper enforces rules automatically instead of relying on people to remember them. Benefits:

- Block non-compliant resources before they enter the cluster.
- Provide audit and reporting.
- Keep standards consistent across teams and projects.

## Architecture

Three pieces work together inside (and around) Gatekeeper:

| Component | Role |
|-----------|------|
| **OPA Engine** | Evaluates policies written in **Rego** — the decision logic ("is this Pod compliant?") |
| **Admission Webhook** | Gatekeeper's validating hook — receives Pod JSON from the API server, passes it to OPA, returns `allowed: true/false` |
| **Audit System** | Periodically scans **already-deployed** resources against the same policies — catches drift after creation |

```text
                    ┌─────────────────┐
kubectl apply ─────►│  API server     │
                    └────────┬────────┘
                             │ AdmissionReview (Pod JSON)
                             ▼
                    ┌─────────────────┐
                    │  Gatekeeper     │
                    │  admission hook │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   OPA engine    │◄── Rego from ConstraintTemplate
                    │ (evaluate input)│
                    └────────┬────────┘
                             │ allow / deny
                             ▼
                    etcd (only if allowed)

Running cluster ◄──── Audit controller re-scans existing objects
```

The audit system matters because admission only checks at **create/update** time — resources can drift later (e.g. someone patches around a policy). Audit makes governance **continuous**, not only at the gate.

### How CRDs map to OPA

| CRD | Maps to… |
|-----|----------|
| **ConstraintTemplate** | Rego policy blueprint installed in the cluster (the reusable rule) |
| **Constraint** | Parameters + scope for one use of that template (e.g. "Pods must have label `team`") |
| **Config / Audit** | What to scan in the background and how audit reports work |

When a Pod is admitted, Gatekeeper loads the matching **Constraint**, feeds the Pod JSON as **`input`** to OPA, and OPA runs the **Rego** from the linked **ConstraintTemplate**.

## Custom Resource Definitions

Gatekeeper introduces CRDs that define how policies are written and applied:

| CRD | Purpose |
|-----|---------|
| **ConstraintTemplate** | Defines reusable policy logic in Rego — a blueprint for a rule |
| **Constraint** | Instantiates a template with specific parameters (e.g. which labels are required) |
| **Config / Audit** | Controls how auditing works and which resources are synced/monitored |

One ConstraintTemplate (e.g. "require these labels") can back many Constraints for different teams. This makes policies modular, reusable, and easy to manage.

## Constraint Example

A Constraint that requires every Pod to include a `team` label:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: pods-must-have-team
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
  parameters:
    labels: ["team"]
```

- `match` targets Pods in the core API group.
- `parameters.labels` lists the required labels.
- If the label is missing, Gatekeeper **denies** the request.

Requiring metadata like `team`, `environment`, or `cost-center` is a common real-world governance pattern.

## Benefits and Considerations

| Benefit | Detail |
|---------|--------|
| Aligns cluster with org policy | Policies are encoded and enforced, not tribal knowledge |
| Audits highlight existing violations | Teams can fix drift before it causes issues |
| Minimal overhead when scoped well | Broad or excessive constraints slow admissions — design carefully |

Operational notes:

- Policies are **code** — version control and test them like application code.
- Requires collaboration between Dev, Sec, and Ops so policies are realistic and non-disruptive.

## CKAD Note

Gatekeeper and Rego are **CKS/platform** topics, not CKAD. Understand conceptually: ConstraintTemplate (reusable logic) + Constraint (instance) + audit (ongoing scanning).

## Key Takeaway

**OPA** is the Rego policy engine. **Gatekeeper** plugs OPA into Kubernetes as a validating admission webhook (plus audit): you write **ConstraintTemplate** (Rego) + **Constraint** (parameters), and OPA decides allow/deny before objects reach etcd — same validating pattern as lesson 01, without building your own webhook server.
