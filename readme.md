# K8s training

## Best compact overview command
```
kubectl get all -A -o wide --show-kind
```
Why this one:

`-A:` all namespaces
`all:` most common workload + service objects
`-o wide:` extra useful columns (node/IP/image details where relevant)
`--show-kind:` clearly labels resource type in one table-style output

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
- CSI: storage drivers used by Kubernetes to provision/mount volumes.
- Ephemeral volumes: temporary per-Pod storage (emptyDir or ephemeral volume claim templates).

### 7) Networking essentials
- Service types: ClusterIP, NodePort, LoadBalancer.
- Ingress: HTTP/HTTPS routing to Services.
- NetworkPolicy: allow/deny traffic between Pods and namespaces.

### 8) Security essentials
- ServiceAccount for Pod identity.
- RBAC basics: Role/ClusterRole + RoleBinding/ClusterRoleBinding.
- securityContext: runAsNonRoot, readOnlyRootFilesystem, capabilities drop.
- Resource requests/limits and LimitRange/ResourceQuota basics.

### 9) Troubleshooting flow (very exam-useful)
1. Check object state: kubectl get pods,deploy,svc
2. Inspect details: kubectl describe <resource>
3. Check logs: kubectl logs <pod> -c <container>
4. Enter container: kubectl exec -it <pod> -- sh
5. Validate events: kubectl get events --sort-by=.lastTimestamp

### 10) CKAD exam focus tips
- Practice fast YAML editing and imperative commands that generate YAML.
- Be strong with Deployments, Services, Ingress, ConfigMap/Secret, probes, Jobs/CronJobs.
- Know multi-container Pods (init + sidecar) and storage mounting patterns.
- Verify everything after apply with get/describe/logs before moving on.