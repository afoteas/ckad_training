# Implementing Kustomize Overlays for Dev and Prod Environments

## Goal
Use one base Deployment and two overlays to create environment-specific behavior:
- dev: fewer replicas for lower cost
- prod: more replicas and stricter resource settings

## Folder structure
```text
.
├── base/
│   ├── deployment.yaml
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml
    └── prod/
        └── kustomization.yaml
```

## What each layer does

### Base
- Defines `Deployment/web-app`
- Sets shared defaults (image, labels, selectors)
- Default replica count in base is 3

### Dev overlay
- References `../../base`
- Adds `env: dev` label
- Patches replica count to 1

### Prod overlay
- References `../../base`
- Adds `env: prod` label
- Patches replica count to 5
- Patches container resources:
  - requests: `cpu=200m`, `memory=128Mi`
  - limits: `cpu=500m`, `memory=256Mi`

## Render manifests before applying
Render helps validate exactly what Kubernetes will receive.

```bash
kubectl kustomize overlays/dev
kubectl kustomize overlays/prod
```

## Apply overlays
```bash
kubectl apply -k overlays/dev
kubectl apply -k overlays/prod
```

## Verify results
```bash
kubectl get deploy web-app -o wide
kubectl get deploy web-app -o yaml | grep -A5 -E "replicas:|resources:"
```

To inspect labels:
```bash
kubectl get deploy web-app --show-labels
```

## Remove resources
```bash
kubectl delete -k overlays/dev
kubectl delete -k overlays/prod
```

## Common troubleshooting
- Patch not applied:
  - Ensure target matches exactly:
    - kind: `Deployment`
    - name: `web-app`
- Wrong path to base:
  - Check `resources: - ../../base` in overlay kustomization files.
- Unexpected output:
  - Re-run `kubectl kustomize overlays/<env>` and inspect rendered YAML first.

## CKAD tip
In the exam, always render first, then apply, then verify with `kubectl get` and `kubectl describe` before moving to the next task.

## Transcript Enhancements (Preserved Notes Kept)

### Overlay Intent in This Demo

- `dev` overlay lowers replica count for cost-efficient development.
- `prod` overlay increases replicas and enforces stricter resource requests/limits.

### Promotion Pattern

```bash
kubectl apply -k overlays/dev
kubectl apply -k overlays/prod
```

Same base manifests are reused while overlays safely represent environment-specific operational policies.

## CKAD Tips

- Render each overlay with `kubectl kustomize overlays/<env>` before running `kubectl apply -k overlays/<env>`.
- Patches must match the target `kind` and `name` exactly (`Deployment`/`web-app`) or they silently do nothing.
- Overlays adjust `replicas` and container resource requests/limits per environment while reusing one base.
- Verify with `kubectl get deploy web-app -o wide` and `--show-labels`; clean up with `kubectl delete -k overlays/<env>`.
- Mind the namespace — query the same namespace the overlay sets or `kubectl get` returns nothing.

## Key Takeaway

One base plus dev and prod overlays lets you tune replicas and resources per environment reproducibly; the reliable exam workflow is always render, then apply, then verify.
