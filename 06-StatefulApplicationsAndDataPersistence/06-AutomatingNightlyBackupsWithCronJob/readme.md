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
