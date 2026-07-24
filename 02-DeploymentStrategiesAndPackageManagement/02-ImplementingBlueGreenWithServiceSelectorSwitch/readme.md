# Implementing Blue/Green with Service Selector Switch

## Scenario
Run two identical deployments side by side — `app-blue` (v1.0) and `app-green` (v2.0).
The `app-gateway` Service routes all traffic to one version at a time via its `version`
label selector. Switching traffic is instant: one `kubectl edit` with zero downtime and
an easy rollback path (switch back to blue).

## Architecture
```
app-gateway (Service)
  selector: version=blue  ──▶  app-blue Pods  (v1.0)
                               app-green Pods (v2.0)  ← idle, ready to go live
```

## Steps

### 1. Deploy blue (v1.0) and the Service
```bash
kubectl apply -f switch-traffic.yaml
kubectl get deploy
```
This creates `app-blue` (2 replicas) and the `app-gateway` Service pointing at `version: blue`.

### 2. Deploy green (v2.0) alongside blue
```bash
kubectl apply -f app-green.yaml
kubectl get pods --show-labels
```
Both blue and green pods are now running. The Service still sends traffic only to blue.

### 3. Verify blue is serving traffic

From outside the cluster (port-forward):
```bash
kubectl port-forward svc/app-gateway 8080:80
# open http://localhost:8080 — should show "Welcome to BLUE - Version 1.0"
```

Or from a pod inside the cluster:
```bash
kubectl run -it --rm svc-test --image=curlimages/curl -- /bin/sh
curl http://app-gateway
exit
```
Expected response: `<h1>Welcome to BLUE - Version 1.0 </h1>`

### 4. Switch traffic to green (the cutover)
```bash
kubectl edit svc app-gateway
```
Change the selector from `version: blue` to `version: green`, then save.

```yaml
selector:
  app: color-app
  version: green   # changed from blue
```

### 5. Verify green is now serving traffic
```bash
kubectl run -it --rm svc-test --image=curlimages/curl -- /bin/sh
curl http://app-gateway
exit
```
Expected response: `<h1>Welcome to GREEN - Version 2.0</h1>`

### 6. Rollback — switch back to blue instantly
```bash
kubectl edit svc app-gateway
# change version: green back to version: blue
```

### 7. Clean up
```bash
kubectl delete -f switch-traffic.yaml
kubectl delete -f app-green.yaml
```

## Notes
- The cutover is **atomic and instant** — the Service selector update is applied immediately.
- Both environments run simultaneously, so green can be fully smoke-tested before cutover.
- Blue pods remain running after the switch, enabling a zero-risk rollback at any time.
- For a non-interactive selector patch (e.g. in CI/CD):
  ```bash
  kubectl patch svc app-gateway -p '{"spec":{"selector":{"version":"green"}}}'
  ```

## Transcript Enhancements (Preserved Notes Kept)

### Validation-first Workflow

1. deploy and verify blue environment
2. deploy green with distinct label
3. run smoke and integration checks on green
4. switch service selector to green
5. keep blue running briefly as rollback target

### Zero-Downtime Principle

Service cutover is network-routing based, not in-place replacement, which is why this method avoids deployment interruption during switch.

## CKAD Tips

- The entire cutover is one label change on the Service selector (`version: blue` → `version: green`) and it takes effect instantly.
- Prefer `kubectl patch svc app-gateway -p '{"spec":{"selector":{"version":"green"}}}'` over `kubectl edit` for speed and scriptability.
- Use `kubectl get pods --show-labels` to confirm exactly which pods a selector will match before switching.
- Smoke-test in-cluster fast: `kubectl run -it --rm curl --image=curlimages/curl -- curl http://app-gateway`.
- Leave `app-blue` running after cutover so rollback is just another selector flip.

## Key Takeaway

A single Service selector edit atomically shifts all traffic between two running Deployments, giving instant, zero-downtime cutover and an equally instant rollback path.