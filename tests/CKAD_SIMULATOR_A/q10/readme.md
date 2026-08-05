# Tags

[Debug Running Pods](https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/) [kubectl logs](https://kubernetes.io/docs/reference/kubectl/quick-reference/#viewing-and-finding-resources) [kubectl debug](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_debug/)

# Question

Solve this question on instance: `ssh ckad7326`

 

*Pod* `mystery-pod` in *Namespace* `triton` keeps crashing. Investigate it:

1. Write the error logs from the crashed container into `/course/10/error.log` on `ckad7326`
2. Use `kubectl debug` to add an ephemeral container to the *Pod*
  - Image: `bash:5`
  - Name: `debugger`
  - Command: `sleep 30d` to keep it running

# Answer

 

###### **Read the previous container logs**



```bash
➜ ssh ckad7326

➜ candidate@ckad7326:~$ k -n triton get pod
NAME          READY   STATUS    RESTARTS      AGE
mystery-pod   1/1     Running   3 (4m ago)    32m
```

The *Pod* shows as `Running` right now, but the `RESTARTS` column tells us it has crashed before. The container runs for about 10 minutes before crashing each time, so most of the time we catch it during a fresh run that hasn't crashed yet.

Using `k logs` only shows what the current container wrote so far. To get the proper errors we often have to use `--previous` to get the logs of the previous container (that crashed):



```bash
➜ candidate@ckad7326:~$ k -n triton logs mystery-pod
starting app v0.7.3


➜ candidate@ckad7326:~$ k -n triton logs mystery-pod --previous
starting app v0.7.3
ERROR: upstream service unreachable
```

We save the matching line to the requested file:



```bash
➜ candidate@ckad7326:~$ k -n triton logs mystery-pod --previous > /course/10/error.log


➜ candidate@ckad7326:~$ cat /course/10/error.log
starting app v0.7.3
ERROR: upstream service unreachable
```

 ###### **Attach an ephemeral debug container**

To poke around the *Pod* without touching the crashing container, we add an ephemeral container with `kubectl debug`.


```bash
➜ candidate@ckad7326:~$ k -n triton debug pod/mystery-pod -c debugger --image=bash:5 -- sleep 30d
Defaulting debug container name to debugger.
```

The `-- sleep 30d` keeps the container alive after we detach so it stays attached to the *Pod*.

We can confirm the ephemeral container is now in the *Pod* spec:


```bash
➜ candidate@ckad7326:~$ k -n triton get pod mystery-pod -oyaml


# kubectl -n triton get pod mystery-pod -oyaml
apiVersion: v1
kind: Pod
metadata:
  name: mystery-pod
...
spec:
  containers:
  - image: bash:5
    imagePullPolicy: IfNotPresent
    name: app
...
  ephemeralContainers:
  - command:
    - sleep
    - "30d"
    image: bash:5
    imagePullPolicy: IfNotPresent
    name: debugger
    resources: {}
    securityContext:
      capabilities:
        add:
        - SYS_PTRACE
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
...
```

Now we could `k -n triton exec -it mystery-pod -c debugger -- bash` to enter the debug container and inspect the *Pod*'s network, mounted volumes, or environment without affecting the crashing `app` container.
 

# Checks

- File /course/10/error.log contains correct error logs
- Pod mystery-pod has kubectl debug container

