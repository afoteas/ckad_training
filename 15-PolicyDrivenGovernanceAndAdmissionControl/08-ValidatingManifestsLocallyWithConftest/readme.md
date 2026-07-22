# Validating Manifests Locally with Conftest

Conftest validates Kubernetes YAML against Rego policies **before they reach the cluster**. Unlike admission controllers that run in-cluster, Conftest runs locally or in CI/CD — catching violations during development ("shift-left").

For Rego basics, see [07-RegoPolicyAndUnitTestWriting](../07-RegoPolicyAndUnitTestWriting/readme.md).

## Demo Files

| File | Purpose |
|------|---------|
| `policy/kubernetes.rego` | Rego policy: deny privileged, missing limits/requests, `:latest` tag, hostNetwork |
| `bad-pod-conftest.yaml` | Non-compliant Pod — should fail |
| `good-pod-conftest.yaml` | Compliant Pod — should pass |

## Key Concepts

- **Conftest** — a utility to test structured configuration data using OPA Rego.
- **Shift-left security** — move checks earlier: local → pre-commit → CI/CD → cluster.
- **No cluster needed** — Conftest runs entirely on your machine.

## Prerequisites

- Conftest CLI (no Kubernetes cluster required)

```bash
brew install conftest   # macOS; use your distro's package manager on Linux
conftest --version
```

## Policy Directory

By default Conftest loads policies from a `policy/` directory. Here `policy/kubernetes.rego` denies:

- privileged containers
- containers missing resource limits
- containers missing resource requests
- images using the `:latest` tag
- `hostNetwork: true`

## Step 1: Test a Non-Compliant Manifest

```bash
conftest test bad-pod-conftest.yaml
```

Expected — multiple failures:

```text
FAIL - bad-pod-conftest.yaml - main - Container 'nginx' is running in privileged mode...
FAIL - bad-pod-conftest.yaml - main - Container 'nginx' must define resource limits
FAIL - bad-pod-conftest.yaml - main - Container 'nginx' must define resource requests
FAIL - bad-pod-conftest.yaml - main - Container 'nginx' must not use the ':latest' image tag
FAIL - bad-pod-conftest.yaml - main - hostNetwork is not allowed...

5 tests, 0 passed, 0 warnings, 5 failures
```

## Step 2: Test a Compliant Manifest

```bash
conftest test good-pod-conftest.yaml
```

Expected — all checks pass:

```text
<n> tests, <n> passed, 0 warnings, 0 failures
```

## Step 3: Test Multiple Files

```bash
conftest test bad-pod-conftest.yaml good-pod-conftest.yaml
```

Conftest reports failures per file, naming the file that violated a rule.

## Step 4: Verify the Policy Itself

```bash
conftest verify --policy policy
```

This runs any policy unit tests in the `policy/` directory.

## What Conftest Does

1. Loads Rego policies from the `policy/` directory.
2. Parses your YAML into structured data.
3. Evaluates the policies against that data.
4. Returns violations with a non-zero exit code (fails the build).

## Why Use Conftest

- **Fast** — millisecond checks.
- **Local** — no cluster required.
- **Early** — catch issues before committing.
- **CI-friendly** — a non-zero exit code fails pipelines on violations.

## CKAD Note

Conftest is a **CI/CKS** practice, not a CKAD topic. The transferable idea: validate manifests against rules (privileged, limits, image tags) before deploying.

## Key Takeaway

Conftest brings policy checks to the developer's machine and CI pipeline. Write rules in `policy/*.rego`, run `conftest test <manifest>`, and block non-compliant manifests before they ever reach the cluster.
