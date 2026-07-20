# Course Summary

In this module, you covered the practical controls that keep Kubernetes clusters stable, fair, and adaptive.

## What You Learned

- How requests and limits shape scheduling and runtime behavior.
- How ResourceQuota and LimitRange enforce multi-tenant governance.
- How node selectors and affinity rules guide Pod placement.
- How taints and tolerations enforce node-level access boundaries.
- How HPA uses metrics to scale workloads automatically.

## Operational Mindset

- Set resource values from observed usage, not guesswork.
- Combine placement rules with capacity planning.
- Use autoscaling with clear min/max safeguards.
- Verify behavior with `kubectl describe`, metrics, and watch commands.

## CKAD Focus

Prioritize hands-on fluency with:

- requests and limits in manifests
- scheduling constraints
- taints and tolerations
- HPA setup and validation

## Final Takeaway

Resource control, scheduling intent, and autoscaling policy are the core triad for reliable Kubernetes operations.
