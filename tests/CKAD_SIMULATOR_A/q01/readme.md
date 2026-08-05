# Tags
[Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces) [kubectl Quick Reference](https://kubernetes.io/docs/reference/kubectl/quick-reference)

# Question

Solve this question on instance: `ssh ckad5601`

Save the list of all Namespaces in the cluster to `/course/1/namespaces` on ckad5601. Extra columns like STATUS or AGE are fine.

# Answer
``` bash
ssh ckad5601

candidate@ckad5601:~$ k get ns > /course/1/namespaces
```
The content should then look like:

``` bash
candidate@ckad5601:~$ cat /course/1/namespaces
NAME              STATUS   AGE
default           Active   136m
earth             Active   105m
jupiter           Active   105m
kube-node-lease   Active   136m
kube-public       Active   136m
kube-system       Active   136m
mars              Active   105m
shell-intern      Active   105m
```

# Checks

 - File `/course/1/namespaces` contains all namespaces