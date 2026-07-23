# K8s training

> **CKAD exam prep:** Start with [17-CKADExamEssentials](17-CKADExamEssentials/readme.md) for the full study path, timed scenarios, and module priority guide.

## Must-know kubectl commands (CKAD)

Full generators and workflows: [17-02](17-CKADExamEssentials/02-ImperativeKubectlAndManifestGeneration/readme.md) · [17-04](17-CKADExamEssentials/04-PostTaskVerificationChecklist/readme.md)

### Observe

```bash
kubectl get all -n <ns> -o wide --show-kind    # workloads + services in one namespace
kubectl get pods -n <ns> -o wide               # node, IP, readiness
kubectl describe pod <name> -n <ns>            # events, probes, mounts, failures
kubectl logs <pod> -n <ns> -c <container>      # multi-container: always set -c
kubectl get events -n <ns> --sort-by=.lastTimestamp | tail -15
kubectl get endpoints <svc> -n <ns>            # empty = Service selector mismatch
kubectl explain pod.spec.containers.livenessProbe
```

### Generate YAML (exam speed)

These commands **print YAML to stdout** — they do not create anything in the cluster. The two flags that matter:

- `--dry-run=client` — build the object locally, do not send to the API server
- `-o yaml` — output as YAML (redirect with `> file.yaml`)

```bash
kubectl create deployment web --image=nginx --replicas=2 --dry-run=client -o yaml > deploy.yaml
kubectl expose deployment web --port=80 --target-port=8080 --dry-run=client -o yaml > svc.yaml
kubectl create configmap app --from-literal=key=val --dry-run=client -o yaml > cm.yaml
kubectl create secret generic db --from-literal=pass=x --dry-run=client -o yaml > secret.yaml

# Pod: --restart=Never → kind: Pod (without it, kubectl run creates a Deployment)
# Put --dry-run=client -o yaml BEFORE -- (after -- = container command, not kubectl flags)
kubectl run debug --image=busybox --restart=Never --dry-run=client -o yaml --command -- sleep 3600 > pod.yaml
```

Without `--dry-run=client -o yaml`, the same `kubectl run` line **creates a real Pod** in the cluster.

### Change live

```bash
kubectl apply -f <file> -n <ns>
kubectl scale deployment <name> --replicas=3 -n <ns>
kubectl set image deployment/<name> <container>=<image:tag> -n <ns>
kubectl rollout status deployment/<name> -n <ns>
kubectl rollout undo deployment/<name> -n <ns>
kubectl patch deployment <name> -n <ns> -p '{"spec":{"replicas":3}}'
kubectl label pod <name> env=prod -n <ns>
kubectl taint nodes <node> key=value:NoSchedule
```

### Context and debug

```bash
kubectl config set-context --current --namespace=<ns>   # default namespace for session
kubectl exec -it <pod> -n <ns> -- sh
kubectl port-forward svc/<name> 8080:80 -n <ns>
kubectl debug <pod> -n <ns> -it --image=busybox --target=<container>   # ephemeral container
kubectl auth can-i list pods --as=system:serviceaccount:<ns>:<sa> -n <ns>
```

## CKAD study path (summary)

| Priority | Module | Topic |
|----------|--------|-------|
| Start | [17-CKADExamEssentials](17-CKADExamEssentials/readme.md) | Exam format, imperative kubectl, timed practice |
| 1 | [01-WorkloadandContainerImageFundamentals](01-WorkloadandContainerImageFundamentals/readme.md) | Workloads, volumes, labels, DaemonSet |
| 2 | [11-ApplicationConfigurationAndSecurityFundamentals](11-ApplicationConfigurationAndSecurityFundamentals/readme.md) | ConfigMap, Secret, securityContext, RBAC |
| 3 | [16-ServicesIngressAndNetworkingFundamentals](16-ServicesIngressAndNetworkingFundamentals/readme.md) | Services, Ingress, NetworkPolicy |
| 4 | [05-ObservabilityLoggingAndProbes](05-ObservabilityLoggingAndProbes/readme.md) | Probes, logs, events |
| 5 | [08-DebuggingAndTroubleshootingApplications](08-DebuggingAndTroubleshootingApplications/readme.md) | CrashLoop, ImagePull, debug |
| 6 | [12-ResourceLimitsSchedulingAndAutoscaling](12-ResourceLimitsSchedulingAndAutoscaling/readme.md) | Resources, affinity, taints, HPA |
| 7 | [02-DeploymentStrategiesAndPackageManagement](02-DeploymentStrategiesAndPackageManagement/readme.md) | Rollback, Helm, Kustomize |
| 8 | [06-StatefulApplicationsAndDataPersistence](06-StatefulApplicationsAndDataPersistence/readme.md) | StatefulSet, PV/PVC, Jobs, CronJobs |
| 9 | [07-APIsCustomResourcesAndOperatorPatterns](07-APIsCustomResourcesAndOperatorPatterns/readme.md) | JSONPath, patch (lessons 01–02) |

