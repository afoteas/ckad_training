# Advanced Volume Mounts: subPath, Projected, and Lifecycle Hooks

This lesson covers three CKAD-relevant patterns beyond basic volume mounts: **`subPath`** (single-file mounts), **projected volumes** (combine sources), and **lifecycle hooks** (`postStart` / `preStop`).

For basic volume types, see [08-VolumesInPods](../08-VolumesInPods/readme.md).

## Demo Files

| File | Purpose |
|------|---------|
| `app-config.yaml` | ConfigMap with two keys |
| `subpath-pod.yaml` | Mount one ConfigMap key as a file via `subPath` |
| `projected-volume-pod.yaml` | ConfigMap + Downward API in one projected volume |
| `lifecycle-hooks-deployment.yaml` | `postStart` and `preStop` hooks |

## subPath — Mount One Key as a File

Without `subPath`, mounting a ConfigMap at `/config` creates a directory with all keys. With `subPath`, you mount **one key** at an exact file path:

```bash
kubectl apply -f app-config.yaml
kubectl apply -f subpath-pod.yaml
kubectl exec subpath-demo -- cat /config/welcome.txt
```

Expected: `hello from configmap`

**Exam use case:** mount `nginx.conf` from a ConfigMap to `/etc/nginx/nginx.conf` without overwriting the whole directory.

## Projected Volume — Multiple Sources, One Mount

A projected volume combines ConfigMap, Secret, Downward API, and ServiceAccount token sources into a single directory:

```bash
kubectl apply -f projected-volume-pod.yaml
kubectl logs projected-demo
```

You should see the config text and the Pod name from the Downward API.

## Lifecycle Hooks

| Hook | When | Typical use |
|------|------|-------------|
| `postStart` | Immediately after container starts | Register with service, write readiness file |
| `preStop` | Before container receives SIGTERM | Drain connections, flush buffers |

```bash
kubectl apply -f lifecycle-hooks-deployment.yaml
kubectl get pods -l app=lifecycle-demo
kubectl exec <pod> -- cat /usr/share/nginx/html/ready
```

`preStop` runs before termination — pair with `terminationGracePeriodSeconds` so the hook has time to finish.

## Cleanup

```bash
kubectl delete -f lifecycle-hooks-deployment.yaml -f projected-volume-pod.yaml -f subpath-pod.yaml -f app-config.yaml
```

## CKAD Tips

- `subPath` only works for **one file per mount** — do not use it to mount a whole ConfigMap directory.
- Projected volumes reduce multiple `volumes` entries to one mount point.
- `postStart` runs **async** with the main process — do not rely on it completing before the app starts; use a **readiness probe** for that.
- `preStop` + sleep is a common pattern to allow Endpoints to update before the Pod stops.

## Key Takeaway

Use `subPath` for single-file ConfigMap/Secret mounts, projected volumes to combine config + metadata in one mount, and lifecycle hooks for startup registration and graceful shutdown.
