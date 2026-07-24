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

## Files in This Section

- `argocd-values-update.yaml`: Helm values override used during Argo CD upgrade.
- `application-health-rollback.yaml`: Application sync policy with prune, self-heal, and retry limit.

## Update Argo CD and App Policy

1. Upgrade Argo CD using base values from section 02 plus this section override file.

```bash
cd /home/foteas/code/ckad_training/GitOpsAndContinuousDeliveryOnKubernetes/04-HealthChecksAndAutomatedRollbacks
helm upgrade --install argocd argo/argo-cd \
	--namespace argocd \
	--values ../02-InstallingArgoCDOnACluster/argocd-values.yaml \
	--values argocd-values-update.yaml
```

2. Wait for Argo CD components to be ready.

```bash
kubectl rollout status deploy/argocd-server -n argocd
kubectl rollout status deploy/argocd-repo-server -n argocd
kubectl rollout status deploy/argocd-applicationset-controller -n argocd
```

3. Apply the Application sync policy that includes automated retry.

```bash
kubectl apply -f application-health-rollback.yaml
```

Alternative: use Argo CD CLI with the same YAML file.

```bash
argocd app create ckad-sample \
	--file /home/foteas/code/ckad_training/GitOpsAndContinuousDeliveryOnKubernetes/04-HealthChecksAndAutomatedRollbacks/application-health-rollback.yaml \
	--upsert

argocd app get ckad-sample
```

4. If needed, patch only the retry block on an existing app.

```bash
kubectl -n argocd patch application ckad-sample --type merge -p '{"spec":{"syncPolicy":{"retry":{"limit":3}}}}'
```

5. Verify the live policy.

```bash
kubectl -n argocd get application ckad-sample -o yaml | grep -A8 "syncPolicy"
```

## Notes

- In Argo CD, `retry.limit` belongs to the Application spec, not Helm values.
- Keep `server.insecure: true` only for local/dev environments.

## CKAD Tips

- Probes are heavily examinable: know `readinessProbe` (gates traffic/endpoint membership), `livenessProbe` (restarts a wedged container), and `startupProbe` (protects slow starters) under `spec.containers[].`.
- Memorize the three handler types — `httpGet`, `tcpSocket`, and `exec` — plus the timing fields `initialDelaySeconds`, `periodSeconds`, `timeoutSeconds`, `failureThreshold`, and `successThreshold`.
- Diagnose probe failures fast: `kubectl describe pod` shows probe events/reasons, and `kubectl get pod -w` reveals restart counts from failing liveness checks.
- For rollout/rollback of native Deployments (the exam's version of "rollback"): `kubectl rollout status`, `kubectl rollout history`, and `kubectl rollout undo deploy/<name> [--to-revision=N]`.
- The Argo CD Helm upgrade and `Application` `retry.limit`/`syncPolicy` details are not on the exam — focus your time on the probe YAML and `kubectl rollout` commands.

## Key Takeaway

Safe delivery still depends on well-configured readiness, liveness, and startup probes plus a clear known-good revision to roll back to; for CKAD, master the probe fields and `kubectl rollout undo` rather than the Argo CD-specific automation shown here.
