# Blue/Green Deployment Pattern

This lesson introduces the Blue/Green deployment strategy for low-risk application releases.

## Concept

Blue/Green keeps two environments:

- Blue: current live version
- Green: new candidate version

Traffic switches from Blue to Green only after validation.

## Benefits

- near-zero downtime cutover
- fast rollback by switching traffic back
- safer production testing before full release

## Typical Workflow

1. Deploy Green version alongside Blue.
2. Run validation checks against Green.
3. Switch traffic to Green.
4. Monitor health and business metrics.
5. Keep Blue temporarily for quick fallback.

## Summary

Blue/Green is ideal when you need predictable cutover and fast rollback with minimal user impact.

## Transcript Enhancements (Preserved Notes Kept)

### Blue/Green Mechanics

- Blue is current live environment.
- Green is staged new version.
- One Service selector determines active traffic target.

### Operational Strengths

1. near-instant cutover via selector change
2. near-instant rollback via selector revert
3. strong pre-production validation on Green before user exposure

### Trade-Offs

1. temporary double resource usage (compute and memory)
2. higher complexity for stateful systems and data synchronization
3. requires disciplined internal testing before cutover

## CKAD Tips

- Blue/Green is explicitly named in the CKAD curriculum — know it means two full versions running side by side with a Service selector deciding which is live.
- Do the cutover imperatively: `kubectl patch svc <svc> -p '{"spec":{"selector":{"version":"green"}}}'` is faster than `kubectl edit`.
- Rollback is just flipping the selector back to `blue`; keep the Blue Deployment running until Green is validated.
- Remember the main trade-off: you pay for double the compute/memory while both environments coexist.
- Stateful apps are the hard case — the traffic switch is easy, but database/data synchronization is not.

## Key Takeaway

Blue/Green delivers near-zero-downtime releases and instant rollback by switching a Service selector between two parallel versions, at the cost of temporarily running double the resources.
