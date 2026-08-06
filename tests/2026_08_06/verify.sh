#!/usr/bin/env bash
# CKAD Simulation Exam 2026-08-06 — machine scoring
# Usage:
#   bash verify.sh       # every check, passed and failed, plus per-domain summary
#   bash verify.sh -q    # only the checks you failed
#
# Deliberately not using `set -e`: failing checks are the normal case here.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$HERE" || exit 1

DETAIL=all   # all | fail
case "${1:-}" in
  ""|-v|--verbose) DETAIL=all ;;
  -q|--quiet)      DETAIL=fail ;;
  *) echo "usage: bash verify.sh [-q|--quiet]" >&2; exit 2 ;;
esac

if ! kubectl get --raw /readyz >/dev/null 2>&1; then
  echo "!! Cluster unreachable — cannot score. See setup.sh for recovery steps." >&2
  exit 1
fi

RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BOLD=$'\e[1m'; DIM=$'\e[2m'; OFF=$'\e[0m'
if [[ ! -t 1 ]]; then RED=; GREEN=; YELLOW=; BOLD=; DIM=; OFF=; fi

declare -A DOM_EARNED DOM_MAX
DOMAINS=(design deploy config net obs)
declare -A DOM_LABEL=(
  [design]="Application Design & Build"
  [deploy]="Application Deployment"
  [config]="App Environment, Config & Security"
  [net]="Services & Networking"
  [obs]="Observability & Maintenance"
)
for d in "${DOMAINS[@]}"; do DOM_EARNED[$d]=0; DOM_MAX[$d]=0; done

TOTAL_EARNED=0   # hundredths of a percentage point
TOTAL_MAX=0
CUR_ID=""; CUR_TITLE=""; CUR_W=0; CUR_DOM=""
CHECKS=0; PASSED=0; DETAILS=()

qbegin() { CUR_ID="$1"; CUR_W="$2"; CUR_DOM="$3"; CUR_TITLE="$4"; CHECKS=0; PASSED=0; DETAILS=(); }

record() {
  local desc="$1" good="$2" info="$3"
  CHECKS=$((CHECKS + 1))
  if [[ "$good" == 1 ]]; then
    PASSED=$((PASSED + 1))
    DETAILS+=("1|${GREEN}  ok${OFF}  ${desc}")
  else
    DETAILS+=("0|${RED}  XX${OFF}  ${desc}${info:+  ${DIM}(${info})${OFF}}")
  fi
}

# want "<desc>" "<expected>" <kubectl args...>
want() {
  local desc="$1" exp="$2"; shift 2
  local got; got="$(kubectl "$@" 2>/dev/null)"
  [[ "$got" == "$exp" ]] && record "$desc" 1 "" || record "$desc" 0 "want '$exp', got '$got'"
}

# has "<desc>" "<substring>" <kubectl args...>
has() {
  local desc="$1" sub="$2"; shift 2
  local got; got="$(kubectl "$@" 2>/dev/null)"
  [[ "$got" == *"$sub"* ]] && record "$desc" 1 "" || record "$desc" 0 "want ~'$sub', got '$got'"
}

# ok "<desc>" '<shell expression>'
ok() {
  local desc="$1"; shift
  if eval "$*" >/dev/null 2>&1; then record "$desc" 1 ""; else record "$desc" 0 ""; fi
}

# podup "<desc>" <namespace> <pod>
# A pod stuck in CrashLoopBackOff still reports phase Running, so phase alone proves
# nothing — every container must also be ready.
podup() {
  local desc="$1" ns="$2" pod="$3" phase ready
  phase="$(kubectl -n "$ns" get pod "$pod" -o jsonpath='{.status.phase}' 2>/dev/null)"
  ready="$(kubectl -n "$ns" get pod "$pod" -o jsonpath='{.status.containerStatuses[*].ready}' 2>/dev/null)"
  if [[ "$phase" == "Running" && -n "$ready" && "$ready" != *false* ]]; then
    record "$desc" 1 ""
  else
    record "$desc" 0 "phase='$phase' ready='$ready'"
  fi
}

