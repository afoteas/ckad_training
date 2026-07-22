# Ingress Controllers and Resources

Ingress provides centralized **Layer 7 (HTTP/HTTPS)** routing to Services inside the cluster. It is typically the first point of contact for external web traffic, making routing decisions before the request reaches any Pod.

For a hands-on install and routing demo, see [06-DeployingNGINXIngressAndBasicRouting](../06-DeployingNGINXIngressAndBasicRouting/readme.md).

## Example File

- `ingress-example.yaml` — host + path-based routing to a `web` Service

## Why Ingress

Unlike LoadBalancer Services (simple TCP/UDP forwarding), Ingress can interpret HTTP **hostnames, URLs, and paths** to direct traffic to different Services. It also terminates TLS at the cluster edge.

## Controller vs Resource

This is the most important distinction. Think of it as **web server vs its config**:

| Ingress **Controller** | Ingress **Resource** |
|------------------------|----------------------|
| The web server that implements the rules (NGINX, Traefik, Istio) | The configuration — a Kubernetes object |
| Runs as a Deployment/Pod in the cluster | Describes host/path routing and TLS in YAML |
| Must be installed **separately** (not part of core Kubernetes) | Consumed by the controller to configure traffic flow |
| Processes resources and applies their config | Declared with a YAML manifest |

**Key point:** an Ingress resource does nothing unless an Ingress controller is running to act on it.

## Example Ingress Resource

```yaml
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web
            port:
              number: 80
```

Any HTTP traffic for `example.com` with a path starting with `/` (Prefix) is forwarded to the `web` Service on port 80.

## Benefits

- **One public LoadBalancer** fronts the controller; all Services are exposed via host/path routing behind the same IP.
- **TLS termination** using Kubernetes secrets — offloads crypto from application Pods.
- **Fewer DNS records** — point one/two records at the central Ingress endpoint.
- **Host-based routing** — `prod.app.com` vs `dev.app.com`.
- **Path-based routing** — `app.com/api` vs `app.com/web`.

## Challenges

- You must **install and manage** the controller yourself (adds complexity).
- Features (WebSockets, traffic weighting, rewrites, annotations) **differ between controllers**.
- **Debugging spans layers** — LoadBalancer, controller, resource rules, Service, Pods.
- **TLS mistakes** (bad secret reference, cert chain issues) can block all HTTPS at the edge.
- The controller can become a **bottleneck / single point of failure** if under-resourced.

## CKAD Tips

- `pathType` is required — usually `Prefix` or `Exact`.
- Backend uses `service.name` + `service.port.number` (networking.k8s.io/v1).
- Remember: no controller running → the resource has no effect.

## Key Takeaway

The Ingress **controller** is the running proxy; the Ingress **resource** is its declarative config. Together they enable host- and path-based Layer 7 routing and TLS termination behind a single entry point.
