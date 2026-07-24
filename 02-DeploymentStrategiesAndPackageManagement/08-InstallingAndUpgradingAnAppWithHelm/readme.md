# Installing and Upgrading an App with Helm

This lab walks through a full Helm lifecycle:
- add and refresh a chart repository
- install a release
- inspect release state and values
- run an upgrade
- validate rollout
- rollback if needed

Important note for this specific command set:
- externalDatabase.host=localhost is intentionally problematic inside Kubernetes.
- In a pod, localhost means the same pod, not your host machine.
- This can cause rollout failures and is useful for rollback practice.

## 1. Add and refresh the chart repository

Purpose:
- Register Bitnami as a source of charts.
- Refresh local index so Helm knows available versions.

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

## 2. Install the WordPress release

Purpose:
- Create a release named my-blog from the Bitnami WordPress chart.
- Disable internal MariaDB and point to an external DB host.

```bash
helm install my-blog bitnami/wordpress --set mariadb.enabled=false --set externalDatabase.host=localhost --set externalDatabase.password=mypassword --set wordpressPassword=helm-demo-pass
```

## 3. Verify pods, release state, and user values

Purpose:
- Check if pods were created.
- Inspect release status.
- Confirm values that were applied.

```bash
kubectl get pods -l app.kubernetes.io/instance=my-blog
helm status my-blog
helm get values my-blog
```

## 4. Upgrade the release

Purpose:
- Apply a configuration change and request a new image tag.
- Trigger a new rollout.

```bash
helm upgrade my-blog bitnami/wordpress --set mariadb.enabled=false --set externalDatabase.host=localhost --set externalDatabase.password=mypassword --set wordpressPassword=helm-demo-peos --set image.tag=latest
```

## 5. Check rollout and release status

Purpose:
- Confirm whether the deployment reaches Ready.
- If it fails with exceeded progress deadline, inspect and rollback.

```bash
kubectl rollout status deployment my-blog-wordpress
helm status my-blog
```

## 6. Rollback to previous revision

Purpose:
- Recover quickly after a failed or unhealthy upgrade.

```bash
helm rollback my-blog 1
```

## Troubleshooting quick notes

- If rollout fails, inspect pods:
```bash
kubectl get pods -l app.kubernetes.io/instance=my-blog
kubectl describe pod <pod-name>
kubectl logs <pod-name> --all-containers --tail=200
```
- If you want a successful install without external DB setup complexity, omit the external database overrides and let the chart deploy its internal MariaDB.

## Transcript Enhancements (Preserved Notes Kept)

### End-to-End Helm Flow

1. `helm repo add` and `helm repo update`
2. `helm install` with required value overrides
3. validate with `helm status` and `kubectl get pods`
4. inspect effective values via `helm get values`
5. upgrade with new settings using `helm upgrade`
6. rollback to known good revision using `helm rollback`

### Practical Note

For demos and training, intentionally imperfect values are useful for learning rollback behavior and operational diagnosis.

## CKAD Tips

- Practice the full lifecycle end to end: `helm repo add`/`update` → `helm install` → `helm upgrade` → `helm rollback`, checking `helm status` at each step.
- Inspect the values actually applied with `helm get values <release>` and the release timeline with `helm history <release>`.
- `--set key=value` overrides chart values inline and multiple `--set` flags stack.
- Diagnose a failed upgrade with `kubectl rollout status deployment <name>`, then `kubectl describe pod` and `kubectl logs`.
- Gotcha: `externalDatabase.host=localhost` resolves to the pod itself, not your host — a deliberate failure to practice rollback.

## Key Takeaway

A Helm release moves through install → upgrade → rollback, and combining `helm status`/`history` with `kubectl` diagnostics lets you validate each step and recover quickly from a bad upgrade.