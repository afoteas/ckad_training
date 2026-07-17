# Port-forwarding & Local Debugging Techniques

This lesson explains how to debug internal-only cluster services safely using `kubectl port-forward` without exposing them publicly.

## Why Port-forward

- access ClusterIP-only services from local machine
- avoid temporary public exposure through LoadBalancer/Ingress
- test APIs and databases from local tools quickly

## How It Works

1. local port is opened on your machine
2. kubectl proxies traffic through API server
3. traffic reaches target pod/service inside cluster

## Example

```bash
kubectl port-forward svc/mydb 5432:5432
```

Now local clients can connect to `localhost:5432` as if database was local.

## Common Use Cases

- test internal REST endpoints
- debug service-to-service behavior
- run integration checks from laptop
- connect local observability tooling to in-cluster endpoints

## Caveats

- tunnel ends when kubectl process exits
- not for production-scale traffic patterns
- requires proper Kubernetes API access permissions