qend() {
  local earned=0
  (( CHECKS > 0 )) && earned=$(( CUR_W * 100 * PASSED / CHECKS ))
  TOTAL_EARNED=$(( TOTAL_EARNED + earned ))
  TOTAL_MAX=$(( TOTAL_MAX + CUR_W * 100 ))
  DOM_EARNED[$CUR_DOM]=$(( DOM_EARNED[$CUR_DOM] + earned ))
  DOM_MAX[$CUR_DOM]=$(( DOM_MAX[$CUR_DOM] + CUR_W * 100 ))

  local mark colour
  if (( PASSED == CHECKS )); then mark="PASS"; colour="$GREEN"
  elif (( PASSED == 0 ));    then mark="FAIL"; colour="$RED"
  else                            mark="PART"; colour="$YELLOW"; fi

  printf '%s%-4s%s  %-4s %-46s %2d/%-2d checks  %s%%\n' \
    "$colour" "$mark" "$OFF" "$CUR_ID" "$CUR_TITLE" "$PASSED" "$CHECKS" \
    "$(printf '%d.%02d' $((earned / 100)) $((earned % 100)))"

  local line flag text
  for line in "${DETAILS[@]}"; do
    flag="${line%%|*}"
    text="${line#*|}"
    [[ "$DETAIL" == fail && "$flag" == 1 ]] && continue
    printf '%s\n' "$text"
  done
}

echo
echo "${BOLD}CKAD Simulation Exam 2026-08-06 — scoring${OFF}"
echo "context: $(kubectl config current-context)"
echo

# ---------------------------------------------------------------- Design & Build

qbegin Q1 4 design "Job integrity-sweep"
want "completions = 6"                6   -n batch get job integrity-sweep -o jsonpath={.spec.completions}
want "parallelism = 3"                3   -n batch get job integrity-sweep -o jsonpath={.spec.parallelism}
want "backoffLimit = 2"               2   -n batch get job integrity-sweep -o jsonpath={.spec.backoffLimit}
want "activeDeadlineSeconds = 120"    120 -n batch get job integrity-sweep -o jsonpath={.spec.activeDeadlineSeconds}
want "ttlSecondsAfterFinished = 7200" 7200 -n batch get job integrity-sweep -o jsonpath={.spec.ttlSecondsAfterFinished}
want "restartPolicy = Never"          Never -n batch get job integrity-sweep -o jsonpath={.spec.template.spec.restartPolicy}
want "6 successful completions"       6   -n batch get job integrity-sweep -o jsonpath={.status.succeeded}
qend

qbegin Q2 6 design "Pod audit-stream (native sidecar)"
podup "pod is up" batch audit-stream
want "app is a regular container"     app     -n batch get pod audit-stream -o 'jsonpath={.spec.containers[?(@.name=="app")].name}'
want "shipper is an init container"   shipper -n batch get pod audit-stream -o 'jsonpath={.spec.initContainers[?(@.name=="shipper")].name}'
want "shipper restartPolicy = Always" Always  -n batch get pod audit-stream -o 'jsonpath={.spec.initContainers[?(@.name=="shipper")].restartPolicy}'
has  "shared volume is emptyDir"      "{" -n batch get pod audit-stream -o 'jsonpath={.spec.volumes[0].emptyDir}'
has  "app mounts /var/log/audit"      "/var/log/audit" -n batch get pod audit-stream -o 'jsonpath={.spec.containers[?(@.name=="app")].volumeMounts[*].mountPath}'
has  "shipper mounts /var/log/audit"  "/var/log/audit" -n batch get pod audit-stream -o 'jsonpath={.spec.initContainers[?(@.name=="shipper")].volumeMounts[*].mountPath}'
ok   "shipper emits the trail on stdout" '[ -n "$(kubectl -n batch logs audit-stream -c shipper --tail=5 2>/dev/null)" ]'
qend

qbegin Q3 5 design "PV/PVC archive + Pod archive-writer"
want "PV capacity 1Gi"                1Gi   get pv archive-pv -o jsonpath={.spec.capacity.storage}
has  "PV accessMode ReadWriteOnce"    ReadWriteOnce get pv archive-pv -o 'jsonpath={.spec.accessModes[*]}'
want "PV storageClassName manual"     manual get pv archive-pv -o jsonpath={.spec.storageClassName}
want "PV hostPath /mnt/archive"       /mnt/archive get pv archive-pv -o jsonpath={.spec.hostPath.path}
want "PVC is Bound"                   Bound -n storage get pvc archive-pvc -o jsonpath={.status.phase}
want "PVC requests 500Mi"             500Mi -n storage get pvc archive-pvc -o jsonpath={.spec.resources.requests.storage}
podup "archive-writer is up" storage archive-writer
has  "archive-writer mounts /var/archive" "/var/archive" -n storage get pod archive-writer -o 'jsonpath={.spec.containers[0].volumeMounts[*].mountPath}'
has  "archive-writer uses archive-pvc"    archive-pvc    -n storage get pod archive-writer -o 'jsonpath={.spec.volumes[*].persistentVolumeClaim.claimName}'
qend

