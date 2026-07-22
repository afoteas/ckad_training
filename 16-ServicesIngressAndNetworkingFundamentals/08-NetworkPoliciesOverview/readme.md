# Network Policies Overview

By default, **all Pods can talk to all other Pods** — Kubernetes networking is flat and open. NetworkPolicies are the firewall equivalent for microservices, enforcing which traffic flows are permitted.

For a hands-on demo, see [09-RestrictingTrafficWithNetworkPolicies](../09-RestrictingTrafficWithNetworkPolicies/readme.md).

## Example Files

| File | Purpose |
|------|---------|
| `networkpolicy-example.yaml` | Allow only `app: frontend` Pods to reach `app: nginx` on port 80 |
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

**Important:** if `policyTypes` includes `Ingress`, all incoming traffic to the selected Pods is **denied unless explicitly allowed** by an ingress rule.

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
- Combining `namespaceSelector` + `podSelector` in one `from` entry is an **AND**; separate list items are **OR**.

## Key Takeaway

NetworkPolicies use `podSelector` + `policyTypes` + `ingress`/`egress` rules to whitelist allowed traffic. Selecting a Pod flips it to default-deny for that direction — but only if a supporting CNI plugin is installed.
