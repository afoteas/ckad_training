# Implementing HPA in a Live App

This lesson demonstrates end-to-end HPA behavior: deploy app, apply HPA policy, generate load, and observe automatic scale-out.

## Prerequisite

Metrics Server must be installed and healthy.

## Demo Files

- `hpa-app.yaml`
- `hpa-config.yaml`

## Step 1: Deploy Target Workload

```bash
kubectl apply -f hpa-app.yaml
kubectl get deployment php-apache
kubectl get svc php-apache
```

## Step 2: Apply HPA Policy

Typical policy values:

- target average CPU utilization: `50%`
- `minReplicas: 1`
- `maxReplicas: 10`

```bash
kubectl apply -f hpa-config.yaml
kubectl get hpa
kubectl get hpa -w
```

## Step 3: Generate Load

Run this in a second terminal:

```bash
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
```

## Step 4: Observe Scale-Out

Watch `TARGETS` and `REPLICAS` in `kubectl get hpa -w`.

Expected behavior:

- CPU utilization rises above target.
- HPA increases replica count.

## Optional Cleanup

```bash
kubectl delete -f hpa-config.yaml
kubectl delete -f hpa-app.yaml
```

## CKAD Tips

- Create an HPA imperatively: `kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10`.
- Metrics Server is required — verify with `kubectl top pods` before expecting any scaling.
- Watch scaling live with `kubectl get hpa -w`; `<unknown>` under `TARGETS` means missing metrics or missing requests.
- The target Deployment **must** define CPU requests, or utilization-based HPA won't scale.
- Remove the `--rm` load-generator Pod when done so replicas scale back down.

## Key Takeaway

HPA uses real-time metrics and request-based baselines to scale workloads automatically as demand changes.