qbegin Q4 5 design "CronJob report-gen"
want "schedule every 2 minutes"       "*/2 * * * *" -n batch get cj report-gen -o jsonpath={.spec.schedule}
want "concurrencyPolicy = Forbid"     Forbid -n batch get cj report-gen -o jsonpath={.spec.concurrencyPolicy}
want "startingDeadlineSeconds = 15"   15 -n batch get cj report-gen -o jsonpath={.spec.startingDeadlineSeconds}
want "job activeDeadlineSeconds = 30" 30 -n batch get cj report-gen -o jsonpath={.spec.jobTemplate.spec.activeDeadlineSeconds}
want "successfulJobsHistoryLimit = 2" 2 -n batch get cj report-gen -o jsonpath={.spec.successfulJobsHistoryLimit}
want "failedJobsHistoryLimit = 1"     1 -n batch get cj report-gen -o jsonpath={.spec.failedJobsHistoryLimit}
want "restartPolicy = OnFailure"      OnFailure -n batch get cj report-gen -o jsonpath={.spec.jobTemplate.spec.template.spec.restartPolicy}
qend

# ------------------------------------------------------------------ Deployment

qbegin Q5 6 deploy "Helm release frontdoor"
ok   "release frontdoor exists in release" 'helm status frontdoor -n release'
ok   "release is deployed"                 'helm list -n release -f "^frontdoor$" | grep -q deployed'
want "3 replicas desired"  3 -n release get deploy frontdoor-nginx -o jsonpath={.spec.replicas}
want "3 replicas ready"    3 -n release get deploy frontdoor-nginx -o jsonpath={.status.readyReplicas}
want "image nginx:1.27"    nginx:1.27 -n release get deploy frontdoor-nginx -o 'jsonpath={.spec.template.spec.containers[0].image}'
ok   "localchart/values.yaml left untouched" 'grep -q "replicaCount: 1" localchart/values.yaml && grep -q "image: nginx:1.25" localchart/values.yaml'
qend

qbegin Q6 7 deploy "Kustomize prod overlay"
ok   "overlay at answers/kustomize/prod"  '[ -f answers/kustomize/prod/kustomization.yaml ]'
ok   "deployment prod-api exists"         'kubectl -n release get deploy prod-api'
want "4 replicas desired"  4 -n release get deploy prod-api -o jsonpath={.spec.replicas}
want "4 replicas ready"    4 -n release get deploy prod-api -o jsonpath={.status.readyReplicas}
want "image nginx:1.27"    nginx:1.27 -n release get deploy prod-api -o 'jsonpath={.spec.template.spec.containers[0].image}'
want "label env=prod"      prod -n release get deploy prod-api -o 'jsonpath={.metadata.labels.env}'
qend

qbegin Q7 7 deploy "payments strategy + rollback"
want "maxSurge = 2"        2 -n release get deploy payments -o jsonpath={.spec.strategy.rollingUpdate.maxSurge}
want "maxUnavailable = 0"  0 -n release get deploy payments -o jsonpath={.spec.strategy.rollingUpdate.maxUnavailable}
want "back on nginx:1.26"  nginx:1.26 -n release get deploy payments -o 'jsonpath={.spec.template.spec.containers[0].image}'
want "3 replicas ready"    3 -n release get deploy payments -o jsonpath={.status.readyReplicas}
want "3 replicas updated"  3 -n release get deploy payments -o jsonpath={.status.updatedReplicas}
qend

# ------------------------------------------------------- Config & Security

qbegin Q8 5 config "ConfigMap app-settings + settings-reader"
want "log_level=warn"          warn        -n settings get cm app-settings -o jsonpath={.data.log_level}
want "region=eu-west-1"        eu-west-1   -n settings get cm app-settings -o jsonpath={.data.region}
want "feature_flags"           beta,metrics -n settings get cm app-settings -o jsonpath={.data.feature_flags}
podup "pod is up" settings settings-reader
want "envFrom whole ConfigMap" app-settings -n settings get pod settings-reader -o 'jsonpath={.spec.containers[0].envFrom[0].configMapRef.name}'
want "volume from ConfigMap"   app-settings -n settings get pod settings-reader -o 'jsonpath={.spec.volumes[0].configMap.name}'
has  "mounted at /etc/app-settings" "/etc/app-settings" -n settings get pod settings-reader -o 'jsonpath={.spec.containers[0].volumeMounts[*].mountPath}'
qend

