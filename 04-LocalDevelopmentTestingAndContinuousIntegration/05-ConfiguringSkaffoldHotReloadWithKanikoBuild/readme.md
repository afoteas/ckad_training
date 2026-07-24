# Configuring Skaffold Hot-Reload with Kaniko Build

This guide demonstrates continuous Kubernetes development with Skaffold and Kaniko, where image builds run inside the cluster and redeploy automatically after code changes.

## Why This Approach

Traditional iteration is slow:

- edit code
- rebuild image manually
- push/load image
- redeploy with kubectl
- re-check logs and endpoints

Skaffold + Kaniko reduces this to a single loop driven by `skaffold dev`.

## What Each Tool Does

### Skaffold

Skaffold watches source changes and automates:

- image build
- image deploy
- log streaming
- optional port-forwarding

### Kaniko

Kaniko builds container images from Dockerfiles inside containers/pods, without Docker daemon access.

Benefits:

- no local Docker daemon dependency for build execution
- works well in Kubernetes-native and CI/CD environments
- safer build model for restricted clusters

## Kaniko vs Docker Build (Important Difference)

### Docker build path

- `docker build` runs on a machine that has Docker daemon
- build execution depends on that daemon and its socket access
- common for local laptop workflows

### Kaniko build path

- Kaniko runs as a container (often in a Kubernetes pod)
- no Docker daemon is required inside that build environment
- ideal when you want in-cluster or CI-native builds

In short: Docker build is daemon-based, Kaniko build is daemonless.

## Where the Build Runs in This Demo

Yes, in this lesson 05 flow, Skaffold with Kaniko triggers in-cluster builds.

When you run `skaffold dev` with `kaniko` configured:

1. Skaffold detects a source change.
2. It sends build context to the cluster build flow.
3. A Kaniko build workload runs in Kubernetes (pod/job) to execute the Dockerfile steps.
4. The built image is then used for redeploy.

That means the image build itself happens inside the cluster build environment, not via your local Docker daemon.

You can observe this during builds by watching pods:

```bash
kubectl get pods -A -w
```

And by checking Skaffold output for Kaniko build activity:

```bash
skaffold dev
```

## Build Strategy Options in Skaffold

- local Docker build
- cluster build (Kaniko)
- cloud build services (for example, managed cloud build backends)

This lesson uses one Skaffold configuration for both kind and minikube with insecure Kaniko flags enabled for constrained local environments.

## Prerequisites

- kind cluster capability
- kubectl configured
- skaffold installed
- project with application code, `Dockerfile`, Kubernetes manifests, and `skaffold.yaml`

Install examples:

```bash
# macOS (as in the demo)
brew install skaffold

# Linux
curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
chmod +x skaffold
sudo mv skaffold /usr/local/bin/
```

Verify:

```bash
skaffold version
```

## 1) Create a kind Cluster for the Demo

```bash
kind create cluster --name skaffold-demo
kubectl config use-context kind-skaffold-demo
kubectl get nodes
```

If you are using minikube (current setup), use this instead:

```bash
kubectl config use-context mini-ckad
minikube status -p mini-ckad
```

## 2) Example Project Layout

The full runnable example is provided in this folder:

- `main.go`
- `go.mod`
- `Dockerfile`
- `k8s/deployment.yaml`
- `skaffold.yaml`

Quick verify:

```bash
ls -la
ls -la k8s
```

## 3) Example Skaffold Configuration (Kaniko + kubectl + portForward)

Use the provided file:

- `skaffold.yaml`

If needed, inspect it directly:

```bash
cat skaffold.yaml
```

What to notice:

- the default build uses the local Docker daemon with `push: false` (best for kind/minikube dev)
- a `kaniko` profile is included for in-cluster builds (see the Kaniko Profile section below)
- `manifests.rawYaml` points to deployment YAML files
- `portForward` keeps local test access active during dev iterations

## 4) Validate Configuration Before Running

```bash
cd /home/foteas/code/ckad_training/LocalDevelopmentTestingAndContinuousIntegration/05-ConfiguringSkaffoldHotReloadWithKanikoBuild
skaffold diagnose
```

This validates syntax and shows expanded config details (artifacts, dependencies, tags, etc.) before the dev loop starts.

