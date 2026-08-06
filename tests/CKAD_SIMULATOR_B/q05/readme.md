# Tags

[CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs) [Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context)

# Question

Solve this question on instance: `ssh ckad1695`

Team Aspen needs a periodic heartbeat in *Namespace* `aspen`. Create a *CronJob* `aspen-beat`:

- Runs every 2 minutes
- Container name `beat` with image `bash:5`
- Container command `sh -c 'echo "beat $(date)"'`

Security Context *Pod* level:

- `runAsNonRoot: true`
- `runAsUser: 1000`

Security Context container level:

- `allowPrivilegeEscalation: false`
- `readOnlyRootFilesystem: true`

# Answer

*securityContext Pod-level* `spec.securityContext`: applies to every container in the *Pod*. Holds fields like `runAsUser`, `runAsNonRoot`, `fsGroup`.

*securityContext Container-level* `spec.containers[].securityContext`: overrides the *Pod* setting for that one container. Holds container-only fields like `allowPrivilegeEscalation`, `readOnlyRootFilesystem`, `capabilities`.


###### **Generate *CronJob* YAML**

We can find helpful examples via `kubectl` and we can look into the K8s Docs for the correct cronjob schedule:


```sh
➜ ssh ckad1695

➜ candidate@ckad1695:~$ k -n aspen create cronjob -h
Create a cron job with the specified name.

Aliases:
cronjob, cj

Examples:
  # Create a cron job
  kubectl create cronjob my-job --image=busybox --schedule="*/1 * * * *"
  
  # Create a cron job with a command
  kubectl create cronjob my-job --image=busybox --schedule="*/1 * * * *" -- date


Options:
    --allow-missing-template-keys=true:
        If true, ignore any errors in templates when a field or map key is missing in the template. Only applies to
        golang and jsonpath output formats.


    --dry-run='none':
        Must be "none", "server", or "client". If client strategy, only print the object that would be sent, without
        sending it. If server strategy, submit server-side request without persisting the resource.
...
```

Now we can generate the YAML to then adjust:

```sh
➜ candidate@ckad1695:~$ k -n aspen create cronjob aspen-beat \
    --image=bash:5 --schedule="*/2 * * * *" \
    --dry-run=client -oyaml -- sh -c 'echo "beat $(date)"' > 5.yaml

➜ candidate@ckad1695:~$ vim 5.yaml
```

 

###### **Update *CronJob* YAML**

Set the container name to `beat` and add both *SecurityContexts*:

```yaml
# ckad1695:/home/candidate/5.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: aspen-beat
  namespace: aspen
spec:
  jobTemplate:
    metadata:
      name: aspen-beat
    spec:
      template:
        metadata: {}
        spec:
          securityContext:                    # add Pod securityContext 
            runAsNonRoot: true                # add
            runAsUser: 1000                   # add
          containers:
          - command:
            - sh
            - -c
            - echo "beat $(date)"
            image: bash:5
            name: beat                        # change
            resources: {}
            securityContext:                  # add container securityContext
              allowPrivilegeEscalation: false # add
              readOnlyRootFilesystem: true    # add
          restartPolicy: OnFailure
  schedule: '*/2 * * * *'
```

Apply:

```sh
➜ candidate@ckad1695:~$ k apply -f 5.yaml
cronjob.batch/aspen-beat created
```

###### **Verify execution**

If we wait for up to 2 minutes we will see the first execution. A *CronJob* will create a *Job* which will create a *Pod*:

```sh
➜ candidate@ckad1695:~$ k -n aspen get cronjob,job,pod
NAME                       SCHEDULE      ...   LAST SCHEDULE   AGE
cronjob.batch/aspen-beat   */2 * * * *   ...   92s             2m28s

NAME                            STATUS     COMPLETIONS   DURATION   AGE
job.batch/aspen-beat-29680700   Complete   1/1           6s         92s

NAME                            READY   STATUS      RESTARTS   AGE
pod/aspen-beat-29680700-l9hcz   0/1     Completed   0          92s
```

Check the log line by looking at the *Pod* logs:

```sh
➜ candidate@ckad1695:~$ k -n aspen logs aspen-beat-29680700-l9hcz
beat Sun Jun  7 14:20:02 UTC 2026
```

> ℹ️ To trigger a *Job* immediately without waiting for the next schedule, create one from the *CronJob*:


```sh
➜ candidate@ckad1695:~$ k -n aspen create job aspen-beat-now --from=cronjob/aspen-beat
job.batch/aspen-beat-now created
```

# Checks

- CronJob aspen-beat created with correct schedule
- Container named beat with correct image
- Pod securityContext sets runAsNonRoot and runAsUser
- Container securityContext sets allowPrivilegeEscalation and readOnlyRootFilesystem
- At least one Job has succeeded

