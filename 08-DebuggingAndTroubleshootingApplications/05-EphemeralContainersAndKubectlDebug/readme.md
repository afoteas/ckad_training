# Ephemeral Containers & kubectl debug

This lesson introduces ephemeral containers for live debugging when normal `kubectl exec` is not practical, such as crash loops.

## Why Ephemeral Containers

- attach temporary debug tooling to a running pod
- inspect filesystem, env, and networking without redeploy
- preserve failing runtime context while debugging

## Core Command

```bash
kubectl debug <pod-name> -it --image=busybox --target=<container-name>
```

What it does:

- injects a temporary debug container
- attaches interactive shell
- targets process namespace context of selected container

## Popular Debug Images

| Image | Best For | Main Advantage |
| --- | --- | --- |
| `busybox` | quick basic checks | tiny image, fast pull, minimal footprint |
| `alpine` | lightweight shell + package installs | small size with easy `apk` package installs |
| `ubuntu` | richer Linux debugging environment | familiar tools and broad package ecosystem |
| `debian` | stable full-featured troubleshooting shell | reliable base with extensive utilities |
| `nicolaka/netshoot` | network and DNS troubleshooting | purpose-built networking toolbox (`dig`, `tcpdump`, `ss`, `nc`) |
| `praqma/network-multitool` | general network diagnostics | many networking commands in one image |
| `curlimages/curl` | API and HTTP endpoint checks | minimal image focused on `curl` workflows |

## Useful Debug Tasks

- inspect files and config
- inspect environment variables
- run `ping`, `wget`, `nslookup`, `curl`
- run process/system tools for deeper diagnosis

## Limitations

- ephemeral containers do not restart automatically
- support depends on cluster Kubernetes version/features
- debug images can expose sensitive runtime data, so use strict RBAC

## CKAD Tips

- Core command to memorize: `kubectl debug <pod> -it --image=busybox --target=<container>` injects an interactive debug container into a running pod without a redeploy.
- Use `--target=<container>` to share that container's process namespace; without it you can't see the target's processes.
- Reach for `kubectl debug` (not `kubectl exec`) when a pod is crash-looping or the app image has no shell/tools.
- Pick the image for the job: `busybox` for quick checks, `nicolaka/netshoot` for network/DNS (`dig`, `tcpdump`, `nc`), `curlimages/curl` for HTTP endpoint tests.
- Remember ephemeral containers can't be added to a pod spec and won't restart — they're strictly for one-off live diagnosis.

## Key Takeaway

Ephemeral containers via `kubectl debug` let you attach troubleshooting tooling to a live (even crashing) pod without rebuilding or redeploying it, preserving the failing runtime for inspection.