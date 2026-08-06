# Tags

[Pods](https://kubernetes.io/docs/concepts/workloads/pods) [kubectl Commands](https://kubernetes.io/docs/reference/kubectl/generated/)

# Question

Solve this question on instance: `ssh ckad3250`

Create a *Pod* `pod1` of image `httpd:2-alpine` in *Namespace* `default`. The container should be named `pod1-container`.

Also write a `kubectl` command that outputs the *Pod*'s status to `/course/2/pod1-status-command.sh` on `ckad3250`.

# Answer


```bash
➜ ssh ckad3250

➜ candidate@ckad3250:~$ k run -h
Create and run a particular image in a pod.

Examples:
  # Start a nginx pod
  kubectl run nginx --image=nginx
  
  # Start a hazelcast pod and let the container expose port 5701
  kubectl run hazelcast --image=hazelcast/hazelcast --port=5701
...

➜ candidate@ckad3250:~$ k run pod1 --image=httpd:2-alpine --dry-run=client -oyaml > 2.yaml

➜ candidate@ckad3250:~$ vim 2.yaml
```

Change the container name in `2.yaml` to `pod1-container`:

```yaml
# ckad3250:/home/candidate/2.yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: pod1
  name: pod1
spec:
  containers:
  - image: httpd:2-alpine
    name: pod1-container # change
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

Then run:

```bash
➜ candidate@ckad3250:~$ k create -f 2.yaml
pod/pod1 created

➜ candidate@ckad3250:~$ k get pod
NAME   READY   STATUS              RESTARTS   AGE
pod1   0/1     ContainerCreating   0          6s

➜ candidate@ckad3250:~$ k get pod
NAME   READY   STATUS    RESTARTS   AGE
pod1   1/1     Running   0          30s
```

Next create the requested command:

```bash
➜ candidate@ckad3250:~$ vim /course/2/pod1-status-command.sh
```

The content of the command file could look like:

```bash
# /course/2/pod1-status-command.sh
kubectl -n default describe pod pod1 | grep -i status:
```

Another solution would be using jsonpath:

```bash
# /course/2/pod1-status-command.sh
kubectl -n default get pod pod1 -o jsonpath="{.status.phase}"
```

To test the command:

```bash
➜ candidate@ckad3250:~$ sh /course/2/pod1-status-command.sh
Running
```


# Checks

- Pod is running
- Pod has single container
- Container has correct name
- Container has correct image
- File /course/2/[pod1-status-command.sh](http://pod1-status-command.sh) uses kubectl

