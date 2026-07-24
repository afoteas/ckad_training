# Implementing a Live Config Reload Pattern

Kubernetes updates ConfigMaps and Secrets, but applications usually do not restart themselves automatically when those values change. A live reload pattern solves that operational gap.

## The Problem

When a Pod consumes configuration from a ConfigMap or Secret:

- Kubernetes can update the mounted content
- or new values can exist in the cluster
- but the application process may keep running with old settings

That means the configuration change does not actually take effect until the Pod is restarted.

## The Pattern

A common solution is to use a reloader-style operator. This controller watches for changes to ConfigMaps and Secrets and triggers a rolling restart of the workloads that depend on them.

This avoids writing custom reload logic into every application.

## How It Works

A typical pattern looks like this:

1. a Deployment consumes a ConfigMap or Secret
2. the Deployment includes an annotation that tells the reloader to watch it
3. the ConfigMap or Secret changes
4. the reloader detects the change
5. the reloader triggers a rollout or pod restart
6. the new Pod starts with the updated configuration

## Demo Concept

A simple demonstration can use:

- an initial ConfigMap with `app.version: 1.0.0`
- an updated ConfigMap with `app.version: 2.0.0`
- a Deployment that prints the current version on startup

Without an automated reloader:

- the ConfigMap updates
- the Pod keeps running unchanged
- the old value remains active until the Pod is restarted manually

With a reloader:

- the Deployment is restarted automatically
- the new Pod starts with the updated configuration value

Files in this lesson:

- `initial-configmap.yaml`
- `updated-configmap.yaml`
- `reloader-app-deployment.yaml`

Install Reloader in the cluster (one-time setup):

```bash
helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update
kubectl create namespace reloader --dry-run=client -o yaml | kubectl apply -f -
helm install reloader stakater/reloader -n reloader
kubectl get pods -n reloader
```

Once Reloader is running, it watches workloads that include the annotation `reloader.stakater.com/auto: "true"`.

Apply the initial configuration and the Deployment:

```bash
kubectl apply -f initial-configmap.yaml
kubectl apply -f reloader-app-deployment.yaml
kubectl get pods -l app=reloader-demo
```

Inspect the running version:

```bash
POD=$(kubectl get pods -l app=reloader-demo -o jsonpath='{.items[0].metadata.name}')
kubectl logs "$POD"
```

Update the ConfigMap:

```bash
kubectl apply -f updated-configmap.yaml
```

If the reloader operator is installed, it should restart the Deployment automatically because `reloader-app-deployment.yaml` includes the annotation `reloader.stakater.com/auto: "true"`.

If the operator is not installed, you can demonstrate the effect manually by deleting the Pod and letting the Deployment recreate it:

```bash
kubectl delete pod "$POD"
kubectl get pods -l app=reloader-demo
```

## Important Detail

Even if two manifest files are different on disk, they must refer to the same ConfigMap object name if the goal is to update an existing cluster object rather than create a separate one.

## Best Practices

- Use live reload for frequently changing non-image configuration.
- Prefer an operator or controller instead of custom restart scripts.
- Keep ConfigMaps and Secrets under version control.
- Use clear annotations to declare reloader behavior.
- Validate restarts in lower environments before production rollout.

## CKAD Note

- Third-party reloader operators (e.g. Stakater Reloader) and Helm-based installs are **real-world tooling, not CKAD exam material**.
- What IS in scope: knowing that mounted ConfigMap/Secret volumes refresh automatically (~60s) while env-var values do not, so a change usually requires a restart to take effect.
- The CKAD-friendly way to force a refresh is `kubectl rollout restart deployment/<name>` — remember this instead of the operator annotation.
- Understand the reload concept, but you won't install Helm charts or operators during the exam.

## Key Takeaway

Live config reload bridges the gap between configuration updates and application process refresh. It ensures that changes to ConfigMaps and Secrets are actually reflected in running workloads without requiring manual Pod deletion each time.