qbegin Q9 4 config "Secret api-creds + creds-user"
ok   "secret key username=svc-portal" '[ "$(kubectl -n settings get secret api-creds -o jsonpath={.data.username} | base64 -d)" = "svc-portal" ]'
ok   "secret key password=Tr0ub4dor"  '[ "$(kubectl -n settings get secret api-creds -o jsonpath={.data.password} | base64 -d)" = "Tr0ub4dor" ]'
podup "pod is up" settings creds-user
want "APP_USER <- api-creds/username" "api-creds username" -n settings get pod creds-user -o 'jsonpath={.spec.containers[0].env[?(@.name=="APP_USER")].valueFrom.secretKeyRef.name} {.spec.containers[0].env[?(@.name=="APP_USER")].valueFrom.secretKeyRef.key}'
want "APP_PASS <- api-creds/password" "api-creds password" -n settings get pod creds-user -o 'jsonpath={.spec.containers[0].env[?(@.name=="APP_PASS")].valueFrom.secretKeyRef.name} {.spec.containers[0].env[?(@.name=="APP_PASS")].valueFrom.secretKeyRef.key}'
want "SA token not mounted" false    -n settings get pod creds-user -o jsonpath={.spec.automountServiceAccountToken}
qend

qbegin Q10 6 config "RBAC deploy-bot"
ok   "ServiceAccount deploy-bot exists"  'kubectl -n access get sa deploy-bot'
ok   "Role deploy-manager exists"        'kubectl -n access get role deploy-manager'
ok   "RoleBinding deploy-bot-binding exists" 'kubectl -n access get rolebinding deploy-bot-binding'
want "pod bot runs as deploy-bot" deploy-bot -n access get pod bot -o jsonpath={.spec.serviceAccountName}
podup "pod bot is up" access bot
want "can create deployments"     yes -n access auth can-i create deployments --as=system:serviceaccount:access:deploy-bot
want "can watch deployments"      yes -n access auth can-i watch deployments --as=system:serviceaccount:access:deploy-bot
want "can patch deployments"      yes -n access auth can-i patch deployments --as=system:serviceaccount:access:deploy-bot
want "can list pods"              yes -n access auth can-i list pods --as=system:serviceaccount:access:deploy-bot
want "cannot delete deployments"  no  -n access auth can-i delete deployments --as=system:serviceaccount:access:deploy-bot
want "cannot create pods"         no  -n access auth can-i create pods --as=system:serviceaccount:access:deploy-bot
want "no reach into other namespaces" no -n edge auth can-i list deployments --as=system:serviceaccount:access:deploy-bot
qend

qbegin Q11 5 config "Hardened pod vault-agent"
podup "pod is up" hardened vault-agent
has  "runAsUser 3000"  3000 -n hardened get pod vault-agent -o 'jsonpath={.spec.securityContext.runAsUser} {.spec.containers[0].securityContext.runAsUser}'
has  "runAsGroup 4000" 4000 -n hardened get pod vault-agent -o 'jsonpath={.spec.securityContext.runAsGroup} {.spec.containers[0].securityContext.runAsGroup}'
want "fsGroup 5000"    5000 -n hardened get pod vault-agent -o jsonpath={.spec.securityContext.fsGroup}
want "allowPrivilegeEscalation false" false -n hardened get pod vault-agent -o 'jsonpath={.spec.containers[0].securityContext.allowPrivilegeEscalation}'
want "readOnlyRootFilesystem true"    true  -n hardened get pod vault-agent -o 'jsonpath={.spec.containers[0].securityContext.readOnlyRootFilesystem}'
has  "capabilities drop ALL"          ALL   -n hardened get pod vault-agent -o 'jsonpath={.spec.containers[0].securityContext.capabilities.drop[*]}'
has  "writable emptyDir at /data"     "/data" -n hardened get pod vault-agent -o 'jsonpath={.spec.containers[0].volumeMounts[*].mountPath}'
ok   "answers/q11-id.txt shows uid=3000" 'grep -q "uid=3000" answers/q11-id.txt'
qend

