# Verifying Image Signatures via ImagePolicyWebhook

This lesson demonstrates cluster-level image signature enforcement using the **Sigstore Policy Controller** admission webhook.

For background on Cosign signing, see [05-ImageSigningAndVerificationWithCosign](../05-ImageSigningAndVerificationWithCosign/readme.md).

## Demo Files

- `unsigned-pod.yaml` — Pod with an unsigned image
- `signed-pod.yaml` — Pod with a Chainguard signed image
- `cluster-image-policy.yaml` — policy requiring Cosign signatures

## Prerequisites

- Kubernetes cluster running (minikube or cloud)
- `kubectl` configured
- `helm` installed
- `cosign` installed locally

## How Admission Webhooks Work

Admission webhooks are HTTP callbacks that intercept requests to the Kubernetes API server **before** they are persisted.

```text
kubectl apply  →  API server  →  Admission webhook  →  Allow or deny
```

| Webhook type | Behavior |
|--------------|----------|
| **Validating** | Allow or deny the request based on rules |
| **Mutating** | Modify the request before it is saved |

Flow for image verification:

1. User runs `kubectl apply`.
2. API server receives the Pod creation request.
3. Policy controller webhook validates the container image signature.
4. If valid → Pod is created. If invalid → request is rejected.

## Cosign Recap

Cosign (from the Sigstore project) provides:

- Image signing with cryptographic signatures
- Keyless signing using OpenID Connect (OIDC)
- Transparency via Rekor signature logs

The **Policy Controller** is an admission webhook that enforces image signature policies using Cosign verification.

## Step 1: Install the Sigstore Policy Controller

```bash
helm repo add sigstore https://sigstore.github.io/helm-charts
helm repo update

kubectl create namespace cosign-system

helm install policy-controller sigstore/policy-controller -n cosign-system --devel
```

Wait for the webhook to be ready:

```bash
kubectl wait --for=condition=Available \
  deployment/policy-controller-webhook -n cosign-system --timeout=120s
```

Verify the webhook is registered:

```bash
kubectl get validatingwebhookconfigurations | grep policy
```

## Step 2: Test Without a Policy (Baseline)

Deploy an unsigned Pod — it should succeed because no policy is enforced yet:

```bash
kubectl apply -f unsigned-pod.yaml
kubectl get pod unsigned-app
kubectl logs unsigned-app
```

Expected behavior: Pod is created and runs normally.

Clean up:

```bash
kubectl delete -f unsigned-pod.yaml
```

## Step 3: Apply a ClusterImagePolicy

Apply a policy requiring Cosign signatures for Chainguard images:

```bash
kubectl apply -f cluster-image-policy.yaml
kubectl get clusterimagepolicy
```

Policy breakdown:

```yaml
spec:
  images:
  - glob: "cgr.dev/**"          # Match all Chainguard images
  authorities:
  - keyless:                     # Accept keyless OIDC signatures
      identities:
      - issuer: "*"
        subject: "*"
```

Chainguard images are pre-signed, making them ideal for testing without managing your own keys.

## Step 4: Deploy a Signed Image

```bash
kubectl apply -f signed-pod.yaml
kubectl get pod signed-app
kubectl describe pod signed-app
```

Expected behavior: Pod is **admitted** — the policy controller validated the Cosign signature before allowing creation.

## Step 5: Verify Webhook Logs

```bash
kubectl logs -n cosign-system \
  -l app.kubernetes.io/name=policy-controller --tail=50
```

Look for log entries confirming the image signature was verified.

## Step 6: Test an Unsigned Image (Should Fail)

After the policy is active, try deploying an unsigned image:

```bash
kubectl apply -f unsigned-pod.yaml
```

Expected behavior: Pod creation is **rejected** because the image lacks a valid Cosign signature matching the policy.

## Optional Cleanup

```bash
kubectl delete -f signed-pod.yaml
kubectl delete -f cluster-image-policy.yaml
helm uninstall policy-controller -n cosign-system
kubectl delete namespace cosign-system
```

## Note on ImagePolicyWebhook vs Policy Controller

Kubernetes also supports a built-in `ImagePolicyWebhook` admission plugin configured on the API server. The Sigstore **Policy Controller** is the modern, Cosign-native approach shown in this lesson — it uses `ClusterImagePolicy` CRDs instead of a static API server config file.

## Key Takeaway

Admission webhooks enforce image trust at the cluster gate. Only Cosign-signed images matching your policy are allowed — unsigned or tampered images never reach the scheduler.
