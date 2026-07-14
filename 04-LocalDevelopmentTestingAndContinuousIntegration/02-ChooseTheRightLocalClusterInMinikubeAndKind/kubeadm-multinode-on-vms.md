# Kubernetes Multi-Node Cluster on Multiple VMs (kubeadm)

This guide sets up one Kubernetes cluster across multiple Linux VMs using kubeadm.

## Target Topology

- 1 control-plane node
- N worker nodes
- Flat network connectivity between all nodes

Example inventory:

- cp1: 192.168.56.10
- wk1: 192.168.56.11
- wk2: 192.168.56.12

## 0) Prerequisites

- OS: Ubuntu 22.04 or 24.04 on all VMs
- CPU/RAM:
  - control-plane: 2 vCPU, 4 GB RAM minimum
  - worker: 2 vCPU, 2 GB RAM minimum
- Unique hostname per VM
- Static IP or DHCP reservation for each VM
- Time sync enabled (chrony or systemd-timesyncd)
- Full node-to-node network reachability

Open required ports (at minimum):

- Control-plane:
  - 6443/TCP (Kubernetes API)
  - 2379-2380/TCP (etcd)
  - 10250/TCP (kubelet)
  - 10257/TCP (kube-controller-manager)
  - 10259/TCP (kube-scheduler)
- Workers:
  - 10250/TCP (kubelet)
  - 30000-32767/TCP (NodePort range if used)

## 1) Prepare All Nodes (run on every VM)

### 1.1 Hostname and hosts file

Set hostname on each VM:

```bash
sudo hostnamectl set-hostname <node-name>
```

Update /etc/hosts on all nodes:

```bash
cat <<'EOF' | sudo tee -a /etc/hosts
192.168.56.10 cp1
192.168.56.11 wk1
192.168.56.12 wk2
EOF
```

### 1.2 Disable swap

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

### 1.3 Kernel modules and sysctl

```bash
cat <<'EOF' | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<'EOF' | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### 1.4 Install containerd

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y containerd.io
```

Configure containerd with systemd cgroups:

```bash
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl enable containerd
sudo systemctl restart containerd
sudo systemctl status containerd --no-pager
```

### 1.5 Install kubeadm, kubelet, kubectl

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable kubelet
```

## 2) Initialize Control Plane (run only on cp1)

Pick a pod CIDR compatible with your CNI. This guide uses Calico.

```bash
sudo kubeadm init \
  --apiserver-advertise-address=192.168.56.10 \
  --pod-network-cidr=192.168.0.0/16
```

Configure kubectl for your user:

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Verify control-plane node appears:

```bash
kubectl get nodes
```

## 3) Install CNI Plugin (Calico, on cp1)

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml
```

Wait for system pods:

```bash
kubectl get pods -A
```

## 4) Join Worker Nodes

On cp1, print join command:

```bash
kubeadm token create --print-join-command
```

Run the printed command on each worker (wk1, wk2, ...), for example:

```bash
sudo kubeadm join 192.168.56.10:6443 --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

Back on cp1, verify:

```bash
kubectl get nodes -o wide
```

All nodes should become Ready after CNI is healthy.

## 5) Optional: Allow Scheduling on Control Plane (Lab Only)

For small labs, if you want workloads on cp1 too:

```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```

Do not do this in production.

## 6) Verify Cluster Health

```bash
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
kubectl -n kube-system get pods
```

Quick workload test:

```bash
kubectl create deployment nginx --image=nginx:stable
kubectl expose deployment nginx --port=80 --type=NodePort
kubectl get svc nginx
```

## 7) Add More Workers Later

On cp1:

```bash
kubeadm token create --print-join-command
```

Run the generated join command on each new VM.

## 8) Reset a Node (if join/init failed)

Run on the node you want to clean:

```bash
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d $HOME/.kube
sudo systemctl restart containerd kubelet
```

If resetting a worker that already exists in cluster, also delete its node object from cp1:

```bash
kubectl delete node <node-name>
```

## 9) Common Troubleshooting

- Node is NotReady:
  - Check CNI pods: kubectl -n kube-system get pods
  - Check kubelet logs: sudo journalctl -u kubelet -f
- Join token expired:
  - Regenerate on cp1: kubeadm token create --print-join-command
- cgroup mismatch errors:
  - Confirm containerd uses SystemdCgroup = true
- API server unreachable from workers:
  - Verify firewall rules and routing to cp1:6443

## 10) What to Learn Next

- High availability control plane (3 control-plane nodes + load balancer)
- Ingress controller installation (ingress-nginx)
- Storage classes and CSI drivers
- Monitoring stack (metrics-server, Prometheus, Grafana)
- Upgrade flow with kubeadm
