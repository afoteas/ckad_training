# EmptyDir And CSI Ephemeral Notes

This folder contains examples related to ephemeral storage.

## Files
- `emptydir-pod.yaml`: Uses `emptyDir` (built-in, pod-lifetime local storage).
- `csi-ephemeral-pod.yaml`: Uses an inline ephemeral volume (`ephemeral.volumeClaimTemplate`) so it works on this cluster.

## 1) EmptyDir example

Apply and verify:

```bash
kubectl apply -f emptydir-pod.yaml
kubectl get pod emptydir-demo
kubectl exec -it emptydir-demo -- cat /cache/msg.txt
```

Cleanup:

```bash
kubectl delete -f emptydir-pod.yaml
```

## 2) CSI-related ephemeral example

Apply and verify:

```bash
kubectl apply -f csi-ephemeral-pod.yaml
kubectl wait --for=condition=Ready pod/csi-ephemeral-demo --timeout=90s
kubectl get pod csi-ephemeral-demo
kubectl logs csi-ephemeral-demo --tail=5
kubectl get pvc | grep csi-ephemeral-demo
```

Cleanup:

```bash
kubectl delete -f csi-ephemeral-pod.yaml
```

## Why the initial CSI manifest did not work

The first version used inline CSI like this:

```yaml
csi:
	driver: example.csi.k8s.io
```

That driver name is a placeholder, and your cluster had no registered CSI driver for it.
Result: the pod stayed in `ContainerCreating` with `FailedMount`.

How to prove it:

```bash
kubectl describe pod csi-ephemeral-demo
kubectl get csidrivers
```

Expected failure message from events:

```text
driver name example.csi.k8s.io not found in the list of registered CSI drivers
```