Lower CKAD priority: [03](03-GitOpsAndContinuousDeliveryOnKubernetes/readme.md), [04](04-LocalDevelopmentTestingAndContinuousIntegration/readme.md), [09](09-MonitoringAlertingAndPerformanceOptimization/readme.md), [13](13-AdvancedSecurityHardeningAndPodSecurityAdmission/readme.md), [14](14-AdvancedSchedulingAndScalabilityPatterns/readme.md), [15](15-PolicyDrivenGovernanceAndAdmissionControl/readme.md).

## CKAD brief theory you should know

### 1) Core Pod patterns
- Sidecar: helper container that runs with the main app (logging, proxy, metrics).
- Init container: runs before app containers start (setup, wait-for-dependency, migrations).
- Adapter: transforms app output to a standard format (for monitoring/log pipelines).
- Ambassador: local proxy that simplifies access to external services.

### 2) Workload objects and when to use them
- Pod: single runtime unit, rarely used directly in production.
- Deployment: stateless apps with rolling updates and rollbacks.
- StatefulSet: stable identity and storage for stateful apps.
- DaemonSet: one Pod per node (agents, log collectors).
- Job: run-to-completion task.
- CronJob: scheduled Jobs.

### 3) Deployment strategies (exam high-yield)
- Recreate: stop old, then start new (downtime).
- RollingUpdate: default for Deployments, gradual replacement.
- Blue/Green: two environments, switch traffic at cutover.
- Canary: send small percentage of traffic to new version first.

### 4) Probes and lifecycle
- Liveness probe: restart stuck app.
- Readiness probe: control if Pod receives traffic.
- Startup probe: protect slow-start apps from premature restarts.

### 5) Config and secrets
- ConfigMap: non-sensitive configuration.
- Secret: sensitive values (still base64, so use RBAC and encryption at rest where possible).
- Injection options: env vars, envFrom, mounted files.

### 6) Storage essentials
- emptyDir: Pod-lifetime temporary storage.
- PVC/PV: persistent data across Pod restarts.
- StorageClass: dynamic provisioning driver and access modes (RWO/RWX/ROX).
- Static PV: admin-pre-provisioned storage bound manually to a PVC.
- CSI: storage drivers used by Kubernetes to provision/mount volumes.
- Ephemeral volumes: temporary per-Pod storage (emptyDir or ephemeral volume claim templates).

### 7) Networking essentials
- Service types: ClusterIP, NodePort, LoadBalancer.
- Ingress: HTTP/HTTPS routing to Services.
- NetworkPolicy: allow/deny traffic between Pods and namespaces.

### 8) Security essentials
- ServiceAccount for Pod identity.
- RBAC basics: Role/ClusterRole + RoleBinding/ClusterRoleBinding.
- `kubectl auth can-i` to verify permissions.
- securityContext: runAsNonRoot, readOnlyRootFilesystem, capabilities drop.
- Resource requests/limits and LimitRange/ResourceQuota basics.

### 9) Troubleshooting flow (very exam-useful)
1. Check object state: kubectl get pods,deploy,svc
2. Inspect details: kubectl describe <resource>
3. Check logs: kubectl logs <pod> -c <container>
4. Enter container: kubectl exec -it <pod> -- sh
5. Validate events: kubectl get events --sort-by=.lastTimestamp

### 10) CKAD exam focus tips
- Practice fast YAML editing and imperative commands that generate YAML — see [17-02](17-CKADExamEssentials/02-ImperativeKubectlAndManifestGeneration/readme.md).
- Be strong with Deployments, Services, Ingress, ConfigMap/Secret, probes, Jobs/CronJobs.
- Know multi-container Pods (init + sidecar), labels/selectors, and storage mounting patterns.
- Verify everything after apply with get/describe/logs before moving on — see [17-04](17-CKADExamEssentials/04-PostTaskVerificationChecklist/readme.md).
