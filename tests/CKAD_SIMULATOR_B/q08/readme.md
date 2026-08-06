# Tags

[Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment)

# Question

Solve this question on instance: `ssh ckad6422`

 

*Deployment* `api-new-c32` in *Namespace* `aspen` has a recent update that never came online. Check the *Deployment* history, find a working revision, and rollback to it.

# Answer

```sh
➜ ssh ckad6422

➜ candidate@ckad6422:~$ k -n aspen get deploy
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
api-new-c32   0/3     3            0           12d

➜ candidate@ckad6422:~$ k -n aspen rollout history -h
View previous rollout revisions and configurations.

Examples:
  # View the rollout history of a deployment
  kubectl rollout history deployment/abc
  
  # View the details of daemonset revision 3
  kubectl rollout history daemonset/abc --revision=3
...

➜ candidate@ckad6422:~$ k -n aspen rollout history deploy api-new-c32
deployment.apps/api-new-c32 
REVISION  CHANGE-CAUSE
1         <none>
2         kubectl edit deployment api-new-c32 --namespace=aspen
3         kubectl edit deployment api-new-c32 --namespace=aspen
4         kubectl edit deployment api-new-c32 --namespace=aspen
5         kubectl edit deployment api-new-c32 --namespace=aspen
```

We see 5 revisions, let's check *Pod* and *Deployment* status:

```sh
➜ candidate@ckad6422:~$ k -n aspen get deploy,pod | grep api-new-c32
deployment.apps/api-new-c32   0/3     3            0           12d
pod/api-new-c32-785d9d6f74-6ffng   0/1     ImagePullBackOff   0          12d
pod/api-new-c32-785d9d6f74-kt5cd   0/1     ImagePullBackOff   0          12d
pod/api-new-c32-785d9d6f74-lwjpl   0/1     ImagePullBackOff   0          12d
```

Let's check the pod for errors:

```sh
➜ candidate@ckad6422:~$ k -n aspen describe pod api-new-c32-785d9d6f74-lwjpl | grep -i error
  Warning  Failed     12d (x5 over 12d)    kubelet            spec.containers{nginx}: Failed to pull image "ngnix:1-alpine": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/ngnix:1-alpine": failed to resolve image: docker.io/library/ngnix:1-alpine: not found
  Warning  Failed     12d (x5 over 12d)    kubelet            spec.containers{nginx}: Error: ErrImagePull
  Warning  Failed     12d (x174 over 12d)  kubelet            spec.containers{nginx}: Error: ImagePullBackOff
```

Someone seems to have added a new image with a spelling mistake in the name `ngnix:1-alpine`, that's the reason for the error.

Now we inspect previous revisions to find one with the correct image. We can pass `--revision=N` to `rollout history` to see the *Pod* template of that revision:

```sh
➜ candidate@ckad6422:~$ k -n aspen rollout history deploy api-new-c32 --revision=5
deployment.apps/api-new-c32 with revision #5
Pod Template:
  Labels:       id=api-new-c32
        pod-template-hash=785d9d6f74
        version=v5
  Annotations:  kubernetes.io/change-cause: kubectl edit deployment api-new-c32 --namespace=aspen
  Containers:
   nginx:
    Image:      ngnix:1-alpine
...


➜ candidate@ckad6422:~$ k -n aspen rollout history deploy api-new-c32 --revision=4
deployment.apps/api-new-c32 with revision #4
Pod Template:
  Labels:       id=api-new-c32
        pod-template-hash=77c8857b45
        version=v4
  Annotations:  kubernetes.io/change-cause: kubectl edit deployment api-new-c32 --namespace=aspen
  Containers:
   nginx:
    Image:      nginx:1-alpine
...
```

Revision `4` uses the correct image `nginx:1-alpine`, so we rollback to it:

```sh
➜ candidate@ckad6422:~$ k -n aspen rollout undo deploy api-new-c32 --to-revision=4
deployment.apps/api-new-c32 rolled back
```

Does this one work?

```sh
➜ candidate@ckad6422:~$ k -n aspen get deploy api-new-c32
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
api-new-c32   3/3     3            3           12d
```

Yes! All up-to-date and available.

Also a fast way to get an overview of the *ReplicaSets* of a *Deployment* and their images could be done with:

```sh
➜ candidate@ckad6422:~$ candidate@ckad6422:~$ k -n aspen get rs -o wide | grep api-new-c32
api-new-c32-5d6b57758c   0         0         0       12d   nginx        nginx:1-alpine   id=api-new-c32,pod-template-hash=5d6b57758c
api-new-c32-6444c8cfc4   0         0         0       12d   nginx        nginx:1-alpine   id=api-new-c32,pod-template-hash=6444c8cfc4
api-new-c32-6469f575fb   0         0         0       12d   nginx        nginx:1-alpine   id=api-new-c32,pod-template-hash=6469f575fb
api-new-c32-77c8857b45   3         3         3       12d   nginx        nginx:1-alpine   id=api-new-c32,pod-template-hash=77c8857b45
api-new-c32-785d9d6f74   0         0         0       12d   nginx        ngnix:1-alpine   id=api-new-c32,pod-template-hash=785d9d6f74
```

# Checks

- Container has correct image
- Deployment has 3 replicas
- Deployment has 3 up-to-date replicas
- Rollout has been made

