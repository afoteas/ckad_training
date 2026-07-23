# Bare-Metal Ingress on Your Own Domain

> **Real-world chapter (beyond CKAD scope).** The exam and lessons 05–07 assume a cloud cluster where `type: LoadBalancer` auto-provisions a public IP for the ingress controller. This chapter covers the **bare-metal** case: your own servers, one public IP, and a domain via Cloudflare — where you wire external access yourself.
>
> Builds directly on [06-DeployingNGINXIngressAndBasicRouting](../06-DeployingNGINXIngressAndBasicRouting/readme.md). To make `type: LoadBalancer` itself work on bare metal, see [12-MetalLBForBareMetalLoadBalancer](../12-MetalLBForBareMetalLoadBalancer/readme.md).

## Scenario

- 3 bare-metal nodes. One is the **control plane** and holds the only **public IP**; the other two are private/internal only.
- A domain `mydomain.com` managed in **Cloudflare**, pointing at the public IP.
- Goal: expose an in-cluster Service `myservice` at **`myservice.mydomain.com`**.

## Demo Files

| File | Purpose |
|------|---------|
| `myservice-deployment.yaml` | Sample `myapp` Deployment (2 replicas) behind the Service |
| `myservice-clusterip.yaml` | `myservice` ClusterIP Service (the Ingress backend) |
| `myservice-ingress.yaml` | Ingress routing `myservice.mydomain.com` → `myservice:80` |
| `controller-hostnetwork-patch.yaml` | Patch to bind the controller to the public node's 80/443 (Option A) |
| `controller-externalips-service.yaml` | Alternative: expose the controller via `externalIPs` (Option B) |

## The Chain

```text
browser → myservice.mydomain.com (Cloudflare DNS → public IP)
        → public node :80/:443
        → NGINX ingress controller
        → host rule: myservice.mydomain.com → myservice (ClusterIP)
        → Pods
```

Three problems to solve: **(1) DNS**, **(2) getting WAN traffic into the cluster on 80/443**, **(3) routing by hostname**. On the cloud, `type: LoadBalancer` solves #2 for you. On bare metal `LoadBalancer` sits `<pending>`, so you wire #2 yourself.

## Prerequisite: Install the NGINX Ingress Controller

Same as lesson 06 — install once:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
kubectl get pods -n ingress-nginx -w
```

## Step 1 — DNS (Cloudflare)

Create an **A record** pointing at the public IP:

```text
myservice.mydomain.com  →  A  →  <public-ip>
```

Or a wildcard so new services need no DNS change:

```text
*.mydomain.com  →  A  →  <public-ip>
```

Cloudflare's orange-cloud (proxy) only proxies HTTP/HTTPS and terminates TLS at the edge — fine here. If it interferes while testing your own TLS, switch the record to **grey cloud (DNS-only)** first, then re-enable the proxy.

## Step 2 — Get external traffic into the cluster (the bare-metal part)

The ingress controller must listen on the **public node's** 80/443. Two clean options.

### Option A — `hostNetwork`, pinned to the public node (recommended)

You do **not** write a new manifest here. You **modify the ingress-nginx controller Deployment the prerequisite step already installed** (named `ingress-nginx-controller` in the `ingress-nginx` namespace). The goal is: bind to the host's 80/443 (`hostNetwork` + `hostPort`) and schedule the Pod on the public node (`nodeSelector`).

Apply the provided patch:

```bash
kubectl patch deployment ingress-nginx-controller -n ingress-nginx \
  --type merge --patch-file controller-hostnetwork-patch.yaml
```

The patch (`controller-hostnetwork-patch.yaml`) sets `hostNetwork: true`, `dnsPolicy: ClusterFirstWithHostNet`, and a control-plane `nodeSelector`. Equivalent Helm install:

```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.hostNetwork=true \
  --set controller.dnsPolicy=ClusterFirstWithHostNet \
  --set controller.kind=DaemonSet \
  --set controller.nodeSelector."node-role\.kubernetes\.io/control-plane"=""
```

> If the control-plane node carries a `NoSchedule` taint and the controller Pod stays `Pending`, add a matching toleration (commented in the patch file).

Verify:

```bash
kubectl get pods -n ingress-nginx -o wide      # NODE column = your public node
curl http://<public-ip>:80                      # reaches the controller directly — no NodePort, no LB
```

### Option B — `externalIPs` on the controller Service

Keep the controller normal, but accept traffic for the public IP on 80/443:

```bash
kubectl apply -f controller-externalips-service.yaml   # edit <public-ip> first
```

kube-proxy forwards traffic arriving at that IP on 80/443 to the controller Pods.

> **MetalLB** is the "proper" way to make `type: LoadBalancer` work on bare metal, but it shines with a **pool of LAN IPs** to hand out. With a single WAN IP already bound to one node, Option A (`hostNetwork`) is simpler — see [12-MetalLBForBareMetalLoadBalancer](../12-MetalLBForBareMetalLoadBalancer/readme.md) for the full alternative.

## Step 3 — Deploy the app, Service, and Ingress

```bash
kubectl apply -f myservice-deployment.yaml
kubectl apply -f myservice-clusterip.yaml
kubectl apply -f myservice-ingress.yaml
kubectl get ingress myservice-ingress
```

`myservice` stays a normal **ClusterIP** Service; the Ingress `host` rule routes `myservice.mydomain.com` to it. This part is identical to the cloud lessons — only Step 2 was extra.

## Step 4 — TLS

Two easy choices:

1. **Cloudflare terminates TLS** (orange cloud). Browser→Cloudflare is HTTPS; Cloudflare→origin can be HTTP or HTTPS. Use SSL mode **Full** with a cert on the origin, or **Flexible** for an HTTP origin (less secure).
2. **Terminate at the cluster** with cert-manager + Let's Encrypt (HTTP-01 works since you're reachable on :80), adding a `tls:` block to the Ingress — see [07-AdvancedIngressTLSHostAndPathRules](../07-AdvancedIngressTLSHostAndPathRules/readme.md).

## Cleanup

```bash
kubectl delete -f myservice-ingress.yaml -f myservice-clusterip.yaml -f myservice-deployment.yaml
```

## Summary

| # | Task | What to do |
|---|------|------------|
| 1 | DNS | Cloudflare A record `myservice.mydomain.com` (or `*.mydomain.com`) → public IP |
| 2 | Ingress into cluster | NGINX controller with `hostNetwork` pinned to the public node (or `externalIPs`) |
| 3 | Routing | ClusterIP `myservice` + Ingress `host: myservice.mydomain.com` |
| 4 | TLS | Cloudflare-terminated, or cert-manager + Let's Encrypt at the Ingress |

## Key Takeaway

On the cloud, `type: LoadBalancer` auto-wires external access. On bare metal you do it yourself with `hostNetwork`/`externalIPs`/MetalLB — but DNS, the ClusterIP+Ingress routing, and TLS are identical to the cloud lessons.
