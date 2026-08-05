# Tags

[Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers) [Configure Service Accounts for Pods](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account)

# Question

Solve this question on instance: `ssh ckad7326`

Team Neptune needs 3 Pods of image `httpd:2-alpine`, create a *Deployment* named `neptune-10ab` for this. The containers should be named `neptune-pod-10ab`. Each container should have a memory request of `20Mi` and a memory limit of `50Mi`.

Team Neptune has its own *ServiceAccount* `neptune-sa-v2` under which the Pods should run. The *Deployment* should be in Namespace `neptune`.

# Answer

``` bash
ssh ckad7326
candidate@ckad7326:~$ k -n neptune create deploy -h
Create a deployment with the specified name.

Aliases:
deployment, deploy

Examples:
...

candidate@ckad7326:~$ k -n neptune create deploy neptune-10ab --replicas=3 --image=httpd:2-alpine --dry-run=client -oyaml > 2.yaml

candidate@ckad7326:~$ vim 2.yaml
```

Now make the required changes:

``` yaml
# ckad7326:/home/candidate/2.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: neptune-10ab
  name: neptune-10ab
  namespace: neptune
spec:
  replicas: 3
  selector:
    matchLabels:
      app: neptune-10ab
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: neptune-10ab
    spec:
      serviceAccountName: neptune-sa-v2  # add
      containers:
      - image: httpd:2-alpine
        name: neptune-pod-10ab           # change
        resources:                       # add
          limits:                        # add
            memory: 50Mi                 # add
          requests:                      # add
            memory: 20Mi                 # add
status: {}
```

Because the Namespace is already set in the YAML we don't have to pass it to kubectl create:


``` bash
candidate@ckad7326:~$ k create -f 2.yaml
deployment.apps/neptune-10ab created
```

Verify all Pods are running:

``` bash
candidate@ckad7326:~$ k -n neptune get pod | grep neptune-10ab
neptune-10ab-7d4b8d45b-4nzj5   1/1     Running   0          57s
neptune-10ab-7d4b8d45b-lzwrf   1/1     Running   0          17s
neptune-10ab-7d4b8d45b-z5hcc   1/1     Running   0          17s
```

# Checks

- Deployment has 3 replicas
- Deployment has 3 ready replicas
- Deployment has single container
- Container has correct name
- Container has correct image
- Container has correct resource limits
- Container has correct resource requests
- Template has correct ServiceAccount