qbegin Q12 5 config "ResourceQuota team-quota + sizer"
want "quota pods = 5"           5    -n capacity get quota team-quota -o 'jsonpath={.spec.hard.pods}'
want "quota requests.cpu = 1"   1    -n capacity get quota team-quota -o 'jsonpath={.spec.hard.requests\.cpu}'
want "quota requests.memory 1Gi" 1Gi -n capacity get quota team-quota -o 'jsonpath={.spec.hard.requests\.memory}'
want "quota limits.cpu = 2"     2    -n capacity get quota team-quota -o 'jsonpath={.spec.hard.limits\.cpu}'
want "quota limits.memory 2Gi"  2Gi  -n capacity get quota team-quota -o 'jsonpath={.spec.hard.limits\.memory}'
want "sizer 2 replicas ready"   2    -n capacity get deploy sizer -o jsonpath={.status.readyReplicas}
want "requests 200m/128Mi"      "200m 128Mi" -n capacity get deploy sizer -o 'jsonpath={.spec.template.spec.containers[0].resources.requests.cpu} {.spec.template.spec.containers[0].resources.requests.memory}'
want "limits 400m/256Mi"        "400m 256Mi" -n capacity get deploy sizer -o 'jsonpath={.spec.template.spec.containers[0].resources.limits.cpu} {.spec.template.spec.containers[0].resources.limits.memory}'
qend

# -------------------------------------------------------- Services & Networking

qbegin Q13 4 net "Service web-tier-svc"
want "type ClusterIP"  ClusterIP -n edge get svc web-tier-svc -o jsonpath={.spec.type}
want "port 8080"       8080      -n edge get svc web-tier-svc -o 'jsonpath={.spec.ports[0].port}'
want "targetPort 80"   80        -n edge get svc web-tier-svc -o 'jsonpath={.spec.ports[0].targetPort}'
ok   "2 endpoints backing the Service" \
     '[ $(kubectl -n edge get endpointslice -l kubernetes.io/service-name=web-tier-svc -o jsonpath="{.items[*].endpoints[*].addresses[0]}" | wc -w) -ge 2 ]'
ok   "answers/q13-curl.txt shows the nginx page" 'grep -qi "welcome to nginx" answers/q13-curl.txt'
qend

qbegin Q14 7 net "Ingress shop"
want "ingressClassName nginx" nginx        -n edge get ing shop -o jsonpath={.spec.ingressClassName}
want "host shop.internal"     shop.internal -n edge get ing shop -o 'jsonpath={.spec.rules[0].host}'
want "/api -> shop-api"       shop-api -n edge get ing shop -o 'jsonpath={.spec.rules[0].http.paths[?(@.path=="/api")].backend.service.name}'
want "/api port 8080"         8080     -n edge get ing shop -o 'jsonpath={.spec.rules[0].http.paths[?(@.path=="/api")].backend.service.port.number}'
want "/api pathType Prefix"   Prefix   -n edge get ing shop -o 'jsonpath={.spec.rules[0].http.paths[?(@.path=="/api")].pathType}'
want "/ -> shop-ui"           shop-ui  -n edge get ing shop -o 'jsonpath={.spec.rules[0].http.paths[?(@.path=="/")].backend.service.name}'
want "/ port 80"              80       -n edge get ing shop -o 'jsonpath={.spec.rules[0].http.paths[?(@.path=="/")].backend.service.port.number}'
want "/ pathType Prefix"      Prefix   -n edge get ing shop -o 'jsonpath={.spec.rules[0].http.paths[?(@.path=="/")].pathType}'
qend

qbegin Q15 9 net "NetworkPolicies in mesh"
ok   "mesh-default-deny exists"        'kubectl -n mesh get netpol mesh-default-deny'
want "deny selects every pod"     "{}" -n mesh get netpol mesh-default-deny -o 'jsonpath={.spec.podSelector}'
want "deny policyTypes = Ingress" Ingress -n mesh get netpol mesh-default-deny -o 'jsonpath={.spec.policyTypes[*]}'
want "deny has no allow rules"    "Ingress|" -n mesh get netpol mesh-default-deny -o 'jsonpath={.spec.policyTypes[*]}|{.spec.ingress[*]}'
ok   "mesh-allow-api exists"           'kubectl -n mesh get netpol mesh-allow-api'
want "allow targets app=api"      api     -n mesh get netpol mesh-allow-api -o 'jsonpath={.spec.podSelector.matchLabels.app}'
want "allow port 8080/TCP"        "8080 TCP" -n mesh get netpol mesh-allow-api -o 'jsonpath={.spec.ingress[0].ports[0].port} {.spec.ingress[0].ports[0].protocol}'
want "two separate from sources"  "XX"    -n mesh get netpol mesh-allow-api -o 'jsonpath={range .spec.ingress[0].from[*]}X{end}'
want "from pods tier=frontend"    frontend -n mesh get netpol mesh-allow-api -o 'jsonpath={.spec.ingress[0].from[*].podSelector.matchLabels.tier}'
want "from namespaces team=ops"   ops      -n mesh get netpol mesh-allow-api -o 'jsonpath={.spec.ingress[0].from[*].namespaceSelector.matchLabels.team}'
qend

