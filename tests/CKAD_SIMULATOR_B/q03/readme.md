# Tags
[Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels) [Annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations)

# Question

Solve this question on instance: `ssh ckad1695`

In *Namespace* `oak`:

1. Add the label `protected: true` to all *Pods* with an existing label `type: worker` or `type: runner`
2. Then add the annotation `protected: do not delete this pod` to all *Pods* with the new `protected: true` label

# Answer


```bash
➜ ssh ckad1695

➜ candidate@ckad1695:~$ k -n oak get pod --show-labels
NAME           READY   STATUS    RESTARTS   AGE   LABELS
0509649a       1/1     Running   0          29s   type=runner,type_old=messenger
0509649b       1/1     Running   0          29s   type=worker
1428721e       1/1     Running   0          28s   type=worker
1428721f       1/1     Running   0          29s   type=worker
43b9a          1/1     Running   0          23s   type=test
4c09           1/1     Running   0          26s   type=worker
4c35           1/1     Running   0          25s   type=worker
4fe4           1/1     Running   0          27s   type=worker
5555a          1/1     Running   0          24s   type=messenger
86cda          1/1     Running   0          23s   type=runner
8d1c           1/1     Running   0          26s   type=messenger
a004a          1/1     Running   0          24s   type=runner
a94128196      1/1     Running   0          29s   type=runner,type_old=messenger
afd79200c56a   1/1     Running   0          28s   type=worker
b667           1/1     Running   0          27s   type=worker
fdb2           1/1     Running   0          25s   type=worker
```

If we would only like to get pods with certain labels we can run:

```bash
➜ candidate@ckad1695:~$ k -n oak get pod -l type=runner
NAME        READY   STATUS    RESTARTS   AGE
0509649a    1/1     Running   0          41s
86cda       1/1     Running   0          35s
a004a       1/1     Running   0          36s
a94128196   1/1     Running   0          41s
```

We can use this label filtering also when using other commands, like setting new labels:

```bash
➜ candidate@ckad1695:~$ k label -h
...
Examples:
  # Update pod 'foo' with the label 'unhealthy' and the value 'true'
  kubectl label pods foo unhealthy=true
  
  # Update pod 'foo' with the label 'status' and the value 'unhealthy', overwriting any existing value
  kubectl label --overwrite pods foo status=unhealthy
...

➜ candidate@ckad1695:~$ k -n oak label pod -l type=runner protected=true
pod/0509649a labeled
pod/86cda labeled
pod/a004a labeled
pod/a94128196 labeled


➜ candidate@ckad1695:~$ k -n oak label pod -l type=worker protected=true
pod/0509649b labeled
pod/1428721e labeled
pod/1428721f labeled
pod/4c09 labeled
pod/4c35 labeled
pod/4fe4 labeled
pod/afd79200c56a labeled
pod/b667 labeled
pod/fdb2 labeled
```

Or we could run:

```bash
kubectl -n oak label pod -l "type in (worker,runner)" protected=true
```

Let's check the result:

```bash
➜ candidate@ckad1695:~$ k -n oak get pod --show-labels
NAME           ...   AGE   LABELS
0509649a       ...          56s   protected=true,type=runner,type_old=messenger
0509649b       ...          55s   protected=true,type=worker
1428721e       ...          54s   protected=true,type=worker
1428721f       ...          53s   protected=true,type=worker
43b9a          ...          53s   type=test
4c09           ...          52s   protected=true,type=worker
4c35           ...          51s   protected=true,type=worker
4fe4           ...          50s   protected=true,type=worker
5555a          ...          50s   type=messenger
86cda          ...          49s   protected=true,type=runner
8d1c           ...          48s   type=messenger
a004a          ...          47s   protected=true,type=runner
a94128196      ...          46s   protected=true,type=runner,type_old=messenger
afd79200c56a   ...          46s   protected=true,type=worker
b667           ...          45s   protected=true,type=worker
fdb2           ...          44s   protected=true,type=worker
```

Looking good. Finally we set the annotation using the newly assigned label `protected: true`:

```bash
➜ candidate@ckad1695:~$ k -n oak annotate pod -l protected=true protected="do not delete this pod"
pod/0509649a annotated
pod/0509649b annotated
pod/1428721e annotated
pod/1428721f annotated
pod/4c09 annotated
pod/4c35 annotated
pod/4fe4 annotated
pod/86cda annotated
pod/a004a annotated
pod/a94128196 annotated
pod/afd79200c56a annotated
pod/b667 annotated
pod/fdb2 annotated
```

Not requested in the task but for your own control you could run:

```bash
➜ candidate@ckad1695:~$ k -n oak get pod -l protected=true -o yaml | grep -A 8 metadata:
  metadata:
    annotations:
      kubectl.kubernetes.io/last-applied-configuration: |
        {"apiVersion":"v1","kind":"Pod","metadata":{"annotations":{},"labels":{"type":"runner","type_old":"messenger"},"name":"0509649a","namespace":"oak"},"spec":{"containers":[{"args":["sh","-c","sleep 2d"],"image":"python:3-alpine","name":"con"}],"dnsPolicy":"ClusterFirst","restartPolicy":"Always"}}
      protected: do not delete this pod
    creationTimestamp: "2026-06-09T20:39:11Z"
    generation: 1
    labels:
      protected: "true"
--
...
```

# Checks

- Pods with label type=runner have new labels
- Pods with label type=worker have new labels
- Pods with label protected=true have annotation
