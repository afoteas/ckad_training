# Power-User kubectl: JSONPath & Patching

This lesson focuses on using kubectl beyond default `get` output so you can query exact fields, extract script-friendly data, and make small live changes without a full redeploy.

## Why This Matters

- default kubectl output often lacks the detail needed for troubleshooting
- JSONPath lets you point to exact fields inside Kubernetes objects
- patching makes low-risk live changes faster than replacing the whole manifest
- these skills prepare you for deeper API-level automation

## JSONPath Basics

Kubernetes objects are exposed as JSON under the hood. JSONPath lets you extract only the fields you care about.

Common pattern:

```bash
kubectl get <resource> -o jsonpath='{<path>}'
```

## Useful Examples

Get only pod names:

```bash
kubectl get pods -o jsonpath='{.items[*].metadata.name}'
```

Get a Service cluster IP:

```bash
kubectl get svc myservice -o jsonpath='{.spec.clusterIP}'
```

Show node CPU capacity:

```bash
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.capacity.cpu}{"\n"}{end}'
```

## Why Patch Instead of Redeploy?

If you only need to change one field, replacing an entire manifest is slower and higher risk than a targeted update.

Patching flow:

1. Identify the object and field to change.
2. Run `kubectl patch` with a JSON or strategic merge payload.
3. Validate with `kubectl get` or `kubectl describe`.

## Patch Example

Increase a Deployment replica count in one command:

```bash
kubectl patch deployment myapp -p '{"spec":{"replicas":5}}'
```

This updates the live object immediately without editing YAML first.

## Server-Side Apply

`kubectl apply --server-side` lets the API server track field ownership per tool or user.

Why it helps:

- better merge conflict handling than client-side apply
- clearer field ownership across teams and automation
- especially useful for GitOps and multi-team environments

## CKAD Tips

- JSONPath and `kubectl patch` are directly examinable — practice `kubectl get <res> -o jsonpath='{.spec.field}'` until it's muscle memory.
- Use `{range .items[*]}...{end}` with `{"\t"}` and `{"\n"}` to build custom table-style output across a list.
- `kubectl patch <res> <name> -p '{"spec":{"replicas":5}}'` defaults to a strategic merge patch; add `--type=json` for JSON Patch (`op`/`path`/`value`) and `--type=merge` for a plain merge.
- `kubectl explain <res>.spec --recursive` helps you find the exact field path before writing JSONPath.
- Remember `kubectl apply --server-side` for shared-ownership scenarios, but plain `kubectl patch`/`edit` is the quickest fix under exam time pressure.

## Key Takeaway

- use JSONPath when you need exact fields, not full object output
- use patch for quick surgical changes during incidents or testing
- follow live changes with Git updates to avoid configuration drift
- use server-side apply when multiple tools manage the same objects