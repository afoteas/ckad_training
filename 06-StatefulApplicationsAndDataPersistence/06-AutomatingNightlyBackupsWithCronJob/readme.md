# Automating Nightly Backups with CronJob

This lesson demonstrates a scheduled PostgreSQL backup pipeline using Kubernetes CronJobs.

## End-to-End Flow

1. Deploy PostgreSQL (secret + PVC + service + deployment)
2. Insert test data
3. Create backup PVC (`backup-pvc`)
4. Create CronJob that runs `pg_dump` and writes SQL files to backup storage
5. Verify Jobs, pods, and logs

## Deploy Database and Seed Test Data

```bash
kubectl apply -f postgres.yaml
kubectl get pods -l app=postgres -w
kubectl exec -it deployment/postgres -- psql -U postgres -d testdb -c "CREATE TABLE users (id serial primary key, name text, created_at timestamptz default now());"
kubectl exec -it deployment/postgres -- psql -U postgres -d testdb -c "INSERT INTO users (name) VALUES ('Alice'),('Bob'),('Charlie');"
kubectl exec -it deployment/postgres -- psql -U postgres -d testdb -c "SELECT * FROM users;"
```

## Create Backup Storage and CronJob

```bash
kubectl apply -f backup-pvc.yaml
kubectl apply -f backup-cronjob.yaml
kubectl get cronjobs
kubectl get jobs -w
```

## Validate Backup Execution

```bash
kubectl get pods -l job-name
kubectl logs -l job-name --tail=50
```

## Manually Trigger a Backup from CronJob Template

```bash
kubectl create job --from=cronjob/postgres-backup manual-backup-1
```

## Production Notes

- store backups off-cluster (S3/GCS/Azure Blob)
- keep short on-cluster retention
- schedule at low-traffic windows
- monitor job success/failure and backup age

## CKAD Tips

- The examinable core is the CronJob, not `pg_dump`: focus on `schedule`, `jobTemplate`, and `concurrencyPolicy`.
- Force an immediate run for testing with `kubectl create job --from=cronjob/<name> <job-name>` instead of waiting for the schedule.
- Inspect results with `kubectl get jobs`, `kubectl get pods -l job-name=<job>`, and `kubectl logs -l job-name=<job>`.
- Mount the backup PVC into the Job pod and pull DB credentials from a Secret (`envFrom` or `secretKeyRef`).
- Prune old runs with `successfulJobsHistoryLimit` / `failedJobsHistoryLimit`.

## Key Takeaway

A CronJob turns a scheduled command (here `pg_dump`) into recurring Jobs that write to persistent storage; for CKAD, master the CronJob mechanics and the `--from=cronjob` manual trigger while treating the backup tooling itself as real-world context.
