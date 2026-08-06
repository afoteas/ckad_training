# Tags
[Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes) [Configure a Pod to use storage](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/)

# Question

Solve this question on instance: `ssh ckad3250`

Create the following, all in *Namespace* `maple` (except the cluster-wide *PV*):

1. *PersistentVolume* `maple-project-mapleflower-pv`: capacity `2Gi`, accessMode `ReadWriteOnce`, hostPath `/Volumes/Data`, no storageClassName
2. *PersistentVolumeClaim* `maple-project-mapleflower-pvc`: request `2Gi`, accessMode `ReadWriteOnce`, no storageClassName. Should bind to the *PV*
3. *Deployment* `project-mapleflower`: image `httpd:2-alpine`, mount the volume at `/tmp/project-data`

# Answer


```sh
➜ ssh ckad3250

➜ candidate@ckad3250:~$ vim 12_pv.yaml
```

Find an example from [https://kubernetes.io/docs](https://kubernetes.io/docs) and alter it:

```yaml
# ckad3250:/home/candidate/12_pv.yaml
kind: PersistentVolume
apiVersion: v1
metadata:
 name: maple-project-mapleflower-pv
spec:
 capacity:
  storage: 2Gi
 accessModes:
  - ReadWriteOnce
 hostPath:
  path: "/Volumes/Data"
```

Then create it:

```sh
➜ candidate@ckad3250:~$ k -f 12_pv.yaml create
persistentvolume/maple-project-mapleflower-pv created
```

Next the *PersistentVolumeClaim*:

```sh
➜ candidate@ckad3250:~$ vim 12_pvc.yaml
```

Find an example from [https://kubernetes.io/docs](https://kubernetes.io/docs) and alter it:

```yaml
# ckad3250:/home/candidate/12_pvc.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: maple-project-mapleflower-pvc
  namespace: maple
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
     storage: 2Gi
```

Then create:

```sh
➜ candidate@ckad3250:~$ k -f 12_pvc.yaml create
persistentvolumeclaim/maple-project-mapleflower-pvc created
```

And check that both have the status Bound:

```sh
➜ candidate@ckad3250:~$ k -n maple get pv,pvc
NAME                                 CAPACITY   ACCESS MODES   ...  STATUS   CLAIM 
persistentvolume/...mapleflower-pv   2Gi        RWO            ...  Bound    ...er-pvc

NAME                                       STATUS   VOLUME                         CAPACITY
persistentvolumeclaim/...mapleflower-pvc   Bound    maple-project-mapleflower-pv   2Gi
```

Next we create a *Deployment* and mount that volume:

```sh
➜ candidate@ckad3250:~$ k -n maple create deploy project-mapleflower --image=httpd:2-alpine --dry-run=client -oyaml > 12_dep.yaml

➜ candidate@ckad3250:~$ vim 12_dep.yaml
```

Alter the YAML to mount the volume:

```yaml
# ckad3250:/home/candidate/12_dep.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: project-mapleflower
  name: project-mapleflower
  namespace: maple
spec:
  replicas: 1
  selector:
    matchLabels:
      app: project-mapleflower
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: project-mapleflower
    spec:
      volumes:                                      # add
      - name: data                                  # add
        persistentVolumeClaim:                      # add
          claimName: maple-project-mapleflower-pvc  # add
      containers:
      - image: httpd:2-alpine
        name: container
        volumeMounts:                               # add
        - name: data                                # add
          mountPath: /tmp/project-data              # add
```

```sh
➜ candidate@ckad3250:~$ k -f 12_dep.yaml create
deployment.apps/project-mapleflower created
```

We can confirm it's mounting correctly:

```sh
➜ candidate@ckad3250:~$ k -n maple describe pod project-mapleflower-d6887f7c5-pn5wv | grep -A2 Mounts:
    Mounts:
      /tmp/project-data from data (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-n2sjj (ro)
```

# Checks

- PersistentVolume exists
- PersistentVolume correctly defined
- PersistentVolumeClaim exists
- PersistentVolumeClaim correctly defined
- Deployment exists
- Deployment container mounts volume

