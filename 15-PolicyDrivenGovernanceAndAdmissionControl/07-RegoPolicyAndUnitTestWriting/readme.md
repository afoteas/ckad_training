# Rego Policy and Unit Test Writing

Rego is the policy language for Open Policy Agent (OPA). It appears in tools like **Gatekeeper** and **Conftest** and is designed for expressing rules over structured data (JSON/YAML) — perfect for Kubernetes manifests.

For local manifest validation with Conftest, see [08-ValidatingManifestsLocallyWithConftest](../08-ValidatingManifestsLocallyWithConftest/readme.md).

## Example Files

| File | Purpose |
|------|---------|
| `deny-privileged.rego` | Rego policy denying privileged Pods |
| `deny-privileged_test.rego` | Unit tests for the policy |

## Why Rego

- Purpose-built for inspecting fields inside structured data (Pods, Deployments).
- Lets you decide whether configuration meets requirements.
- Flexible enough for security, compliance, multi-tenancy, and governance.
- The foundation for OPA and Gatekeeper's customizable policy logic.

## Rego Basics

A Rego policy is essentially a set of conditions:

1. Evaluate input data (usually a Kubernetes manifest).
2. Apply rules.
3. Return `true`/`false` or a structured message (e.g. a denial reason).

If the conditions match, the policy produces a violation; if not, the request is allowed. It is a **declarative** way to express logic about configuration.

## Example Policy

```rego
package kubernetes.admission

deny[msg] {
  input.kind == "Pod"
  container := input.spec.containers[_]
  container.securityContext.privileged == true
  msg := sprintf("Privileged pods are not allowed: container %v", [container.name])
}
```

What it does:

- Checks the object `kind` is `Pod`.
- Loops through the Pod's containers (`[_]` iterates the array).
- Checks whether any container has `securityContext.privileged == true`.
- Emits a denial message if found.

## Unit Testing Policies

Rego supports unit tests — rules prefixed with `test_` that feed mock input via `with input as`:

```rego
test_denies_privileged_pod {
  msgs := deny with input as {
    "kind": "Pod",
    "spec": {"containers": [{"name": "app", "securityContext": {"privileged": true}}]},
  }
  count(msgs) == 1
}
```

Run the tests with the OPA CLI:

```bash
opa test . -v
```

Testing policies like application code catches mistakes before they block real deployments.

## Where Rego Runs

| Tool | Use |
|------|-----|
| **Gatekeeper** | In-cluster admission enforcement + audit |
| **Conftest** | Local / CI validation of manifests before they reach the cluster |

## CI/CD Integration

Once policies work locally, integrate them:

- **Pre-commit hooks** validate manifests before commit.
- **CI pipelines** run Conftest in build/test stages to catch violations early.
- **GitOps** blocks pull requests that violate policy.
- **Reporting tools** surface violations to teams.

The goal is **continuous compliance** — policies checked at every stage of development, not only at deploy time.

## CKAD Note

Rego is **not** part of the CKAD curriculum (it is CKS/platform). Understand only the concept: a declarative rule that inspects a manifest and emits a violation when requirements are not met.

## Key Takeaway

Rego expresses declarative rules over Kubernetes manifests and supports unit testing. Write the policy in a `.rego` file, test it with `opa test`, then enforce it via Gatekeeper or Conftest.
