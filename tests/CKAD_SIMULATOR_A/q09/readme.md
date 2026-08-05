# Tags

[Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment) [Configure a Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context) 

# Question

Solve this question on instance: `ssh ckad9043`

 In *Namespace* `pluto` runs a single *Pod* `holy-api`. The *Pod* template is at `/course/9/holy-api-pod.yaml`:

1. Convert the *Pod* into *Deployment* `holy-api` with `3` replicas
2. Add Container *SecurityContext*: `allowPrivilegeEscalation: false`, `privileged: false`
3. Save the *Deployment* YAML at `/course/9/holy-api-deployment.yaml` on `ckad9043`
4. Delete the original *Pod* once it's running.

# Answer

There are multiple ways to do this, one is to copy a *Deployment* example from [https://kubernetes.io/docs](https://kubernetes.io/docs) and then merge it with the existing *Pod* yaml. That's what we will do now:



```bash
➜ ssh ckad9043

➜ candidate@ckad9043:~$ cp /course/9/holy-api-pod.yaml /course/9/holy-api-deployment.yaml

➜ candidate@ckad9043:~$ vim /course/9/holy-api-deployment.yaml
```

Now copy/use a *Deployment* example YAML and put the *Pod's* **metadata:** and **spec:** into the *Deployment's* **template:** section:

```yaml
# ckad9043:/course/9/holy-api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: holy-api                       # name stays the same
  namespace: pluto                     # important
spec:
  replicas: 3                          # 3 replicas
  selector:
    matchLabels:
      id: holy-api                     # set the correct selector
  template:
    # => from here down it's the same as the pods metadata: and spec: sections
    metadata:
      labels:
        id: holy-api
      name: holy-api
    spec:
      containers:
      - env:
        - name: CACHE_KEY_1
          value: "b&MTCi0=[T66RXm!jO@"
        - name: CACHE_KEY_2
          value: "PCAILGej5Ld@Q%{Q1=#"
        - name: CACHE_KEY_3
          value: "2qz-]2OJlWDSTn_;RFQ"
        image: nginx:1-alpine
        name: holy-api-container
        securityContext:                   # add
          allowPrivilegeEscalation: false  # add
          privileged: false                # add
        volumeMounts:
        - mountPath: /cache1
          name: cache-volume1
        - mountPath: /cache2
          name: cache-volume2
        - mountPath: /cache3
          name: cache-volume3
      volumes:
      - emptyDir: {}
        name: cache-volume1
      - emptyDir: {}
        name: cache-volume2
      - emptyDir: {}
        name: cache-volume3
```

To indent multiple lines using `vim` you should set the shiftwidth using `:set shiftwidth=2`. Then mark multiple lines using `Shift v` and the up/down keys.

To then indent the marked lines press `>` or `<` and to repeat the action press `.`

Next create the new *Deployment*:



```bash
➜ candidate@ckad9043:~$ k -f /course/9/holy-api-deployment.yaml create
deployment.apps/holy-api created
```

and confirm it's running:

```bash
➜ candidate@ckad9043:~$ k -n pluto get pod | grep holy
holy-api                    1/1     Running   0          19m
holy-api-5dbfdb4569-8qr5x   1/1     Running   0          30s
holy-api-5dbfdb4569-b5clh   1/1     Running   0          30s
holy-api-5dbfdb4569-rj2gz   1/1     Running   0          30s
```

Finally delete the single *Pod*:


```bash
➜ candidate@ckad9043:~$ k -n pluto delete pod holy-api --force --grace-period=0
pod "holy-api" force deleted

➜ candidate@ckad9043:~$ k -n pluto get pod,deployment | grep holy
pod/holy-api-5dbfdb4569-8qr5x   1/1     Running   0          2m4s
pod/holy-api-5dbfdb4569-b5clh   1/1     Running   0          2m4s
pod/holy-api-5dbfdb4569-rj2gz   1/1     Running   0          2m4s

deployment.apps/holy-api   3/3     3            3           2m4s
```

# Checks

- Deployment exists
- Deployment has 3 replicas
- Deployment has 3 ready replicas
- Deployment has single container
- Container has correct name
- Container has correct image
- Deployment defines correct SecurityContext
- Deployment template has same label as pod
- File /course/9/holy-api-deployment.yaml exists
- Old Pod has been removed

