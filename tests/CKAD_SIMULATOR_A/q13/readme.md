# Tags

[Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes) [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes)

# Question

Solve this question on instance: `ssh ckad9043`

Team Moonpie needs more storage. Create a new *StorageClass* `moon-retain`:

1. *provisioner*: `moon-retainer`
2. *reclaimPolicy*: `Retain`

Then in *Namespace* `moon` create a *PersistentVolumeClaim* `moon-pvc-126` that uses it:

1. *storageClassName*: `moon-retain`
2. *accessModes*: `ReadWriteOnce`
3. storage request: `3Gi`

The provisioner `moon-retainer` will be created by another team, so the *PVC* will stay Pending. Write the event message explaining why into `/course/13/pvc-126-reason` on `ckad9043`.

# Answer


```bash
➜ ssh ckad9043

➜ candidate@ckad9043:~$ vim 13_sc.yaml
```

Head to [https://kubernetes.io/docs](https://kubernetes.io/docs), search for "storageclass" and alter the example code to this:


```yaml
# ckad9043:/home/candidate/13_sc.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: moon-retain
provisioner: moon-retainer
reclaimPolicy: Retain
```

```bash
➜ candidate@ckad9043:~$ k -f 13_sc.yaml create
storageclass.storage.k8s.io/moon-retain created
```

Now the same for the *PersistentVolumeClaim*, head to the docs, copy an example and transform it into:



```bash
➜ candidate@ckad9043:~$ vim 13_pvc.yaml
```

```yaml
# ckad9043:/home/candidate/13_pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: moon-pvc-126               # name as requested
  namespace: moon                  # important
spec:
  accessModes:
    - ReadWriteOnce                # RWO
  resources:
    requests:
      storage: 3Gi                 # size
  storageClassName: moon-retain    # uses our new storage class
```
```bash
➜ candidate@ckad9043:~$ k -f 13_pvc.yaml create
persistentvolumeclaim/moon-pvc-126 created
```

Next we check the status of the *PVC*:

```bash
➜ candidate@ckad9043:~$ k -n moon get pvc
NAME           STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
moon-pvc-126   Pending                                      moon-retain    2m57s


➜ candidate@ckad9043:~$ k -n moon describe pvc moon-pvc-126
Name:          moon-pvc-126
...
Status:        Pending
...
Events:
  Type    Reason                Age                  From                         Message
  ----    ------                ----                 ----                         -------
  Normal  ExternalProvisioning  4s (x19 over 4m28s)  persistentvolume-controller  Waiting for a volume to be created either by the external provisioner 'moon-retainer' or manually by the system administrator. If volume creation is delayed, please verify that the provisioner is running and correctly registered.
```

This confirms that the *PVC* waits for the provisioner `moon-retainer` to be created. Finally we copy or write the event message into the requested location:


```bash
➜ candidate@ckad9043:~$ cat /course/13/pvc-126-reason
Waiting for a volume to be created either by the external provisioner 'moon-retainer' or manually by the system administrator. If volume creation is delayed, please verify that the provisioner is running and correctly registered.
```


# Checks

- StorageClass exists
- StorageClass correctly defined
- PersistentVolumeClaim exists
- PersistentVolumeClaim correctly defined
- PersistentVolumeClaim status Pending
- File /course/13/pvc-126-reason valid

