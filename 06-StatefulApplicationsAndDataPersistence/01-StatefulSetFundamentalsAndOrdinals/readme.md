# StatefulSet Fundamentals and Ordinals

Stateful workloads need guarantees that Deployments do not provide by default.

## Why StatefulSets

Use StatefulSets when the app needs:

- stable identity (predictable pod names and DNS)
- sticky storage (same disk reattached after restart)
- ordered startup, scale, and termination behavior

Typical examples:

- MySQL, PostgreSQL
- Kafka, RabbitMQ
- Redis clusters and other partition-aware systems

## StatefulSet Guarantees

1. Stable pod identities: `app-0`, `app-1`, `app-2`
2. One persistent volume per pod identity
3. Ordered rollout/scale/termination
4. Predictable lifecycle useful for leader election and quorum systems

## Ordinals

Ordinal suffixes (`-0`, `-1`, `-2`) matter for stateful software.

- startup order follows ordinal order
- shutdown order is graceful and predictable
- a restarted pod keeps the same name and reattaches its own disk

Example outcome:

- if `mysql-1` restarts, it comes back as `mysql-1` and gets the same PVC/PV data

## Stateful vs Stateless Mental Model

- Deployment (stateless): hotel room, any room is fine
- StatefulSet (stateful): apartment lease, fixed identity and mailbox/storage

If your app is truly stateless (no local data, no stable identity need), a Deployment is simpler.

## Example StatefulSet YAML

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
	name: mysql
spec:
	serviceName: "mysql"
	replicas: 3
	selector:
		matchLabels:
			app: mysql
	template:
		metadata:
			labels:
				app: mysql
		spec:
			containers:
				- name: mysql
					image: mysql:8
					ports:
						- containerPort: 3306
```

This creates three ordered pods (`mysql-0`, `mysql-1`, `mysql-2`) under one StatefulSet controller.

## CKAD Tips

- There is no `kubectl create statefulset` generator — scaffold from a Deployment YAML, then change `kind`, and add `serviceName` and `volumeClaimTemplates`.
- A StatefulSet needs a headless Service (`clusterIP: None`) referenced by `serviceName` for stable per-pod DNS (`<pod>.<service>`).
- Scale in ordinal order with `kubectl scale statefulset <name> --replicas=N`; pods are created/removed lowest-to-highest / highest-to-lowest.
- `podManagementPolicy` defaults to `OrderedReady`; use `Parallel` only when startup order does not matter.
- Deleting a StatefulSet leaves its PVCs behind — remove them explicitly with `kubectl delete pvc <name>`.

## Key Takeaway

Reach for a StatefulSet when a workload needs stable network identity, sticky per-pod storage, and ordered lifecycle; ordinals (`app-0`, `app-1`) guarantee each pod keeps its name and its own volume across restarts.
