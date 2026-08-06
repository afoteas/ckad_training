# Tags
[Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels) [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap)

# Question

Solve this question on instance: `ssh ckad1695`

Some manual *ConfigMap* housekeeping is up:

1. In *Namespace* `pine-project1`, count the *ConfigMaps* with label `purpose=cache` and write that number to `/course/1/cf-count`
2. In *Namespace* `pine-project2`, delete all *ConfigMaps* with label `purpose=expired`

# Answer

###### **Count *ConfigMaps***

There are a bunch of *ConfigMaps* with labels:

```bash
➜ ssh ckad1695

➜ candidate@ckad1695:~$ k -n pine-project1 get cm --show-labels
NAME               DATA   AGE   LABELS
cf-0a1b2e          1      51s   purpose=app-config
cf-0d1e2f          1      51s   purpose=cache
cf-12abcd          1      51s   purpose=cache
cf-1a3b5d          1      51s   purpose=cache
cf-1f2e3d          1      51s   purpose=feature-flags
cf-2d3e4f          1      51s   purpose=cache
cf-2f3a4b          1      51s   purpose=archive
cf-3a4b5c          1      51s   purpose=cache
cf-3c4d5b          1      51s   purpose=app-config
cf-4f5e6d          1      51s   purpose=feature-flags
cf-5a6b7c          1      51s   purpose=cache
cf-5d6e7c          1      51s   <none>
cf-6d7e8f          1      51s   purpose=cache
cf-6f7a8b          1      51s   purpose=app-config
cf-7a8b9c          1      51s   purpose=cache
cf-7d9e1b          1      51s   purpose=cache
cf-7f8e9d          1      51s   purpose=feature-flags
cf-8a9b0c          1      51s   <none>
cf-8d9e0f          1      51s   purpose=cache
cf-9a0b1c          1      51s   purpose=cache
cf-9c0d1e          1      51s   purpose=archive
cf-a1b2c3          1      51s   purpose=cache
cf-bcdef0          1      51s   purpose=cache
cf-d4e5f6          1      51s   purpose=cache
kube-root-ca.crt   1      51s   <none>
```

We can filter by label:

```bash
➜ candidate@ckad1695:~$ k -n pine-project1 get cm -l purpose=cache
NAME        DATA   AGE
cf-0d1e2f   1      2m31s
cf-12abcd   1      2m31s
cf-1a3b5d   1      2m31s
cf-2d3e4f   1      2m31s
cf-3a4b5c   1      2m31s
cf-5a6b7c   1      2m31s
cf-6d7e8f   1      2m31s
cf-7a8b9c   1      2m31s
cf-7d9e1b   1      2m31s
cf-8d9e0f   1      2m31s
cf-9a0b1c   1      2m31s
cf-a1b2c3   1      2m31s
cf-bcdef0   1      2m31s
cf-d4e5f6   1      2m31s
```

And we can use `wc -l` for counting:

```bash
➜ candidate@ckad1695:~$ k -n pine-project1 get cm -l purpose=cache | wc -l
15
```

Now we just **need to subtract one** for the header, or we can even use `--no-headers`:

```bash
➜ candidate@ckad1695:~$ k -n pine-project1 get cm -l purpose=cache --no-headers | wc -l > /course/1/cf-count

➜ candidate@ckad1695:~$ cat /course/1/cf-count
14
```

###### **Delete *ConfigMaps***

It's possible to delete using a label selector:

```bash
➜ candidate@ckad1695:~$ k -n pine-project2 get cm -l purpose=expired
NAME        DATA   AGE
cf-e0e167   1      6m13s
cf-eaeb01   1      6m13s
cf-eced23   1      6m13s
cf-eeef45   1      6m13s

➜ candidate@ckad1695:~$ k -n pine-project2 delete cm -l purpose=expired
configmap "cf-e0e167" deleted from pine-project2 namespace
configmap "cf-eaeb01" deleted from pine-project2 namespace
configmap "cf-eced23" deleted from pine-project2 namespace
configmap "cf-eeef45" deleted from pine-project2 namespace

➜ candidate@ckad1695:~$ k -n pine-project2 get cm -l purpose=expired
No resources found in pine-project2 namespace.
```

(Optional) verify the *ConfigMaps* with other labels are still there:

```bash
➜ candidate@ckad1695:~$ k -n pine-project2 get cm --show-labels
NAME               DATA   AGE     LABELS
cf-001122          1      6m35s   purpose=app-config
cf-334455          1      6m35s   <none>
cf-aabb01          1      6m35s   purpose=cache
cf-ccdd23          1      6m35s   purpose=feature-flags
cf-eeff45          1      6m35s   purpose=feature-flags
kube-root-ca.crt   1      6m36s   <none>
```

# Checks

- File /course/1/cf-count contains correct count
- All purpose=expired ConfigMaps deleted in pine-project2
- Non-expired ConfigMaps in pine-project2 still present

