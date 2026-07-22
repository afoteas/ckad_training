# Pod Security Admission and Standards

Pod Security Admission (PSA) is the built-in Kubernetes admission controller that evaluates Pods **before they are created** and ensures they meet defined security standards.

## Why PSA Exists

### History: PodSecurityPolicy (PSP)

Before Kubernetes 1.25, cluster admins used **PodSecurityPolicy (PSP)** to control what Pods could do — whether they could run as root, mount the host filesystem, and similar rules.

PSP problems:

- Complex and hard to manage
- Inconsistent across clusters and API versions
- Difficult to balance security and usability
- Required extensive per-cluster configuration

PSP is now **deprecated** and removed in modern Kubernetes.

### PSA: A Simpler Model

PSA replaces PSP with a **standardized admission controller** that is easier to manage and consistent across environments.

Instead of complex policy objects, PSA uses **namespace labels** to define how strict Pod security should be. Teams get consistent enforcement without maintaining separate PSP configurations per cluster.

## How PSA Works

PSA is an **admission controller** that runs when Pods are submitted to the API server:

1. A user or controller creates a Pod.
2. PSA evaluates the Pod against the security standard configured on the namespace.
3. Depending on the mode, PSA **blocks**, **logs**, or **warns** about violations.

All configuration is done at the **namespace level** using labels.

## PSA Modes of Operation

PSA can operate in three modes. You can enable multiple modes on the same namespace at once.

| Mode | Label suffix | Behavior |
|------|--------------|----------|
| `enforce` | `pod-security.kubernetes.io/enforce` | **Blocks** non-compliant Pods — strict bouncer at the door |
| `audit` | `pod-security.kubernetes.io/audit` | Allows the Pod but **logs** the violation — useful for testing impact |
| `warn` | `pod-security.kubernetes.io/warn` | Allows the Pod but **warns** the user — good for gradual adoption |

### Mode Examples

- **`enforce`** — if the Pod doesn't meet the profile, it is rejected.
- **`audit`** — non-compliant Pods still run, but violations appear in audit logs.
- **`warn`** — non-compliant Pods still run, but the user sees a warning. Ideal when teams are transitioning to stricter standards without breaking dev workflows.

**Best practice:** start with `audit` and `warn` before enabling `enforce`.

### Quick Comparison: How Noisy Is Each Label?

The **standard** you choose (`privileged`, `baseline`, `restricted`) affects how often violations occur — regardless of mode.

| Label | How noisy? | Why |
|-------|------------|-----|
| `warn=privileged` | Very quiet | Almost nothing violates `privileged` |
| `warn=baseline` | Moderate | Warns on privileged containers, host namespaces, etc. |
| `warn=restricted` | Noisy | Warns on root, missing caps drop, no seccomp, etc. |
| `audit=restricted` | Silent to user | Logs only — you won't see warnings in the terminal |

Use `warn=restricted` during migration to surface issues to developers. Use `audit=restricted` when you want a paper trail without bothering users. Use `enforce=restricted` when you are ready to block non-compliant Pods.

## Pod Security Standards (PSS)

PSS defines three **predefined, fixed** security levels you can apply per namespace. You **cannot customize** the rules — you only choose which level to use.

| Level | Description | Typical use |
|-------|-------------|-------------|
| `privileged` | Unrestricted — allows anything | System components: CNI plugins, storage drivers |
| `baseline` | Minimally restrictive — prevents known privilege escalations | Most non-critical application workloads |
| `restricted` | Most secure — non-root, dropped capabilities, no privileged containers | Production apps following security best practices |

### Predefined Rules Comparison

The table below lists the main rules enforced at each level. A check means the rule applies; "—" means no restriction at that level.

