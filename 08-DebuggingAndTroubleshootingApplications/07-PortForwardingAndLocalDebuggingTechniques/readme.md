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

## CKAD Tips

- Syntax to know cold: `kubectl port-forward svc/<name> <local>:<remote>` (also works with `pod/<name>` and `deploy/<name>`).
- The mapping is `LOCAL:TARGET` — mixing these up is a common mistake; e.g. `8080:80` sends `localhost:8080` to the target's port 80.
- Use port-forward to test `ClusterIP`-only services locally without creating a `NodePort`/`LoadBalancer` or `Ingress`.
- The tunnel lives only while the `kubectl` process runs, so keep it in a separate terminal (or background it) while you `curl` from another.
- Add `--address 0.0.0.0` only if you deliberately need the forward reachable beyond `localhost` — otherwise leave it bound locally.

## Key Takeaway

`kubectl port-forward` creates a temporary local tunnel through the API server to an in-cluster pod or service, letting you test internal-only endpoints safely without exposing them publicly.