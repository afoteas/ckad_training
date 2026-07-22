# Kyverno Policy Language and Capabilities

Kyverno is a Kubernetes-native policy engine. Unlike OPA Gatekeeper, which uses **Rego**, Kyverno policies are written in **plain YAML** — just like regular Kubernetes manifests.

For a hands-on validation demo, see [06-BlockingPrivilegedPodsWithKyverno](../06-BlockingPrivilegedPodsWithKyverno/readme.md).

## Why Kyverno

Gatekeeper's Rego has a steep learning curve for non-developers. Kyverno takes a different approach:

- Policies look like Kubernetes manifests — if you know YAML, you can write policies.
- Approachable for platform engineers, DevOps, and cluster operators.
- No new language required.

Where Gatekeeper is extremely flexible and powerful, Kyverno focuses on **simplicity, readability, and ease of adoption**.

## Policy Types

| Type | What it does | Example |
|------|--------------|---------|
| **validate** | Enforce rules — allow or block | Block privileged Pods, require labels |
| **mutate** | Modify manifests before creation | Inject labels or sidecars |
| **generate** | Create additional resources automatically | Generate a default ConfigMap when a Namespace is created |

`generate` is unique to Kyverno. Together these three make it flexible for platform automation.

## Example: Validation Policy

A `ClusterPolicy` that prevents any Pod from running in privileged mode:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-privileged
spec:
  validationFailureAction: Enforce
  rules:
  - name: privileged-not-allowed
    match:
      any:
      - resources:
          kinds:
          - Pod
    validate:
      message: "Privileged mode is not allowed"
      pattern:
        spec:
          containers:
          - securityContext:
              privileged: false
```

Key parts:

- `validationFailureAction: Enforce` — block the request (not just warn).
- `rules[].match` — targets the `Pod` kind.
- `validate.pattern` — describes the **allowed structure**: every container's `securityContext.privileged` must be `false`.
- `validate.message` — shown when the policy rejects a request.

Kyverno's **pattern** section describes the allowed YAML structure rather than imperative logic — this makes policies intuitive to read and write.

## Benefits

| Benefit | Detail |
|---------|--------|
| Kubernetes-native | No new language — write YAML |
| Admission webhook enforcement | Enforcement happens at the right point in the workflow |
| Built-in testing tools | CLI makes it easy to validate policies |
| Rich community policy library | Reuse policies (disallow privileged, naming conventions, etc.) |

## Considerations and Limitations

| Consideration | Detail |
|---------------|--------|
| YAML simplicity vs complex logic | Harder to express advanced logic than Rego |
| Performance overhead | Many policies across many resource types add cost |
| CRD lifecycle | Custom resources must be managed across cluster upgrades |
| Policy conflicts | Multiple teams' policies can conflict — use version control/GitOps |

Version-control policies and coordinate across teams to avoid drift and conflicts, especially in clusters with many operators.

## Kyverno vs Gatekeeper

| | **Kyverno** | **Gatekeeper** |
|---|-------------|----------------|
| Language | YAML | Rego |
| Learning curve | Low | Higher |
| Capabilities | validate, mutate, generate | validate, mutate (limited) |
| Best for | Readability, quick adoption | Complex/advanced policy logic |

## CKAD Note

Kyverno is a **CKS/platform** tool, not part of CKAD. The transferable idea is that a validation policy can block Pods based on fields like `securityContext.privileged`.

## Key Takeaway

Kyverno makes policy-as-code approachable by using familiar YAML patterns for validation, mutation, and generation — trading some of Rego's raw power for readability and ease of adoption.
