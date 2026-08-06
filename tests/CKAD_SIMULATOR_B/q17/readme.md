# Tags

[Canary Deployments](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments) [Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization)

# Question

Solve this question on instance: `ssh ckad3250`
 
*Namespaces* `tea-one` and `tea-two` host separate canary deployments managed via *Kustomize*. Update both *Kustomize* configurations and apply them so the live state matches. Totals are the sum of `current` + `canary` *Pods*:

1. `/course/17/tea-one/`:
  - `4` total *Pods*
  - `0%` traffic to canary (errors reported, full rollback)
  - Verify with `curl -s http://one.tea.local:30020`
2. `/course/17/tea-two/`:
  - `10` total *Pods*
  - `20%` traffic to canary
  - Make changes in the `prod` overlay
  - Verify with `curl -s http://two.tea.local:30030`

# Answer

In a *canary deployment*, two versions of an app run side by side. In a K8s-native *canary deployment*, they share a *Service* selector so traffic is split between them in proportion to their *Pod* counts. To shift traffic, we change the replica ratio.

*Kustomize* is a tool for managing Kubernetes YAML configurations and is also built into kubectl. A common pattern is to keep shared resources in a base and adjust them through overlays, such as staging and production overlays.

###### **Update** `tea-one`

`tea-one`'s `kustomization.yaml` is a pure bundler, replica counts live in the *Deployment* files themselves. Edit both:

```sh
➜ ssh ckad3250

➜ candidate@ckad3250:~$ cd /course/17/tea-one/

➜ candidate@ckad3250:/course/17/tea-one$ vim deployment-current.yaml
```
```yaml
# ckad3250:/course/17/tea-one/deployment-current.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: current
spec:
  replicas: 4      # UPDATE from 3
  selector:
    matchLabels:
      app: tea-one
      version: current
...
```
```sh
➜ candidate@ckad3250:/course/17/tea-one$ vim deployment-canary.yaml
```
```yaml
# ckad3250:/course/17/tea-one/deployment-canary.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: canary
spec:
  replicas: 0      # UPDATE from 1
  selector:
    matchLabels:
      app: tea-one
      version: canary
...
```

First we diff, and we can use `-k` for Kustomize which is built into kubectl:

```sh
➜ candidate@ckad3250:/course/17/tea-one$ k -k . diff
diff -u -N /tmp/LIVE-836305243/apps.v1.Deployment.tea-one.canary /tmp/MERGED-2046445066/apps.v1.Deployment.tea-one.canary
...
 spec:
   progressDeadlineSeconds: 600
-  replicas: 1
+  replicas: 0
   revisionHistoryLimit: 10
   selector:
     matchLabels:
diff -u -N /tmp/LIVE-836305243/apps.v1.Deployment.tea-one.current /tmp/MERGED-2046445066/apps.v1.Deployment.tea-one.current
...
 spec:
   progressDeadlineSeconds: 600
-  replicas: 3
+  replicas: 4
   revisionHistoryLimit: 10
   selector:
     matchLabels:
```

If it looks good we apply with `kubectl apply -k`:

```sh
➜ candidate@ckad3250:/course/17/tea-one$ k -k . apply
service/tea-one unchanged
deployment.apps/canary configured
deployment.apps/current configured
```


###### **Update** `tea-two`

The `base/` defines the resources; the `prod/` overlay is where the replica counts are set. Edit the `prod` overlay as mentioned on the question:

```sh
➜ candidate@ckad3250:~$ cd /course/17/tea-two/prod

➜ candidate@ckad3250:/course/17/tea-two/prod$ vim kustomization.yaml
```
```yaml
# ckad3250:/course/17/tea-two/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../base
replicas:
  - name: current
    count: 8      # UPDATE from 10
  - name: canary
    count: 2      # UPDATE from 0
```

First we diff:

```sh
➜ candidate@ckad3250:/course/17/tea-two/prod$ k -k . diff
diff -u -N /tmp/LIVE-2909103623/apps.v1.Deployment.tea-two.canary /tmp/MERGED-418920802/apps.v1.Deployment.tea-two.canary
...
 spec:
   progressDeadlineSeconds: 600
-  replicas: 0
+  replicas: 2
   revisionHistoryLimit: 10
   selector:
     matchLabels:
diff -u -N /tmp/LIVE-2909103623/apps.v1.Deployment.tea-two.current /tmp/MERGED-418920802/apps.v1.Deployment.tea-two.current
...
 spec:
   progressDeadlineSeconds: 600
-  replicas: 10
+  replicas: 8
   revisionHistoryLimit: 10
   selector:
     matchLabels:
```

Then we apply:

```sh
➜ candidate@ckad3250:/course/17/tea-two/prod$ k -k . apply
service/tea-two unchanged
deployment.apps/canary configured
deployment.apps/current configured
```

###### **Verify**

```sh
➜ candidate@ckad3250:/course/17/tea-two/prod$ k -n tea-one get deploy
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
canary    0/0     0            0           18m
current   4/4     4            4           18m


➜ candidate@ckad3250:/course/17/tea-two/prod$ k -n tea-two get deploy
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
canary    2/2     2            2           18m
current   8/8     8            8           18m
```

Hit each *Service* a few times and look at the split:

```sh
➜ candidate@ckad3250:/course/17/tea-two/prod$ for i in $(seq 1 20); do curl -s http://one.tea.local:30020; done
current-7c5dd6795-v8v7c
current-7c5dd6795-blqz2
current-7c5dd6795-g98gf
current-7c5dd6795-blqz2
current-7c5dd6795-blqz2
...

➜ candidate@ckad3250:/course/17/tea-two/prod$ for i in $(seq 1 20); do curl -s http://two.tea.local:30030; done
canary-fd9756756-8ths9
current-795b8ff549-66blz
current-795b8ff549-ldzfk
current-795b8ff549-8cbg4
canary-fd9756756-8ths9
...
```

Ensure to use the correct ports of the *Services*, `30020` vs `30030`. Then we should see our canary request distribution.

# Checks

- tea-one Deployment current has 4 replicas
- tea-one Deployment canary has 0 replicas
- tea-one Kustomize configuration diff shows nothing
- tea-two Deployment current has 8 replicas
- tea-two Deployment canary has 2 replicas
- tea-two Kustomize configuration diff shows nothing

