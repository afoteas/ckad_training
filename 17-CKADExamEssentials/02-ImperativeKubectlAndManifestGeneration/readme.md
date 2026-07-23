# Imperative kubectl and Manifest Generation

The fastest CKAD workflow: **generate YAML with kubectl**, save to a file, edit the few fields the task requires, apply.

## The Core Pattern

```bash
kubectl create <resource> <name> <flags> --dry-run=client -o yaml > task.yaml
# edit task.yaml
kubectl apply -f task.yaml
```

`--dry-run=client` prints YAML without sending to the API server. `-o yaml` outputs full manifest structure.

## High-Yield Generators

### Deployment

```bash
kubectl create deployment web --image=nginx --replicas=3 \
  --dry-run=client -o yaml > deploy.yaml
```

### Service (expose)

```bash
kubectl expose deployment web --port=80 --target-port=8080 --type=ClusterIP \
  --dry-run=client -o yaml > svc.yaml

kubectl expose deployment web --port=80 --type=NodePort \
  --dry-run=client -o yaml > nodeport.yaml
```

### Pod

```bash
kubectl run debug --image=busybox --restart=Never --dry-run=client -o yaml --command -- sleep 3600 > pod.yaml
```

**Important:** put `--dry-run=client -o yaml` **before** `--`. Anything after `--` is the container command, not kubectl flags — if dry-run comes after `--`, kubectl creates a real Pod instead of printing YAML.

- `--restart=Never` → generates a **Pod** (what you usually want for debug pods).
- Omit `--restart=Never` → modern kubectl creates a **Deployment** (not a standalone Pod).

### ConfigMap and Secret

```bash
kubectl create configmap app-config --from-literal=log=info \
  --dry-run=client -o yaml > cm.yaml

kubectl create secret generic db-creds --from-literal=password=s3cr3t \
  --dry-run=client -o yaml > secret.yaml
```

### Job and CronJob

```bash
kubectl create job batch --image=busybox -- date \
  --dry-run=client -o yaml > job.yaml

kubectl create cronjob backup --image=busybox --schedule="0 2 * * *" -- date \
  --dry-run=client -o yaml > cronjob.yaml
```

### ServiceAccount + Role + RoleBinding

```bash
kubectl create serviceaccount app-sa --dry-run=client -o yaml > sa.yaml

kubectl create role pod-reader --verb=get,list,watch --resource=pods \
  --dry-run=client -o yaml > role.yaml

kubectl create rolebinding read-pods --role=pod-reader --serviceaccount=default:app-sa \
  --dry-run=client -o yaml > binding.yaml
```

## Live Changes (No YAML File)

```bash
kubectl scale deployment web --replicas=5
kubectl set image deployment/web nginx=nginx:1.25
kubectl rollout undo deployment/web
kubectl label pod <name> env=prod
kubectl taint nodes <node> dedicated=gpu:NoSchedule
kubectl patch deployment web -p '{"spec":{"replicas":3}}'
```

## kubectl explain

```bash
kubectl explain pod.spec.containers.resources
kubectl explain deployment.spec.strategy
kubectl explain ingress.spec.rules
```

Add `--recursive` for nested fields.

## CKAD Tips

- Always add `--namespace=<ns>` if the task specifies a namespace.
- `kubectl create` vs `kubectl apply`: exam tasks usually want `apply -f`.
- For probes, resources, volumeMounts — generate base Deployment, then add fields manually or copy from docs.
- `kubectl run` with `--restart=Never` creates a Pod; default creates a Deployment.

## Key Takeaway

Never write a full manifest from scratch if a generator gets you 80% there in one command. Generate → edit → apply → verify.
