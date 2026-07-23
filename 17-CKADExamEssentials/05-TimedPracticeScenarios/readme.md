# Timed Practice Scenarios

Practice these **end-to-end** with a **10-minute timer** each. Use [lesson 02](../02-ImperativeKubectlAndManifestGeneration/readme.md) generators and [lesson 04](../04-PostTaskVerificationChecklist/readme.md) to verify.

Set namespace for all scenarios: `kubectl create namespace exam --dry-run=client -o yaml | kubectl apply -f -` then `kubectl config set-context --current --namespace=exam` (or pass `-n exam` on every command).

---

## Scenario 1: Deployment + Service + Probes (10 min)

**Task:** Create Deployment `web` (2 replicas, image `nginx:1.25`) with:
- liveness HTTP probe on `/` port 80
- readiness HTTP probe on `/` port 80
- CPU request `100m`, limit `200m`

Expose as ClusterIP Service `web-svc` on port 80.

**Verify:** `kubectl rollout status deploy/web` && `kubectl get endpoints web-svc`

**Relevant modules:** [01](../01-WorkloadandContainerImageFundamentals/readme.md), [05](../05-ObservabilityLoggingAndProbes/readme.md), [16](../16-ServicesIngressAndNetworkingFundamentals/readme.md)

---

## Scenario 2: ConfigMap + Secret + env/volume (10 min)

**Task:** Create ConfigMap `app-config` with `LOG_LEVEL=debug`. Create Secret `db-secret` with `password=exam123`. Deploy Pod `api` (image `busybox`, command sleep 3600) that:
- has env var `LOG_LEVEL` from ConfigMap
- mounts Secret key `password` at `/etc/db/password` (read-only)

**Verify:** `kubectl exec api -- printenv LOG_LEVEL` && `kubectl exec api -- cat /etc/db/password`

**Relevant modules:** [11](../11-ApplicationConfigurationAndSecurityFundamentals/readme.md)

---

## Scenario 3: Job with parallelism (8 min)

**Task:** Create Job `pi` that runs `perl -Mbignum=bpi -wle print bpi(2000)` (image `perl:5.34`), `completions: 4`, `parallelism: 2`, `backoffLimit: 3`.

**Verify:** `kubectl get job pi` → completions 4/4

**Relevant modules:** [06](../06-StatefulApplicationsAndDataPersistence/readme.md), [10](../10-BatchAndEventDrivenWorkloads/readme.md)

---

## Scenario 4: NetworkPolicy (10 min)

**Task:** Labels: `app=backend` on backend Pods, `role=frontend` on frontend Pods. Policy: only Pods with `role=frontend` may reach backend on TCP 80.

**Verify:** `kubectl describe networkpolicy` — correct podSelector and ingress from rule

**Relevant modules:** [16](../16-ServicesIngressAndNetworkingFundamentals/readme.md)

---

## Scenario 5: RBAC (8 min)

**Task:** ServiceAccount `deployer` can `get`, `list`, `watch` Deployments in namespace `exam`. Cannot delete Deployments.

**Verify:**
```bash
kubectl auth can-i list deployments --as=system:serviceaccount:exam:deployer -n exam
kubectl auth can-i delete deployments --as=system:serviceaccount:exam:deployer -n exam
```

**Relevant modules:** [11](../11-ApplicationConfigurationAndSecurityFundamentals/readme.md)

---

## Scenario 6: Ingress with path routing (12 min)

**Task:** Deployment `api` (nginx), Service `api-svc:80`. Ingress `app-ing` routes `exam.local/api` → `api-svc:80`.

**Verify:** `kubectl describe ingress app-ing`

**Relevant modules:** [16](../16-ServicesIngressAndNetworkingFundamentals/readme.md)

---

## Scenario 7: PVC + Deployment (10 min)

**Task:** PVC `data` 500Mi RWO. Deployment `store` (busybox) mounts PVC at `/data`, writes `exam-ok` to `/data/test.txt`.

**Verify:** `kubectl get pvc data` (Bound) && `kubectl exec <pod> -- cat /data/test.txt`

**Relevant modules:** [01](../01-WorkloadandContainerImageFundamentals/readme.md), [06](../06-StatefulApplicationsAndDataPersistence/readme.md)

---

## Scenario 8: Fix broken Deployment (8 min)

**Given:** Deployment with wrong container port, failing readiness probe, or image typo.

**Task:** Diagnose with `describe`/`logs`, fix manifest, rollout succeeds.

**Verify:** `kubectl get pods` — all Running, ready 1/1

**Relevant modules:** [08](../08-DebuggingAndTroubleshootingApplications/readme.md)

---

## Full Mock (2 hours)

Combine 15–17 scenarios above in random order. Rules:
- No pausing the timer
- Docs allowed (one tab)
- Skip after 7 min, return at end
- Score: completed + verified tasks / total

## Key Takeaway

Timed repetition builds muscle memory. If you can complete scenarios 1, 2, 5, and 7 in under 10 minutes each with verification, you are in strong CKAD shape.
