# Kustomize For Overlay Management

## What Kustomize is
Kustomize lets you customize Kubernetes manifests without editing the original YAML files.
You keep one base and apply environment-specific changes through overlays.

## Why overlays are useful
- Keep one source of truth for shared resources.
- Avoid copy-pasting full manifests for each environment.
- Apply small, readable changes for dev, staging, and prod.

## Typical folder layout
		.
		├── base
		│   ├── deployment.yaml
		│   └── kustomization.yaml
		└── overlays
				├── dev
				│   └── kustomization.yaml
				└── prod
						└── kustomization.yaml

## Core files

### Base kustomization
Minimal base example:

		apiVersion: kustomize.config.k8s.io/v1beta1
		kind: Kustomization
		resources:
			- deployment.yaml

### Overlay kustomization
Each overlay references the base and applies changes such as namespace, replicas, labels, image tag, or patches.

Example dev overlay:

		apiVersion: kustomize.config.k8s.io/v1beta1
		kind: Kustomization
		resources:
			- ../../base
		namespace: dev
		nameSuffix: -dev
		commonLabels:
			env: dev
		replicas:
			- name: app
				count: 1

Example prod overlay:

		apiVersion: kustomize.config.k8s.io/v1beta1
		kind: Kustomization
		resources:
			- ../../base
		namespace: prod
		nameSuffix: -prod
		commonLabels:
			env: prod
		replicas:
			- name: app
				count: 3

## High-value commands

Preview rendered manifests:

		kubectl kustomize overlays/dev
		kubectl kustomize overlays/prod

Apply overlays:

		kubectl apply -k overlays/dev
		kubectl apply -k overlays/prod

Verify:

		kubectl get deploy -n dev
		kubectl get deploy -n prod
		kubectl describe deploy <deployment-name> -n dev

Delete overlay resources:

		kubectl delete -k overlays/dev

## Common customization options
- namePrefix and nameSuffix: make names environment-specific.
- namespace: place resources in target namespace.
- commonLabels and commonAnnotations: stamp metadata across resources.
- images: change image name or tag per environment.
- replicas: set replica count per environment.
- patches: change specific fields in selected resources.
- configMapGenerator and secretGenerator: build config objects from files or literals.

## CKAD exam-friendly workflow
1. Start with a clean base that only contains shared settings.
2. Put environment differences only in overlays.
3. Render first with kubectl kustomize to validate output.
4. Apply with kubectl apply -k.
5. Verify with get and describe before moving on.

## Frequent mistakes to avoid
- Editing base for one environment-specific change.
- Wrong relative path from overlay to base.
- Namespace mismatch between overlays and validation commands.
- Assuming generated names when nameSuffix or namePrefix is set.

## Transcript Enhancements (Preserved Notes Kept)

### Why Kustomize

Kustomize reduces YAML duplication by separating common manifests (base) from environment-specific changes (overlays).

### Core Pattern

1. keep shared resources in base
2. encode environment deltas in overlays
3. render and apply with `kubectl -k`

### Scope Clarification

Kustomize is native configuration overlay tooling. It is not a package manager with chart repositories or release history like Helm.

## CKAD Tips

- Kustomize is built into kubectl: render with `kubectl kustomize <dir>` and apply with `kubectl apply -k <dir>`.
- Always render before applying so you can verify the merged output.
- Know the common overlay fields: `namespace`, `namePrefix`/`nameSuffix`, `commonLabels`, `images`, `replicas`, and `patches`.
- Overlays reference the base via `resources: - ../../base`; a wrong relative path is the most common failure.
- Never edit the base for a one-off environment change — put the delta in the overlay.

## Key Takeaway

Kustomize keeps a single base of manifests and layers environment-specific overlays on top, applied natively with `kubectl -k` — no templating language or chart repositories required.

