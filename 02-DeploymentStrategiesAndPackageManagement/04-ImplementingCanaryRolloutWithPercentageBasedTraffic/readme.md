# Implementing Canary Rollout with Percentage-Based Traffic

## Scenario
Deploy `critical-api` with 5 replicas using a rolling update strategy. By tuning
`maxUnavailable` and `maxSurge`, you control what percentage of pods serve the new
version at any point — simulating a canary-style gradual rollout.

## Default Rolling Update Strategy
The YAML starts with:
- `maxUnavailable: 1` — at most 1 pod can be down during the update
- `maxSurge: 1` — at most 1 extra pod can be created above the desired count

With 5 replicas this means ~20% of traffic shifts at a time.

## Steps

### 1. Deploy the initial version (v1.0)
```bash
kubectl apply -f rolling-update-demo.yaml
```

### 2. Watch ReplicaSets to observe the rollout behaviour
```bash
kubectl get rs -w
```
During a rolling update you will see the old RS scale down while the new RS scales up.

### 3. Simulate a canary rollout — set maxUnavailable to 0
```bash
kubectl edit deploy critical-api
```
Change the strategy so no existing pods are taken down before a new one is ready:
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0   # never remove an old pod until a new one is Ready
    maxSurge: 1         # bring up one new pod at a time
```
With 5 replicas and `maxSurge: 1`, only 1 new pod is added at a time (~20% canary slice).
Increase `maxSurge` to shift more traffic faster, e.g. `maxSurge: 2` = 40% canary.

### 4. Trigger an update to observe the controlled rollout
```bash
kubectl set image deploy critical-api api-container=nginx:1.25.1
kubectl rollout status deploy critical-api
```

### 5. Confirm the rollout
```bash
kubectl get rs
kubectl get pods -o wide
```
You should see the old ReplicaSet scaling to 0 and the new one reaching 5.

## Key concepts

| Parameter | Effect |
|---|---|
| `maxUnavailable: 0` | Zero-downtime — no pod removed until replacement is Ready |
| `maxSurge: 1` | One pod canary slice at a time (~20% with 5 replicas) |
| `maxSurge: 2` | Two pods at a time (~40% canary slice) |

## Notes
- True percentage-based canary (e.g. 10%) requires a service mesh (Istio, Linkerd) or
  an Ingress controller with traffic splitting. ReplicaSet-based canary is approximate
  and tied to replica count.
- `kubectl rollout pause deploy critical-api` lets you freeze the rollout mid-way to
  manually validate the canary pods before continuing with `kubectl rollout resume`.

## Transcript Enhancements (Preserved Notes Kept)

### Safety vs Speed Profiles

Slow and safe profile:

- `maxUnavailable: 0`
- `maxSurge: 1`

Effect: no existing pod removed before replacement is ready.

Aggressive profile:

- high `maxUnavailable`
- low `maxSurge`

Effect: faster replacement but potential temporary outage.

### Practical Insight

For critical APIs, use conservative rollout settings and only increase aggressiveness when cluster capacity and SLO risk are well understood.

## CKAD Tips

- `maxUnavailable` and `maxSurge` live under `spec.strategy.rollingUpdate` — memorize what each one controls.
- `maxUnavailable: 0` + `maxSurge: 1` is the safest profile: never drop a pod until the new one is Ready (≈20% slice with 5 replicas).
- Trigger updates imperatively with `kubectl set image deploy critical-api api-container=nginx:1.25.1` and watch `kubectl rollout status`.
- `kubectl rollout pause` / `resume deploy <name>` freezes a rollout mid-way so you can validate the canary pods.
- Replica-based canary is only approximate — exact percentages require a service mesh or Ingress traffic splitting.

## Key Takeaway

Tuning `maxUnavailable` and `maxSurge` on a RollingUpdate controls how many pods carry the new version at once, approximating a canary rollout without any extra tooling.