# ------------------------------------------------- Observability & Maintenance

qbegin Q16 8 obs "Probes on Deployment catalog"
want "startup httpGet / :80"   "/ 80" -n triage get deploy catalog -o 'jsonpath={.spec.template.spec.containers[0].startupProbe.httpGet.path} {.spec.template.spec.containers[0].startupProbe.httpGet.port}'
want "startup periodSeconds 2" 2  -n triage get deploy catalog -o 'jsonpath={.spec.template.spec.containers[0].startupProbe.periodSeconds}'
want "startup failureThreshold 30" 30 -n triage get deploy catalog -o 'jsonpath={.spec.template.spec.containers[0].startupProbe.failureThreshold}'
want "readiness httpGet / :80" "/ 80" -n triage get deploy catalog -o 'jsonpath={.spec.template.spec.containers[0].readinessProbe.httpGet.path} {.spec.template.spec.containers[0].readinessProbe.httpGet.port}'
want "readiness initialDelay 3 / period 5" "3 5" -n triage get deploy catalog -o 'jsonpath={.spec.template.spec.containers[0].readinessProbe.initialDelaySeconds} {.spec.template.spec.containers[0].readinessProbe.periodSeconds}'
has  "liveness runs a command"  "index.html" -n triage get deploy catalog -o 'jsonpath={.spec.template.spec.containers[0].livenessProbe.exec.command[*]}'
want "liveness periodSeconds 10" 10 -n triage get deploy catalog -o 'jsonpath={.spec.template.spec.containers[0].livenessProbe.periodSeconds}'
want "2 replicas ready"          2  -n triage get deploy catalog -o jsonpath={.status.readyReplicas}
qend

qbegin Q17 7 obs "Triage alpha / beta / gamma"
podup "alpha is up" triage alpha
ok   "beta is healthy" \
     '[ "$(kubectl -n triage get pod beta -o jsonpath={.status.phase})" = "Succeeded" ] ||
      [ "$(kubectl -n triage get pod beta -o jsonpath={.status.containerStatuses[0].ready})" = "true" ]'
podup "gamma is up" triage gamma
ok   "q17.txt has three lines"        '[ $(grep -c . answers/q17.txt) -ge 3 ]'
ok   "alpha reason: image pull"       'grep -i "^alpha" answers/q17.txt | grep -Eqi "ImagePullBackOff|ErrImagePull"'
ok   "beta reason: CrashLoopBackOff"  'grep -i "^beta" answers/q17.txt | grep -qi "CrashLoopBackOff"'
ok   "gamma reason: config error"     'grep -i "^gamma" answers/q17.txt | grep -qi "CreateContainerConfigError"'
qend

# ------------------------------------------------------------------- summary

pct() { printf '%d.%02d' $(( $1 / 100 )) $(( $1 % 100 )); }

echo
echo "${BOLD}Per domain${OFF}"
for d in "${DOMAINS[@]}"; do
  local_share=0
  (( DOM_MAX[$d] > 0 )) && local_share=$(( DOM_EARNED[$d] * 100 / DOM_MAX[$d] ))
  printf '  %-36s %5s / %-5s  (%d%% of domain)\n' \
    "${DOM_LABEL[$d]}" "$(pct "${DOM_EARNED[$d]}")" "$(pct "${DOM_MAX[$d]}")" "$local_share"
done

echo
FINAL=$(pct "$TOTAL_EARNED")
if (( TOTAL_EARNED * 100 >= TOTAL_MAX * 66 )); then
  echo "${BOLD}${GREEN}TOTAL ${FINAL}% — PASS${OFF} (threshold 66%)"
else
  echo "${BOLD}${RED}TOTAL ${FINAL}% — FAIL${OFF} (threshold 66%)"
fi
echo
echo "${DIM}Run with -q to show only the checks you failed.${OFF}"
