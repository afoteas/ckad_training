# OPA Gatekeeper Architecture and Constraints

OPA Gatekeeper is a policy engine that lets you declare **policies as code** and enforces them automatically at admission time — bringing consistency and governance to the cluster.

For a hands-on Gatekeeper demo, see [04-EnforcingResourceLimitsWithGatekeeper](../04-EnforcingResourceLimitsWithGatekeeper/readme.md).

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

Three pieces work together:

| Component | Role |
|-----------|------|
| **OPA Engine** | Evaluates policies written in the **Rego** language — where the logic lives |
| **Admission Webhook** | Intercepts API requests and evaluates them against your policies; rejects violations |
| **Audit System** | Periodically scans **already-deployed** resources to detect drift after creation |

The audit system matters because admission controllers only check at **creation** time — resources can drift later. Together these make the cluster **continuously** governed, not just governed at creation.

```text
API request → Admission webhook → OPA engine evaluates Rego → allow / deny
Running cluster ← Audit system periodically re-scans for violations
```

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

Gatekeeper brings policy-as-code to Kubernetes: the OPA engine evaluates Rego, the admission webhook enforces at creation, and the audit system catches drift over time.
