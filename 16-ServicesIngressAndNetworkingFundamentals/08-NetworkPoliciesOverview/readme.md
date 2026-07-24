# Network Policies Overview

By default, **all Pods can talk to all other Pods** — Kubernetes networking is flat and open. NetworkPolicies are the firewall equivalent for microservices, enforcing which traffic flows are permitted.

For a hands-on demo, see [09-RestrictingTrafficWithNetworkPolicies](../09-RestrictingTrafficWithNetworkPolicies/readme.md).

## Example Files

| File | Purpose |
|------|---------|
| `networkpolicy-example.yaml` | Allow only `app: frontend` Pods to reach `app: nginx` on port 80 (ingress) |
| `networkpolicy-egress-example.yaml` | Allow only `tier: api` Pods to reach `tier: database` on port 5432 (egress) |
| `default-deny-all.yaml` | Deny all ingress and egress for every Pod in the namespace |

## Why They Matter

Without controls, any compromised workload can reach any other Pod. NetworkPolicies provide **security segmentation** based on Pod labels and namespaces, implementing least privilege.

## The Four Key Fields

| Field | Role |
|-------|------|
| `podSelector` | **Mandatory** — label selector for the Pods the policy applies to |
| `policyTypes` | Whether the policy controls `Ingress`, `Egress`, or both |
| `ingress` | Allowed **sources** (Pods, namespaces, CIDR blocks) |
| `egress` | Allowed **destinations** for outgoing traffic |

**Important:** if `policyTypes` includes `Ingress`, all incoming traffic to the selected Pods is **denied unless explicitly allowed** by an ingress rule. The same applies to `Egress` for outgoing traffic.

## Example

```yaml
spec:
  podSelector:
    matchLabels:
      app: nginx        # affected Pods
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend # only frontend Pods allowed
    ports:
    - protocol: TCP
      port: 80
```

This allows only `app: frontend` Pods to reach `app: nginx` on port 80; all other incoming traffic is implicitly denied.

## Egress example

Ingress rules control **who may connect to** the selected Pods. Egress rules control **where those Pods may connect**. If `policyTypes` includes `Egress`, all outgoing traffic from the selected Pods is **denied unless explicitly allowed**.

```yaml
spec:
  podSelector:
    matchLabels:
      tier: api           # affected Pods
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database  # only database Pods allowed
    ports:
    - protocol: TCP
      port: 5432
```

This allows only `tier: api` Pods to send traffic to `tier: database` Pods on TCP 5432; all other outbound traffic is implicitly denied. See `networkpolicy-egress-example.yaml`.

**Ingress vs egress field names:**

| Direction | Rule block | Peer field |
|-----------|------------|------------|
| Incoming | `ingress` | `from` |
| Outgoing | `egress` | `to` |

## Both directions in one policy

A single NetworkPolicy can control **ingress and egress** together — one `podSelector`, both `policyTypes`, and both rule blocks:

```yaml
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
```

## Why `policyTypes` and `ingress`/`egress`?

They look redundant but serve different roles:

| Piece | Role |
|-------|------|
| `policyTypes` | Declares **which directions** this policy enforces — and turns on **default-deny** for those directions |
| `ingress` / `egress` | The **allow list** — permitted sources (`from`) or destinations (`to`) |

- `policyTypes: [Ingress]` with **no** `ingress` rules → deny all incoming.
- `ingress` rules present but `Egress` **not** in `policyTypes` → egress rules are **ignored**.
- If `policyTypes` is omitted, Kubernetes **infers** it from the rules you define (explicit `policyTypes` is safer on the exam).

## Multiple rules and multiple policies

**Multiple `ingress` or `egress` entries in one policy** — the lists are combined with **OR** (traffic is allowed if it matches **any** rule):

```yaml
ingress:
- from:                              # rule 1: from frontend
  - podSelector:
      matchLabels:
        role: frontend
  ports:
  - protocol: TCP
    port: 80
- from:                              # rule 2: from monitoring
  - podSelector:
      matchLabels:
        role: monitoring
  ports:
  - protocol: TCP
    port: 9090
```

Within one rule, multiple `from` / `to` peers are also **OR**. **`namespaceSelector` + `podSelector` in the same peer** is **AND** (Pod must be in that namespace **and** match the label).

**Multiple NetworkPolicy objects on the same Pod** — if several policies select the same Pod (same labels), allowed traffic is the **union** of all policies: traffic is permitted if **any** selecting policy allows it.

## Common Use Cases

- **Namespace isolation** — `dev` Pods can never talk to `prod` Pods.
- **Database lockdown** — deny all ingress to DB Pods except from `tier: api`.
- **Block egress to the internet** — deny outgoing traffic except specific CIDRs/ports.
- **Zero-trust** — start with a cluster-wide **default-deny**, then add explicit allow rules.

## Constraints (Important)

- **CNI-enforced** — policies only work if your CNI plugin supports them (Calico, Cilium, Weave Net). No supporting CNI → policies have **no effect**.
- **Silent failures** — a misconfigured/overlapping policy causes hard-to-trace connectivity loss (no clear error).
- **Default allow** — if no policy selects a Pod, all traffic is allowed; use a catch-all default-deny for true segmentation.
- **Layers 3/4 only** — filter by IP, port, protocol (TCP/UDP). No Layer 7 (HTTP headers, URLs).
- **Label-dependent** — inconsistent labeling makes policies ineffective or unmanageable.

## CKAD Tips

- Empty `podSelector: {}` selects **all** Pods in the namespace.
- A policy with `policyTypes` but no matching rules = **deny all** for that direction.
- Distinguish `from` (ingress source) vs `to` (egress destination).
- Combining `namespaceSelector` + `podSelector` in one `from`/`to` entry is an **AND**; separate list items are **OR**.
- Multiple `ingress`/`egress` rules in one policy = **OR**; multiple policies on the same Pod = **OR** (union of allows).
- `policyTypes` declares direction + default-deny; `ingress`/`egress` blocks are the allow list — rules without a matching `policyTypes` entry are ignored.

## Key Takeaway

NetworkPolicies use `podSelector` + `policyTypes` + `ingress`/`egress` rules to whitelist allowed traffic. One policy can enforce both directions, stack multiple allow rules (OR), and multiple policies on the same Pod combine permissively. Selecting a Pod flips it to default-deny for that direction — but only if a supporting CNI plugin is installed.
