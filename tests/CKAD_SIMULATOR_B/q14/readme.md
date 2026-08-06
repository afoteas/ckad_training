# Tags

[Secrets](https://kubernetes.io/docs/concepts/configuration/secret)

# Question

Solve this question on instance: `ssh ckad1695`

 

Modify the existing *Pod* `secret-handler` in *Namespace* `willow` (YAML at `/course/14/secret-handler.yaml`). Save your changes under `/course/14/secret-handler-new.yaml` on `ckad1695`.

1. Create *Secret* `secret1` with `user=test` and `pass=pwd`. Expose its values in the *Pod* as env vars `SECRET1_USER` and `SECRET1_PASS`
2. Create *Secret* `secret2` from `/course/14/secret2.yaml` and mount it in the *Pod* at `/tmp/secret2`

Both *Secrets* should only exist in *Namespace* `willow`.

# Answer


```sh
➜ ssh ckad1695

➜ candidate@ckad1695:~$ k -n willow get pod
NAME             READY   STATUS    RESTARTS   AGE
secret-handler   1/1     Running   0          10m

➜ candidate@ckad1695:~$ k -n willow create secret -h
...
Available Commands:
  docker-registry   Create a secret for use with a Docker registry
  generic           Create a secret from a local file, directory, or literal value
  tls               Create a TLS secret

Usage:
  kubectl create secret (docker-registry | generic | tls) [options]
...

➜ candidate@ckad1695:~$ k -n willow create secret generic -h
...
Examples:
...
  # Create a new secret named my-secret with key1=supersecret and key2=topsecret
  kubectl create secret generic my-secret --from-literal=key1=supersecret --from-literal=key2=topsecret
...
```

The last command would generate this YAML:

```yaml
# kubectl -n willow create secret generic secret1 --from-literal user=test --from-literal pass=pwd -oyaml --dry-run=client
apiVersion: v1
data:
  pass: cHdk
  user: dGVzdA==
kind: Secret
metadata:
  name: secret1
  namespace: willow
```

Looks good, so now we create it for real (without `--dry-run`):

```sh
➜ candidate@ckad1695:~$ k -n willow create secret generic secret1 --from-literal user=test --from-literal pass=pwd
secret/secret1 created
```

Next we create the second *Secret* from the given location, making sure it'll be created in *Namespace* `willow`:

```sh
➜ candidate@ckad1695:~$ k -n willow -f /course/14/secret2.yaml create
secret/secret2 created

➜ candidate@ckad1695:~$ k -n willow get secret
NAME                  TYPE                                  DATA   AGE
default-token-rvzcf   kubernetes.io/service-account-token   3      66m
secret1               Opaque                                2      4m3s
secret2               Opaque                                1      8s
```

We will now edit the *Pod* YAML:

```sh
➜ candidate@ckad1695:~$ cp /course/14/secret-handler.yaml /course/14/secret-handler-new.yaml

➜ candidate@ckad1695:~$ vim /course/14/secret-handler-new.yaml
```

Add the following to the YAML:

```yaml
# ckad1695:/course/14/secret-handler-new.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    id: secret-handler
    uuid: 1428721e-8d1c-4c09-b5d6-afd79200c56a
    red_ident: 9cf7a7c0-fdb2-4c35-9c13-c2a0bb52b4a9
    type: automatic
  name: secret-handler
  namespace: willow
spec:
  volumes:
  - name: cache-volume1
    emptyDir: {}
  - name: cache-volume2
    emptyDir: {}
  - name: cache-volume3
    emptyDir: {}
  - name: secret2-volume              # add
    secret:                           # add
      secretName: secret2             # add
  containers:
  - name: secret-handler
    image: bash:5
    args: ['bash', '-c', 'sleep 2d']
    volumeMounts:
    - mountPath: /cache1
      name: cache-volume1
    - mountPath: /cache2
      name: cache-volume2
    - mountPath: /cache3
      name: cache-volume3
    - name: secret2-volume            # add
      mountPath: /tmp/secret2         # add
    env:
    - name: SECRET_KEY_1
      value: ">8$kH#kj..i8}HImQd{"
    - name: SECRET_KEY_2
      value: "IO=a4L/XkRdvN8jM=Y+"
    - name: SECRET_KEY_3
      value: "-7PA0_Z]>{pwa43r)__"
    - name: SECRET1_USER              # add
      valueFrom:                      # add
        secretKeyRef:                 # add
          name: secret1               # add
          key: user                   # add
    - name: SECRET1_PASS              # add
      valueFrom:                      # add
        secretKeyRef:                 # add
          name: secret1               # add
          key: pass                   # add
```

There is also the possibility to import all keys from a *Secret* as env variables at once, though the env variable names will then be the same as in the *Secret*, which doesn't work for the requirements here:

```yaml
  containers:
  - name: secret-handler
...
    envFrom:
    - secretRef:        # also works for configMapRef
        name: secret1
```

Then we apply the changes:

```sh
➜ candidate@ckad1695:~$ k -f /course/14/secret-handler.yaml delete --force --grace-period=0
pod "secret-handler" force deleted

➜ candidate@ckad1695:~$ k -f /course/14/secret-handler-new.yaml create
pod/secret-handler created
```

Instead of running delete and create we can also use recreate:

```sh
➜ candidate@ckad1695:~$ k -f /course/14/secret-handler-new.yaml replace --force --grace-period=0
pod "secret-handler" deleted
pod/secret-handler replaced
```

It was not requested directly, but you should always confirm it's working:

```sh
➜ candidate@ckad1695:~$ k -n willow exec secret-handler -- env | grep SECRET1
SECRET1_USER=test
SECRET1_PASS=pwd

➜ candidate@ckad1695:~$ k -n willow exec secret-handler -- find /tmp/secret2
/tmp/secret2
/tmp/secret2/..data
/tmp/secret2/key
/tmp/secret2/..2019_09_11_09_03_08.147048594
/tmp/secret2/..2019_09_11_09_03_08.147048594/key

➜ candidate@ckad1695:~$ k -n willow exec secret-handler -- cat /tmp/secret2/key
12345678
```

# Checks

- Secret secret1 exists
- Secret secret1 correctly defined
- Secret secret2 exists
- Pod has secret2 volume
- Pod container mounts secret2 volume
- Pod container ready
- Pod container has secret1 envs
- File /course/14/secret-handler-new.yaml exists