## 5) Start the Continuous Dev Loop

```bash
cd /home/foteas/code/ckad_training/LocalDevelopmentTestingAndContinuousIntegration/05-ConfiguringSkaffoldHotReloadWithKanikoBuild
skaffold dev
```

This works on either context:

```bash
kubectl config use-context kind-ckad
# or
kubectl config use-context mini-ckad
```

Skaffold behavior in this mode:

1. Watches source files
2. Detects changes
3. Builds the image with the local Docker daemon
4. Loads/deploys the image to the cluster
5. Redeploys to Kubernetes via kubectl
6. Continues log streaming and port-forwarding
7. Waits for the next change

## Kaniko Profile (In-Cluster Build)

The default build uses Docker. The `skaffold.yaml` also ships a `kaniko` profile that builds the image **inside a pod** instead of the local Docker daemon.

Key difference: Kaniko always **pushes** the built image, so it needs a registry reachable by both the Kaniko build pod and cluster nodes.

### If you use minikube

Enable the built-in registry first:

```bash
minikube addons enable registry -p mini-ckad
```

Then run with the Kaniko profile and point Skaffold at that registry:

```bash
skaffold dev -p kaniko --default-repo localhost:5000
```

### If you use kind

Do not use `localhost:5000` as the Kaniko target in kind. For pods, `localhost` points to the pod itself, not your host.

You have two valid registry patterns with kind:

- Option A: local registry container on the host Docker network (simpler)
- Option B: registry running inside Kubernetes (more cluster-native)

#### Option A: local registry container (host Docker)

Create a local registry container and connect it to the `kind` Docker network:

```bash
docker run -d --restart=always -p 5000:5000 --name kind-registry registry:2
docker network connect kind kind-registry || true
```

Create the ConfigMap used by tooling to discover the local registry:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "kind-registry:5000"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
```

Then run Kaniko and point Skaffold at the registry container name:

```bash
skaffold dev -p kaniko --default-repo kind-registry:5000
```

Optional quick checks:

```bash
docker ps --format '{{.Names}}\t{{.Ports}}' | grep kind-registry
kubectl get configmap local-registry-hosting -n kube-public
```

#### Option B: in-cluster registry (Kubernetes Deployment + Service)

Deploy a registry into the cluster:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: registry
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
  namespace: registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
        - name: registry
          image: registry:2
          ports:
            - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: registry
  namespace: registry
spec:
  selector:
    app: registry
  ports:
    - name: http
      port: 5000
      targetPort: 5000
EOF
```

Then run Kaniko and point Skaffold at the in-cluster service DNS:

```bash
skaffold dev -p kaniko --default-repo registry.registry.svc.cluster.local:5000
```

Notes for Option B:

- add a PVC if you need image persistence across pod restarts
- configure node runtime trust if your environment enforces strict TLS/insecure-registry rules
- this is valid for labs, but Option A is usually easier to bootstrap on kind

How to tell which builder ran:

- Docker build → output shows `Step X/13` and `using local docker daemon`
- Kaniko build → output shows `Start building with kaniko`, `Sending build context to Kaniko pod`, and a build pod appears in `kubectl get pods`

Use Docker mode for fast everyday local dev; use the Kaniko profile when you specifically want to practice/validate daemonless in-cluster builds.

## 6) Change-and-Observe Cycle

Edit your application source (for example `main.go`) and save.

Skaffold should automatically:

- trigger a new Kaniko build
- redeploy updated workload
- keep the same local test endpoint active

Then test quickly through forwarded port:

```bash
curl http://localhost:8080
```

## 7) Why This Improves Developer Experience

Without Skaffold + Kaniko you typically repeat several manual commands per iteration.

With Skaffold + Kaniko you mostly do:

- edit code
- save
- verify behavior

That is the core productivity win.

## Trade-Offs

- frequent rebuilds can consume cluster resources on large projects
- repeated image publishing/tagging strategy must be handled correctly
- initial setup of `skaffold.yaml` and manifests must be accurate
- insecure mode is for demo/local troubleshooting only

## Troubleshooting Tips

- Build does not start:
  - run `skaffold diagnose` and validate artifact paths
- Deployment does not update:
  - check deployment image name/tag alignment
