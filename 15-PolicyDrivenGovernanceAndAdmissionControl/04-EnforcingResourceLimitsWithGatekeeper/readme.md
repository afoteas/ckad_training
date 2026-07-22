# Enforcing Resource Limits with Gatekeeper

This lesson uses OPA Gatekeeper to **block any Pod that does not define CPU and memory limits and requests**, ensuring resource governance and preventing resource starvation.

For Gatekeeper architecture and CRDs, see [03-OPAGatekeeperArchitectureAndConstraints](../03-OPAGatekeeperArchitectureAndConstraints/readme.md).

## Demo Files

| File | Purpose |
|------|---------|
| `require-resources-template.yaml` | `ConstraintTemplate` with Rego checking CPU/memory limits and requests |
| `require-resources-constraint.yaml` | `Constraint` applying the template to Pods with `deny` |
| `pod-without-resources.yaml` | Non-compliant Pod — should be blocked |
| `pod-with-resources.yaml` | Compliant Pod — should be created |

## Why Enforce Resource Limits

- Prevent resource starvation (noisy neighbors).
- Control costs by capping runaway consumption.
- Support capacity planning.

## Concepts

- **ConstraintTemplate** — defines the schema and the Rego policy logic; creates a new CRD.
- **Constraint** — an instance of the template that specifies what to validate (Pods), any parameters, and the enforcement action (`deny`, `dryrun`, `warn`).

## Prerequisites

- Docker Desktop, Minikube, `kubectl`
- Internet connection (to install Gatekeeper)

## Step 1: Start a Cluster

```bash
minikube start --driver=docker
```

## Step 2: Install Gatekeeper

```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.16.0/deploy/gatekeeper.yaml
kubectl get pods -n gatekeeper-system
```

This deploys the controller-manager (webhook server), the audit controller, the policy CRDs, and webhook configurations. Wait until all Pods are `1/1`.

## Step 3: Create the ConstraintTemplate

```bash
kubectl apply -f require-resources-template.yaml
kubectl get constrainttemplates
```

The template's Rego checks that every container defines:

- `resources.limits.cpu`
- `resources.limits.memory`
- `resources.requests.cpu`
- `resources.requests.memory`

Each missing field produces a violation message.

## Step 4: Create the Constraint

```bash
kubectl apply -f require-resources-constraint.yaml
kubectl get k8srequiredresources
```

`enforcementAction: deny` means violations are blocked. `kubectl describe` shows the current violation count from the audit.

## Step 5: Test a Non-Compliant Pod

```bash
kubectl apply -f pod-without-resources.yaml
```

Expected — the request is rejected:

```text
Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request:
Container nginx must set resources.limits.cpu
```

The Pod never runs.

## Step 6: Test a Compliant Pod

```bash
kubectl apply -f pod-with-resources.yaml
kubectl get pod good-pod
kubectl describe pod good-pod | grep -i -A2 limits
```

The compliant Pod is created and runs, showing its configured limits and requests.

## How It Fits Together

```text
kubectl apply Pod
      │
API server → Gatekeeper webhook → runs Rego against the Pod
      │
   allow ──→ stored in etcd
   deny  ──→ rejected with violation message
```

## Cleanup

```bash
kubectl delete -f pod-with-resources.yaml --ignore-not-found
kubectl delete -f require-resources-constraint.yaml
kubectl delete -f require-resources-template.yaml
```

## CKAD Note

Gatekeeper enforcement is a **CKS/platform** topic. The CKAD-relevant part is knowing how to *write* compliant `resources.requests`/`limits` (covered in module 12) — which is exactly what this policy enforces.

## Key Takeaway

A ConstraintTemplate (reusable Rego) plus a Constraint (Pod-scoped, `deny`) makes CPU/memory limits mandatory cluster-wide, blocking non-compliant Pods at admission time.
