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