- No local access:
  - verify `portForward` section and service name/port
- Slow loop:
  - inspect build context size and reduce unnecessary files

### TLS / Registry Errors with Zscaler

If you see errors like:

- `x509: certificate signed by unknown authority`
- `error checking push permissions`

this is caused by TLS interception (for example, Zscaler) between your tools and Docker Hub. No Skaffold or Kaniko flag fixes this, because the failures happen in trust stores that ignore those flags. The real fix is to install the Zscaler CA where the TLS connections actually happen.

## Fixing Zscaler TLS (What Was Actually Done Here)

The environment used Zscaler, which intercepts TLS to Docker Hub. Three separate trust stores needed the Zscaler CA: the WSL host (Skaffold client + WSL Docker) and the minikube node (its Docker daemon that pulls base images).

### Step 1 — Extract the Zscaler CA certificates

Fetch the certificate chain Docker Hub presents and split it into individual certs:

```bash
echo | openssl s_client -connect index.docker.io:443 -showcerts 2>/dev/null > /tmp/dockerhub-chain.pem
cd /tmp && awk 'BEGIN{n=0} /BEGIN CERTIFICATE/{n++} {print > ("cert-" n ".pem")}' dockerhub-chain.pem

# Identify which files are the Zscaler CA certs
for f in cert-*.pem; do echo -n "$f: "; openssl x509 -in "$f" -noout -subject; done
```

The Zscaler CA certs were `cert-2.pem` and `cert-3.pem` (subjects contained `Zscaler Intermediate Root CA`).

### Step 2 — Trust the CA in WSL (fixes Skaffold client + WSL Docker)

```bash
sudo cp /tmp/cert-2.pem /usr/local/share/ca-certificates/zscaler-intermediate-root-t.crt
sudo cp /tmp/cert-3.pem /usr/local/share/ca-certificates/zscaler-intermediate-root.crt
sudo update-ca-certificates

# Verify: this should now return HTTP 401 (auth), NOT an x509 error
curl -sSf -o /dev/null -w '%{http_code}\n' https://index.docker.io/v2/ || true
```

### Step 3 — Trust the CA in the minikube node (fixes base image pulls during build)

Skaffold builds using the minikube node's Docker daemon, so that node must also trust Zscaler:

```bash
minikube cp /tmp/cert-2.pem /tmp/zscaler-t.crt -p mini-ckad
minikube cp /tmp/cert-3.pem /tmp/zscaler.crt -p mini-ckad

minikube ssh -p mini-ckad "sudo cp /tmp/zscaler-t.crt /usr/local/share/ca-certificates/zscaler-t.crt && sudo cp /tmp/zscaler.crt /usr/local/share/ca-certificates/zscaler.crt && sudo update-ca-certificates && sudo systemctl restart docker"

# Verify the node can now pull base images
minikube ssh -p mini-ckad "docker pull golang:1.22-alpine >/dev/null 2>&1 && echo NODE_PULL_OK || echo NODE_PULL_FAIL"
```

### Step 4 — Run Skaffold

After both trust stores were fixed, no insecure flags were needed:

```bash
skaffold run    # one-shot build + deploy to verify
skaffold dev    # continuous loop
```

Notes:

- If you run `minikube delete` and recreate `mini-ckad`, repeat Step 3 (node trust is not preserved).
- Replace `mini-ckad` with your profile name if different.
- These steps trust an interception CA locally; only do this on machines where Zscaler is expected.

## CKAD Note

Skaffold and Kaniko (daemonless, in-cluster image builds) are real-world/CI tooling and are **out of scope** for CKAD — the exam never asks you to build container images at all.

- You won't run `skaffold dev -p kaniko`, wire up registries, or debug TLS/Zscaler trust stores on the exam.
- The one transferable concept is that a build can run as a Pod/Job in the cluster, with the resulting image referenced by a Deployment — but you are only tested on deploying pre-built images.
- Focus exam prep on `kubectl apply`/`set image`/`rollout` against existing images, not on how those images are produced.

## Key Takeaway

Skaffold + Kaniko enable in-cluster, daemonless image builds with an automatic dev loop, but for CKAD this is background — the exam only cares that you can deploy and roll out existing images with `kubectl`.
