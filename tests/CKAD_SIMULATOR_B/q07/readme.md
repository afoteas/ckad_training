# Tags

[HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale) [API Deprecation Guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide)

# Question

Solve this question on instance: `ssh ckad1695`

A *HorizontalPodAutoscaler* YAML has been placed at `/course/7/hpa.yaml` to autoscale the existing *Deployment* `cherry-app` in *Namespace* `cherry`. But its `apiVersion` is no longer accepted by this cluster.

1. Fix the deprecation issue
2. Set `minReplicas` to `2` and `maxReplicas` to `5`
3. Scale on memory utilization with target average `80` (in addition to CPU)

Then apply the *HPA*.

# Answer



###### **Try to apply the *HPA***

First we look at the file we were given:

```sh
➜ ssh ckad1695

➜ candidate@ckad1695:~$ cat /course/7/hpa.yaml
apiVersion: autoscaling/v2beta2
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-cherry
  namespace: cherry
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: cherry-app
  minReplicas: 1
  maxReplicas: 3
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

We'll work here with a pretty standard *HPA* which scales depending on the average CPU usage of the *Pods* of the *Deployment* `cherry-app`.

Try to apply it to see what `kubectl` says:

```sh
➜ candidate@ckad1695:~$ k apply -f /course/7/hpa.yaml
error: resource mapping not found for name: "hpa-cherry" namespace: "cherry" from "/course/7/hpa.yaml": no matches for kind "HorizontalPodAutoscaler" in version "autoscaling/v2beta2"
ensure CRDs are installed first
```

Depending on the *K8s* version, `kubectl` may show:

1. A warning which means the version is still deprecated but accepted
2. An error which means the `apiVersion` has been fully removed

Either way the next step is the same: find the correct current version and use it instead.

###### **Fix the deprecation issue**

Using `kubectl explain` we can see current version pretty fast:

```sh
➜ candidate@ckad1695:~$ k explain hpa
GROUP:      autoscaling
KIND:       HorizontalPodAutoscaler
VERSION:    v2
...
```

The [API Deprecation Guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide) lists every removed *apiVersion* with its replacement.

Edit the file and update the `apiVersion`:

```sh
➜ candidate@ckad1695:~$ vim /course/7/hpa.yaml
```
```yaml
# ckad1695:/course/7/hpa.yaml
apiVersion: autoscaling/v2         # UPDATE
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-cherry
  namespace: cherry
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: cherry-app
  minReplicas: 1
  maxReplicas: 3
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

> ℹ️ Depending on the resource changes between versions, like updated/changed fields, more things than just the `apiVersion` might need to be updated!

Now we apply to see if there are still errors:

```sh
➜ candidate@ckad1695:~$ k apply -f /course/7/hpa.yaml
horizontalpodautoscaler.autoscaling/hpa-cherry created

➜ candidate@ckad1695:~$ k -n cherry get hpa
NAME      REFERENCE            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
hpa-cherry   Deployment/cherry-app   cpu: 0%/50%   1         3         1          18s
```

That looks much better!

###### **Adjust *HPA***

We also need to perform the other required changes:

```sh
➜ candidate@ckad1695:~$ vim /course/7/hpa.yaml
```

```yaml
# ckad1695:/course/7/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-cherry
  namespace: cherry
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: cherry-app
  minReplicas: 2                   # UPDATE
  maxReplicas: 5                   # UPDATE
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  - type: Resource                 # ADD
    resource:                      # ADD
      name: memory                 # ADD
      target:                      # ADD
        type: Utilization          # ADD
        averageUtilization: 80     # ADD
```

Apply:

```sh
➜ candidate@ckad1695:~$ k apply -f /course/7/hpa.yaml
horizontalpodautoscaler.autoscaling/hpa-cherry configured
```

Verify:

```sh
➜ candidate@ckad1695:~$ k -n cherry get hpa,pod
NAME    ...   TARGETS                       MINPODS  MAXPODS  REPLICAS ...
hpa-cherry  ...  cpu: 0%/50%, memory: 11%/80%  2        5        2        ...

NAME                           READY   STATUS    RESTARTS   AGE
pod/cherry-app-7798d7f986-c9l2n   1/1     Running   0          5m31s
pod/cherry-app-7798d7f986-jxvq5   1/1     Running   0          18s
```

The *HPA* is now configured correctly. The TARGETS column shows the current CPU and memory utilisation against the configured thresholds. Even without the *Pods* reaching the average CPU or Memory configured in the *HPA*, we now see two *Pods* instead of one because of the `minReplicas: 2`.

With multiple metrics, the *HPA* scales **up** as soon as **any** metric exceeds its target (the most-stressed metric wins), and scales **down** only when **all** metrics agree fewer *Pods* would still stay under target.

 

# Checks

- HPA hpa-cherry exists in cherry namespace
- HPA targets Deployment cherry-app
- minReplicas and maxReplicas correct
- Memory utilization metric with averageUtilization=80

