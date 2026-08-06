# Tags

[Configure Probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes)

# Question

Solve this question on instance: `ssh ckad3250`

 

Create a single *Pod* named `pod6` in *Namespace* `default` of image `busybox:1` running command `touch /tmp/ready && sleep 1d`.

Add a readiness-probe executing `cat /tmp/ready` with initial delay of `5` seconds and period of `10` seconds.

# Answer


```sh
➜ ssh ckad3250

➜ candidate@ckad3250:~$ k run pod6 --image=busybox:1 --dry-run=client -oyaml --command -- sh -c "touch /tmp/ready && sleep 1d" > 6.yaml

➜ candidate@ckad3250:~$ vim 6.yaml
```

Search for a readiness-probe example on [https://kubernetes.io/docs](https://kubernetes.io/docs), then copy and alter the relevant section for the task:

```yaml
# ckad3250:/home/candidate/6.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod6
  name: pod6
spec:
  containers:
  - command:
    - sh
    - -c
    - touch /tmp/ready && sleep 1d
    image: busybox:1
    name: pod6
    resources: {}
    readinessProbe:                             # add
      exec:                                     # add
        command:                                # add
        - sh                                    # add
        - -c                                    # add
        - cat /tmp/ready                        # add
      initialDelaySeconds: 5                    # add
      periodSeconds: 10                         # add
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

Then:

```sh
➜ candidate@ckad3250:~$ k -f 6.yaml create
pod/pod6 created
```

Running `k get pod pod6` we should see the pod being created and become ready:

```sh
➜ candidate@ckad3250:~$ k get pod pod6
NAME   READY   STATUS              RESTARTS   AGE
pod6   0/1     ContainerCreating   0          2s

➜ candidate@ckad3250:~$ k get pod pod6
NAME   READY   STATUS    RESTARTS   AGE
pod6   0/1     Running   0          7s

➜ candidate@ckad3250:~$ k get pod pod6
NAME   READY   STATUS    RESTARTS   AGE
pod6   1/1     Running   0          15s
```

We see that the *Pod* is finally ready.

# Checks

- Pod is running
- Pod has single container
- Container has correct image
- ReadinessProbe has correct initialDelaySeconds
- ReadinessProbe has correct periodSeconds

