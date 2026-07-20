# Scheduling with Node Selectors and Affinity

Kubernetes can place Pods automatically, but some workloads need placement constraints for hardware, security, or environment segregation.

## Node Selector

`nodeSelector` is the simplest hard constraint.

- Pod schedules only on nodes with exact matching label key/value.
- If no node matches, Pod remains `Pending`.

## Node Affinity

`nodeAffinity` is more expressive than `nodeSelector`.

- Supports operators such as `In`, `NotIn`, and `Exists`.
- Supports hard rules (`requiredDuringSchedulingIgnoredDuringExecution`).
- Supports soft preferences (`preferredDuringSchedulingIgnoredDuringExecution`).

## Hard vs Soft Matching

- Hard: must match, or Pod is unscheduled.
- Soft: scheduler tries to match, but may place elsewhere if needed.

## Common Use Cases

- GPU workloads on labeled GPU nodes.
- SSD-bound workloads on low-latency storage nodes.
- Environment isolation with labels like `environment=prod` and `environment=dev`.
- Compliance workloads pinned to hardened nodes.

## Key Takeaway

Use `nodeSelector` for simple mandatory placement and `nodeAffinity` for flexible, production-grade scheduling logic.
