# Canary Deployments and Progressive Delivery

This lesson introduces canary deployment strategy and progressive delivery principles.

## Concept

A canary release sends a small portion of traffic to a new version while most users continue on the stable version.

## Why Use Canary

- reduces blast radius of bad releases
- enables gradual confidence building
- supports data-driven promotion decisions

## Progressive Delivery Flow

1. Deploy new version with small traffic share.
2. Observe errors, latency, and resource behavior.
3. Increase traffic in controlled steps.
4. Promote to full rollout or rollback on issues.

## Common Traffic Steps

- 5%
- 20%
- 50%
- 100%

## Summary

Canary delivery is a practical risk-control method for production releases when observability and rollback are in place.
