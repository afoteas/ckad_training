# Tainting Nodes and Applying Tolerations

This lesson demonstrates how to taint a node and control which Pods are allowed to run on it.

For background on taint syntax, effects, toleration matching, and how taints differ from labels and affinity, see [06-TaintsAndTolerationsExplained](../06-TaintsAndTolerationsExplained/readme.md).

## Demo Files

- `untolerating-pod.yaml` — a normal Pod with no tolerations
- `tolerating-pod.yaml` — a Pod with a toleration that matches the node taint

## Taint Used in This Lesson

This exercise applies the following taint:

```text
dedicated=finance:NoSchedule
```

The tolerating Pod includes a matching toleration in `spec.tolerations` with `operator: Equal`.

## Step 1: Taint the Node

List nodes and pick one to taint:

```bash
kubectl get nodes
kubectl taint nodes <node-name> dedicated=finance:NoSchedule
kubectl describe node <node-name>
```

After tainting, `kubectl describe node` should show the taint under **Taints**:

```text
Taints: dedicated=finance:NoSchedule
```

Expected behavior: non-tolerating Pods are blocked from scheduling on this node.

To remove the taint later, append a `-` to the same taint expression:

```bash
kubectl taint nodes <node-name> dedicated=finance:NoSchedule-
```

## Step 2: Deploy Pod Without Toleration

```bash
kubectl apply -f untolerating-pod.yaml
kubectl get pod untolerating-test -o wide
kubectl describe pod untolerating-test
```

`untolerating-test` has no tolerations, so the scheduler cannot place it on the tainted node.

Expected behavior: Pod remains `Pending` if only tainted nodes are available.

Check the Events section from `kubectl describe pod`:

```text
0/1 nodes are available: 1 node(s) had untolerated taint {dedicated: finance}.
```

That message confirms the taint is working and the Pod is being rejected.

## Step 3: Deploy Pod With Matching Toleration

```bash
kubectl apply -f tolerating-pod.yaml
kubectl get pod tolerating-test -o wide
kubectl describe pod tolerating-test
```

`tolerating-test` includes a toleration for `dedicated=finance:NoSchedule`, so it is allowed on the tainted node.

Expected behavior: Pod schedules successfully on the tainted node.

Verify with:

```bash
kubectl get pod tolerating-test -o wide
```

The `NODE` column should show the tainted node name.

## Optional Cleanup

```bash
kubectl delete -f untolerating-pod.yaml
kubectl delete -f tolerating-pod.yaml
kubectl taint nodes <node-name> dedicated=finance:NoSchedule-
```

Removing the taint restores normal scheduling behavior on that node.

## CKAD Tips

- Apply/remove a taint: `kubectl taint nodes <node> dedicated=finance:NoSchedule` and re-run with a trailing `-` to remove.
- Confirm the taint with `kubectl describe node <node>` under the **Taints** section.
- Diagnose a blocked Pod via `kubectl describe pod` — look for `had untolerated taint`.
- A toleration only *permits* scheduling; pair it with `nodeSelector`/affinity to actually target the node.
- `kubectl get pod <pod> -o wide` confirms the tolerating Pod landed on the tainted node.

## Key Takeaway

Taints enforce node-level restrictions. Matching tolerations are required for permitted workloads.
