# Imperative work log — 2026-08-06

## Q5 — Helm release frontdoor

```sh
helm install frontdoor ../localchart/ -n release --set replicaCount=3,image=nginx:1.27
```

## Q6 — Kustomize prod overlay

```sh
```

## Q7 — payments strategy + rollback

How the good revision was identified:

```sh
 k rollout history deploy payments -n release
```

## Q10 — RBAC deploy-bot

Proof the bot can create but not delete Deployments:

```sh
```

## Q17 — triage alpha / beta / gamma

Diagnosis command:

```sh
k get pods -n triage -o yaml
```

Root cause and fix per Pod:

- `alpha` —
- `beta` —
- `gamma` —

- alpha - ImagePullBackOff - change image
- beta - CrashLoopBackOff - sleep infinity
- gamma -CreateContainerConfigError -- create cm
