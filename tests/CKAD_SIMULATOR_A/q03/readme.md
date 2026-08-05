# Tags

[Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job)

# Question

Solve this question on instance: `ssh ckad7326`

Create a *Job* template at `/course/3/job.yaml` in Namespace `neptune`:

1. Name `neb-new-job`, container name `neb-new-job-container`
2. Image `busybox:1`, command `sleep 2 && echo done`
3. 3 completions in total, 2 running in parallel
4. Pods are labelled `id: awesome-job`

Apply it and check the Job history.

# Answer

```bash
ssh ckad7326

candidate@ckad7326:~$ k -n neptune create job neb-new-job --image=busybox:1 --dry-run=client -oyaml -- sh -c "sleep 2 && echo done" > /course/3/job.yaml

candidate@ckad7326:~$ vim /course/3/job.yaml
```

Make the required changes in the YAML:

```yaml
# ckad7326:/course/3/job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  creationTimestamp: null
  name: neb-new-job
  namespace: neptune
spec:
  completions: 3                  # add
  parallelism: 2                  # add
  template:
    metadata:
      creationTimestamp: null
      labels:                     # add
        id: awesome-job           # add
    spec:
      containers:
      - command:
        - sh
        - -c
        - sleep 2 && echo done
        image: busybox:1
        name: neb-new-job-container   # update
        resources: {}
      restartPolicy: Never
status: {}
```

Then to create it:

```bash
➜ candidate@ckad7326:~$ k -f /course/3/job.yaml create
job.batch/neb-new-job created
```

Check Job and Pods, you should see two running in parallel at most but three in total. Mid-rollout we see one Pod completed, one still running, and the third just starting up, so at most two run in parallel:

```bash
➜ candidate@ckad7326:~$ k -n neptune get pod,job | grep neb-new-job
pod/neb-new-job-gm8sz              0/1     ContainerCreating   0          0s
pod/neb-new-job-jhq2g              0/1     Completed           0          10s
pod/neb-new-job-vf6ts              1/1     Running             0          10s

job.batch/neb-new-job   1/3           10s        11s
```

Once all three finish:

```bash
➜ candidate@ckad7326:~$ k -n neptune get pod,job | grep neb-new-job
pod/neb-new-job-gm8sz              0/1     Completed   0          12s
pod/neb-new-job-jhq2g              0/1     Completed   0          22s
pod/neb-new-job-vf6ts              0/1     Completed   0          22s

job.batch/neb-new-job   3/3           21s        23s
```

Check history:

```bash
➜ candidate@ckad7326:~$ k -n neptune describe job neb-new-job
...
Events:
  Type    Reason            Age    From            Message
  ----    ------            ----   ----            -------
  Normal  SuccessfulCreate  2m52s  job-controller  Created pod: neb-new-job-jhq2g
  Normal  SuccessfulCreate  2m52s  job-controller  Created pod: neb-new-job-vf6ts
  Normal  SuccessfulCreate  2m42s  job-controller  Created pod: neb-new-job-gm8sz
```

At the age column we can see that two Pods run parallel and the third one after that, just as it was required in the task.

# Checks

- Job created
- Job has succeeded three times
- Job has parallelism of two
- Job has single container
- Container has correct name
- Container has correct image

