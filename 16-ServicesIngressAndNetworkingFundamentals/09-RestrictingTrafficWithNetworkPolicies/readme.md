# Restricting Traffic with Network Policies

This lesson deploys a backend and a frontend, then uses a **NetworkPolicy** to ensure the backend only accepts traffic from the frontend Pods — a Pod-level firewall enforcing least privilege.

For the concepts, see [08-NetworkPoliciesOverview](../08-NetworkPoliciesOverview/readme.md).

## Prerequisite: CNI with NetworkPolicy support

NetworkPolicies are only **enforced** if the cluster CNI supports them. The API accepts policies on any cluster, but without a capable CNI they are **silently ignored** — Step 4's "blocked" test will still succeed.

### Check which CNI is installed

```bash
# CNI pods (most common check)
kubectl get pods -n kube-system | grep -iE 'calico|cilium|flannel|weave|kindnet|antrea|canal'

# CNI DaemonSet on every node
kubectl get ds -n kube-system
```

| What you see | CNI | Enforces NetworkPolicy? |
|---|---|---|
| `kindnet-xxxxx` | kind default (**kindnet**) | **No** |
| `calico-node-xxxxx` | Calico | **Yes** |
| `cilium-xxxxx` | Cilium | **Yes** |
| `weave-net-xxxxx` | Weave Net | **Yes** |
| `kube-flannel-ds-xxxxx` | Flannel (default) | **No** (needs Canal/Calico overlay) |

On your **kind** cluster you will typically see `kindnet` — policies apply cleanly but traffic is **not** filtered.

Optional node-level check (SSH / `docker exec` into a node):

```bash
ls /etc/cni/net.d/
```

### Install a NetworkPolicy-capable CNI (if missing)

**kind** — apply Calico on the running cluster (official manifest; wait for nodes to be Ready):

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=120s
kubectl get pods -n kube-system | grep -iE 'calico|kindnet'
```

You may see both `kindnet` and `calico-node` briefly; Calico takes over policy enforcement. Re-run Step 4 after Calico is Ready — the unauthorized `curl` should time out or be refused.

**minikube** — enable at cluster start (or use an addon):

```bash
minikube start --cni=calico
# or: minikube start --cni=cilium
```

**CKAD exam** — the exam cluster already has a supporting CNI; you only need to write correct NetworkPolicy YAML.

## Demo Files

| File | Purpose |
|------|---------|
| `backend-and-frontend.yaml` | `backend-app`, `frontend-app` (labeled `role: web-server`), and `backend-service` |
| `backend-policy.yaml` | Allows ingress to the backend only from `role: web-server` Pods |

## Step 1: Deploy the Apps

```bash
kubectl apply -f backend-and-frontend.yaml
kubectl get pods
```

Both backend and frontend Pods should be `Running`.

## Step 2: Prove Open Access (default behavior)

By default any Pod can reach the backend. Test from an unrelated Pod:

```bash
kubectl run unauthorized-test -it --rm --image=curlimages/curl -- /bin/sh
# inside the Pod:
curl http://backend-service
```

You get the nginx welcome page — no restrictions yet. Then `exit`.

## Step 3: Apply the NetworkPolicy

```bash
kubectl apply -f backend-policy.yaml
```

The policy:
- **targets** Pods with `app: backend` (`podSelector`),
- **direction** `Ingress` (traffic into the backend),
- **allows** only Pods labeled `role: web-server`.

The frontend Deployment carries `role: web-server`, so it is permitted; anything else is denied.

## Step 4: Test the Rules

**Allowed (frontend has `role: web-server`):**

```bash
kubectl get pods                       # find the frontend Pod name
kubectl exec <frontend-pod> -- curl -s http://backend-service
```

**Blocked (unauthorized Pod lacks the label):**

```bash
kubectl run unauthorized-test -it --rm --image=curlimages/curl -- /bin/sh
curl http://backend-service            # should time out / be refused
```

If the unauthorized request **still succeeds**, see **Prerequisite: CNI with NetworkPolicy support** above — your CNI is likely not enforcing (e.g. kindnet on kind).

## Cleanup

```bash
kubectl delete -f backend-policy.yaml -f backend-and-frontend.yaml
```

## CKAD Tips

- Match the policy's `podSelector` to the **target** Pod's labels, and the `from` selector to the **source** Pod's labels.
- Applying an Ingress policy flips the target to default-deny for ingress — only listed sources get through.
- If a policy "doesn't work" locally, run the CNI check above — kindnet on kind does not enforce; install Calico first.

## Key Takeaway

A NetworkPolicy targets Pods by label and whitelists allowed sources — turning an open backend into one reachable only by authorized frontends. Enforcement depends on a NetworkPolicy-capable CNI plugin.
