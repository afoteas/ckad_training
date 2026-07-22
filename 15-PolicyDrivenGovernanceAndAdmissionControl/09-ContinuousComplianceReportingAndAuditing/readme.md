# Continuous Compliance Reporting and Auditing

Admission controllers only check resources when they are **created or updated** — they do not re-evaluate what already exists. Over time clusters **drift** from their intended state. Continuous compliance closes that gap with ongoing auditing.

For admission-time enforcement, see [03-OPAGatekeeperArchitectureAndConstraints](../03-OPAGatekeeperArchitectureAndConstraints/readme.md) and [05-KyvernoPolicyLanguageAndCapabilities](../05-KyvernoPolicyLanguageAndCapabilities/readme.md).

## Why Continuous Compliance

As clusters evolve — new workloads, updated configs, removed resources — the running state diverges from what you intended. Regulated organizations need ongoing checks so workloads remain secure, compliant, and correctly configured weeks or months after deployment.

The problem: admission controllers help only at creation. We need a way to **audit the cluster as it runs**. Continuous auditing fills this gap after admission enforcement has done its job.

## Gatekeeper Audit

Gatekeeper's audit mechanism periodically scans **already-deployed** resources and evaluates them against your constraints:

- Runs on a schedule.
- Flags resources that violate a rule (e.g. missing a required label).
- Surfaces findings in an **audit report**.
- Does **not** block anything — it only highlights drift.

This lets platform teams detect issues that slipped through over time and fix them without guessing.

### Example Audit Violation

```yaml
status:
  auditTimestamp: "2026-01-15T02:00:00Z"
  violations:
  - kind: Pod
    name: nginx
    message: "you must provide labels: {\"team\"}"
    enforcementAction: deny
```

The timestamp shows when the audit ran; each violation names the non-compliant resource and the reason.

## Kyverno Reports

Kyverno supports ongoing reporting through two report types:

| Report | Scope | Use |
|--------|-------|-----|
| **PolicyReport** | Namespaced | Policy results for a specific team/app/environment |
| **ClusterPolicyReport** | Cluster-wide | Big-picture compliance across the whole cluster |

These integrate with dashboards and external systems so teams can visualize compliance, track problems, and improve workloads over time.

```bash
kubectl get policyreport -A
kubectl get clusterpolicyreport
```

## Enforcement at Admission vs Audit

```text
Admission time  →  block non-compliant NEW resources (enforce)
Audit (ongoing) →  detect drift in EXISTING resources (report only)
```

Together they turn policy enforcement from a one-time creation check into **continuous** governance.

## Best Practices

| Practice | Why |
|----------|-----|
| Automate report collection into CI/CD | Do not rely on manual checking |
| Export reports to dashboards | Easier to see than scanning log files |
| Integrate with SIEM tools | Compliance issues visible like other operational events |
| Regularly review and remediate | Reports only help if teams act on them |
| Balance strictness vs productivity | Too strict blocks developers; too loose lets mistakes through |

Good policy design requires collaboration between Dev, Sec, and Ops so rules are strong but not disruptive.

## CKAD Note

Compliance auditing and reporting are **operations/CKS** concerns, not CKAD topics. The concept to retain: admission control is creation-time; auditing detects drift in already-running resources.

## Key Takeaway

Continuous compliance combines admission-time enforcement with ongoing auditing. Gatekeeper's audit and Kyverno's PolicyReport/ClusterPolicyReport surface drift in running resources so teams can remediate and keep the cluster aligned with standards.