| Rule | privileged | baseline | restricted |
|------|:----------:|:--------:|:----------:|
| **Privileged containers** (`privileged: true`) | Allowed | Blocked | Blocked |
| **Host namespaces** (`hostNetwork`, `hostPID`, `hostIPC`) | Allowed | Blocked | Blocked |
| **Host ports** (`hostPort` > 0) | Allowed | Blocked | Blocked |
| **HostPath volumes** | Allowed | Restricted paths only | Blocked |
| **Added Linux capabilities** (beyond defaults) | Allowed | Only safe caps allowed | Only `NET_BIND_SERVICE` |
| **Unsafe sysctls** | Allowed | Blocked | Blocked |
| **Run as root** (`runAsUser: 0`) | Allowed | Allowed | Blocked |
| **`runAsNonRoot: true`** required | — | — | Required |
| **`allowPrivilegeEscalation: false`** required | — | — | Required |
| **Drop all capabilities** (`capabilities.drop: ["ALL"]`) | — | — | Required |
| **seccomp profile** | Any | Any (incl. `Unconfined`) | `RuntimeDefault` or `Localhost` only |
| **Volume types** | Any | Any | Only ConfigMap, Secret, emptyDir, PVC, projected |

### What Each Standard Means in Practice

#### `privileged`

No restrictions. Use only for trusted system workloads that need full host access (CNI plugins, storage drivers, node agents).

```yaml
# Allowed under privileged — blocked under baseline and restricted
securityContext:
  privileged: true
```

#### `baseline`

Blocks the most dangerous settings but still allows common application patterns, including running as root.

Blocked examples:

```yaml
# NOT allowed under baseline
securityContext:
  privileged: true

hostNetwork: true
hostPID: true
```

Still allowed under baseline:

```yaml
# Allowed under baseline — blocked under restricted
securityContext:
  runAsUser: 0          # root is OK
  # no capabilities.drop required
```

#### `restricted`

Enforces all baseline rules **plus** strict least-privilege defaults. This is the standard tested most often on CKAD.

Required settings for a compliant Pod:

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: nginx
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
```

### CKAD: Which Standard to Remember?

| Standard | CKAD priority | Focus on |
|----------|---------------|----------|
| `privileged` | Low | Know it means "no restrictions" |
| `baseline` | Medium | Know what it blocks vs allows (root OK, privileged not) |
| `restricted` | **High** | Be able to write a compliant `securityContext` from memory |

Official reference: [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)

When applying PSA, you choose which of these three profiles applies to each namespace.

## Namespace Label Example

Apply PSA to a namespace called `secure-apps`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-apps
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: baseline
    pod-security.kubernetes.io/warn: baseline
```

This configuration:

- **Enforces** the `restricted` profile (blocks violations).
- **Audits** and **warns** on `baseline` violations.

This creates a **gradual path** to stricter enforcement: developers can still deploy apps that aren't fully compliant while you monitor and warn them along the way.

Equivalent `kubectl` commands:

```bash
kubectl label namespace secure-apps \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=baseline \
  pod-security.kubernetes.io/warn=baseline
```

## Operational Considerations

### 1. Start with Audit and Warn

Before jumping to `enforce`, use `audit` and `warn` to identify which workloads would break. This prevents breaking production overnight.

### 2. Apply Different Standards per Namespace

| Namespace type | Suggested level |
|----------------|-----------------|
| `dev` | `baseline` or `privileged` |
| `staging` | `baseline` with `warn: restricted` |
| `production` | `restricted` |

### 3. Document Exemptions

Some system-critical Pods may need extra privileges. Document exceptions so they are not blocked accidentally.

### 4. Train Teams to Interpret Warnings

Warnings are early signals that a deployment isn't following security best practices. Teams must understand:

- What the warning means
- Which `securityContext` fields need to change
- How to make the Pod compliant

### 5. Monitor Admission Logs

Audit logs show violations and help you tune policies over time. Review them regularly as you tighten enforcement.

## Key Takeaway

PSA replaces complex PodSecurityPolicy with namespace-level labels and three clear standards. Start with `warn` and `audit`, then move to `enforce` for a gradual, team-friendly path to stronger security.

For a hands-on walkthrough, see [02-EnforcingRestrictedPolicyInANamespace](../02-EnforcingRestrictedPolicyInANamespace/readme.md).
