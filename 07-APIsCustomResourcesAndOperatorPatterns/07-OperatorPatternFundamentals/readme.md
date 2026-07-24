# Operator Pattern Fundamentals

This lesson introduces operators as a way to encode day-2 operational knowledge directly into the cluster.

## Why Operators?

Manual operations such as upgrades, backups, and health checks work for small systems, but they do not scale well. Operators package those repetitive tasks into Kubernetes automation.

Examples of day-2 operations:

- install
- upgrade
- backup
- health monitoring
- scaling behavior

## The Core Pattern

The operator pattern is built around three steps:

1. Declare intent using a custom resource.
2. Watch for that resource with a controller.
3. Reconcile actual state until it matches desired state.

## Database Example

The transcript uses a database-style example where the operator can:

- observe a new database custom resource
- create the required pod and configuration
- monitor health
- apply updates
- trigger backups or scaling based on spec fields

## Building Blocks

- CRDs define the new resource type
- controller-runtime libraries simplify controller development
- events and watches detect changes in cluster state
- the reconcile function contains the logic that closes the gap between actual and desired state

## Benefits

- automates routine operations
- reduces human error
- makes recovery and scaling behavior more consistent
- turns team runbooks into cluster-native automation

## Trade-Offs

- requires strong domain knowledge to design well
- can add operational complexity if poorly implemented
- needs careful testing before production use

## CKAD Note

- Building operators and writing reconcile/controller logic (controller-runtime, watches) is **beyond CKAD scope** — you won't author controllers on the exam.
- What's worth knowing conceptually is the pattern: a CRD declares desired state and a controller continuously reconciles actual → desired, the same control-loop idea behind built-in controllers like Deployments.
- In-scope, examinable adjacent skills are CRD basics (`kubectl get crds`, `kubectl api-resources`) and consuming operator-provided custom resources with `kubectl apply`.
- Focus your exam prep on managing workloads declaratively, not on implementing operators.

## Key Takeaway

- operators combine CRDs with reconciliation logic
- they are most valuable for complex lifecycle management
- the quality of the operator depends on the quality of the encoded operational logic