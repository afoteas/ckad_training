# Health Checks and Automated Rollbacks

## Overview

GitOps does not remove the need for safe rollout practices. Readiness, liveness, and progressive verification are essential to detect bad releases and recover quickly.

## What You Should Know

- Readiness probe failures should block traffic to unhealthy pods.
- Liveness probes should restart deadlocked processes.
- Argo CD health checks can report non-healthy states and trigger alerting.
- Rollbacks are fastest when previous known-good revision is clearly identified.

## Kubernetes Health Basics

- readinessProbe controls endpoint availability.
- livenessProbe controls container restarts.
- startupProbe protects slow-starting applications.

## Practical Tips

- Use realistic probe timings to avoid false failures.
- Keep rollout strategy conservative for critical apps.
- Store known-good revisions or release tags for rapid rollback.
- Combine monitoring alerts with GitOps status signals.

## Failure Drill

- Deploy a version with a bad readiness endpoint.
- Observe degraded health state.
- Revert to previous commit and confirm recovery.
