# Advanced Ingress: TLS, Host, and Path Rules

Advanced Ingress rules add the features production apps need: **HTTPS/TLS**, **host-based routing** (multiple domains), and **path-based routing** (traffic segmentation by URL).

For basic Ingress, see [06-DeployingNGINXIngressAndBasicRouting](../06-DeployingNGINXIngressAndBasicRouting/readme.md).

## Example Files

| File | Purpose |
|------|---------|
| `tls-ingress.yaml` | TLS termination referencing a `kubernetes.io/tls` Secret |
| `host-path-ingress.yaml` | Host-based + path-based routing across Services |

## TLS Termination

The ingress controller (e.g. NGINX) holds the private key and certificate, decrypts incoming traffic at the edge, and forwards unencrypted traffic to Pods — so applications don't manage certificates themselves.

It requires a Kubernetes Secret of type `kubernetes.io/tls` containing the cert and key:

```bash
kubectl create secret tls tls-secret --cert=tls.crt --key=tls.key
```

The Ingress references it in the `tls` section:

```yaml
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: tls-secret
  rules:
  - host: myapp.example.com
    ...
```

One centralized TLS setup can secure all Services exposed by that Ingress.

## Host-Based Routing

Serve multiple domains from one controller:

| | Single host | Multiple hosts |
|--|------------|----------------|
| Mapping | One domain → one backend | Many domains → different Services |
| Use case | Small apps | Multi-tenant / SaaS platforms |
| DNS | Simpler | Flexible scaling per domain |

## Path-Based Routing

Route by URL path under a single hostname — key for microservices:

```text
example.com/api/*  → api service
example.com/web/*  → web/frontend service
```

Each Service owns a distinct path segment, letting you expose dozens of Services under one hostname.

## Operational Challenges

- **Certificate expiry** — use an automated system like **Cert-Manager** to renew TLS secrets before expiry (avoids sudden HTTPS downtime).
- **Overlapping paths** — use specific `pathType` (`Prefix`, `Exact`) and order most-specific first.
- **Controller differences** — annotations/features differ between NGINX, Traefik, Istio; migrating means rewriting manifests.
- **Over-broad paths** — a wide `/` Prefix can accidentally expose admin-only paths.
- **Bottlenecks** — consolidating high-traffic domains onto one controller needs sufficient CPU/memory.

## CKAD Tips

- TLS Secret must be type `kubernetes.io/tls` (keys `tls.crt` / `tls.key`); reference it via `spec.tls[].secretName`.
- `spec.tls[].hosts` must match the `rules[].host` you want secured.
- `pathType: Exact` matches the exact path; `Prefix` matches path prefixes.

## Key Takeaway

Use the `tls` section (with a `kubernetes.io/tls` Secret) for HTTPS at the edge, `host` rules to split by domain, and `path` rules to split by URL — the building blocks for secure, multi-service web apps behind one Ingress.
