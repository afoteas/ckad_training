# Restricting Traffic with Network Policies

This lesson deploys a backend and a frontend, then uses a **NetworkPolicy** to ensure the backend only accepts traffic from the frontend Pods — a Pod-level firewall enforcing least privilege.

For the concepts, see [08-NetworkPoliciesOverview](../08-NetworkPoliciesOverview/readme.md).

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

## Important: CNI Requirement

NetworkPolicies are enforced by the **CNI plugin**. On local setups like Docker Desktop there is often **no NetworkPolicy-capable CNI**, so the policy is silently ignored and the "blocked" test still succeeds.

You need a CNI such as **Calico, Cilium, or Weave Net** for enforcement. With one installed, the unauthorized request would time out or be refused immediately.

## Cleanup

```bash
kubectl delete -f backend-policy.yaml -f backend-and-frontend.yaml
```

## CKAD Tips

- Match the policy's `podSelector` to the **target** Pod's labels, and the `from` selector to the **source** Pod's labels.
- Applying an Ingress policy flips the target to default-deny for ingress — only listed sources get through.
- If a policy "doesn't work" locally, suspect a missing CNI before the YAML.

## Key Takeaway

A NetworkPolicy targets Pods by label and whitelists allowed sources — turning an open backend into one reachable only by authorized frontends. Enforcement depends on a NetworkPolicy-capable CNI plugin.
