# MetalLB: `type: LoadBalancer` on Bare Metal

> **Real-world chapter (beyond CKAD scope).** On the cloud, [03-LoadBalancerServicesAndExternalTrafficPolicy](../03-LoadBalancerServicesAndExternalTrafficPolicy/readme.md) shows a `type: LoadBalancer` Service getting an auto-provisioned public IP. On bare metal there is no cloud controller, so those Services sit `<pending>`. **MetalLB** fills that gap. Pairs with [11-BareMetalIngressOnYourOwnDomain](../11-BareMetalIngressOnYourOwnDomain/readme.md).

## What MetalLB Does

MetalLB watches for `LoadBalancer` Services, assigns each an IP from a pool you define, then announces that IP on your network so traffic reaches the node. Two announcement modes:

| Mode | How it advertises | When to use |
|------|-------------------|-------------|
| **L2 (ARP/NDP)** | One elected node answers ARP for the IP; traffic enters via that node, then kube-proxy spreads it | Simplest; works on any LAN. Good default. |
| **BGP** | Peers with your router; true multi-node load balancing | Needs a BGP-capable router; larger setups. |

This chapter uses **L2 mode** (the common bare-metal choice).

## Demo Files

| File | Purpose |
|------|---------|
| `ipaddresspool.yaml` | `IPAddressPool` — the range of IPs MetalLB may assign |
| `l2advertisement.yaml` | `L2Advertisement` — announce the pool over ARP |
| `loadbalancer-service.yaml` | A sample `type: LoadBalancer` Service that gets a pool IP |

## Caveat for a Single Public WAN IP

MetalLB hands out IPs from a **pool it fully controls**, announced on the **local network (LAN)**. It fits best when you have a **range of spare LAN IPs** (e.g. `192.168.1.240-192.168.1.250`).

If your only public IP is a **WAN IP already bound to the control-plane node's NIC**, MetalLB is awkward — you don't want it ARP-fighting over an address the OS already owns. In that case prefer `hostNetwork`/`externalIPs` from [11-BareMetalIngressOnYourOwnDomain](../11-BareMetalIngressOnYourOwnDomain/readme.md). Use MetalLB when:

- you have a block of **LAN** IPs to dedicate to services, and/or
- you route/NAT a public IP **to** a MetalLB LAN IP at your router/firewall.

## Step 1 — Install MetalLB

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml
kubectl get pods -n metallb-system -w
```

This creates the `metallb-system` namespace with a `controller` Deployment (assigns IPs) and a `speaker` DaemonSet (announces them). Wait until both are `Running`.

## Step 2 — Define an IP Address Pool

Use IPs that are **free on your LAN** and outside your DHCP range, then apply:

```bash
kubectl apply -f ipaddresspool.yaml
```

## Step 3 — Advertise the Pool (L2)

```bash
kubectl apply -f l2advertisement.yaml
```

MetalLB is now ready to assign IPs from `first-pool` to any `LoadBalancer` Service.

## Step 4 — Use It: a `LoadBalancer` Service Gets a Real IP

```bash
kubectl apply -f loadbalancer-service.yaml
kubectl get svc web-app
# NAME      TYPE           EXTERNAL-IP      PORT(S)
# web-app   LoadBalancer   192.168.1.240    80:31234/TCP
```

`EXTERNAL-IP` is no longer `<pending>` — MetalLB assigned an address from the pool. The **ingress-nginx controller** Service (installed as `type: LoadBalancer`) picks up a pool IP the same way, giving you a single entry point for host/path routing.

## How It Fits the Domain Setup

Combine with the DNS + Ingress steps from [11-BareMetalIngressOnYourOwnDomain](../11-BareMetalIngressOnYourOwnDomain/readme.md):

```text
browser → myservice.mydomain.com
        → (Cloudflare DNS → your public IP)
        → router/firewall NAT: public IP :80/:443 → MetalLB IP 192.168.1.240
        → ingress-nginx controller (LoadBalancer via MetalLB)
        → host rule → myservice (ClusterIP) → Pods
```

- **DNS:** Cloudflare A record `myservice.mydomain.com` → your public IP (unchanged).
- **Edge:** forward the public IP's 80/443 to the MetalLB `EXTERNAL-IP` at your router/firewall.
- **Routing + TLS:** identical to the main lessons — a ClusterIP `myservice` plus an Ingress `host` rule, TLS via Cloudflare or cert-manager.

## Request an Explicit IP (optional)

Pin a specific pool address to a Service with an annotation (see the commented block in `loadbalancer-service.yaml`):

```yaml
metadata:
  annotations:
    metallb.io/loadBalancerIPs: 192.168.1.245
```

(The older `spec.loadBalancerIP` field is deprecated — use the annotation.)

## Troubleshooting

- **Still `<pending>`** — no `IPAddressPool`/`L2Advertisement`, or the pool is exhausted. Check `kubectl logs -n metallb-system deploy/controller`.
- **IP assigned but unreachable** — the address isn't actually free/on-subnet, or a firewall blocks ARP. Confirm nothing else answers that IP (`arping`) and it's outside DHCP.
- **`speaker` not on the node** — L2 needs a `speaker` Pod on the node that should announce; check the DaemonSet.

## Summary

| Step | Object | Purpose |
|------|--------|---------|
| 1 | MetalLB manifest | Installs `controller` + `speaker` |
| 2 | `IPAddressPool` | The IPs MetalLB may hand out |
| 3 | `L2Advertisement` | Announce the pool over ARP |
| 4 | `type: LoadBalancer` Service | Gets a real IP from the pool |

## Key Takeaway

MetalLB makes `type: LoadBalancer` behave on bare metal exactly like it does in the cloud — you define a pool of network IPs, MetalLB assigns and advertises them. Best when you have a **block of LAN IPs**; for a single WAN IP already on one node, `hostNetwork`/`externalIPs` is simpler.
