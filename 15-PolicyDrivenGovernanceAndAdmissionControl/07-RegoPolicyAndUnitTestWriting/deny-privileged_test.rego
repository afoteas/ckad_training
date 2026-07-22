package kubernetes.admission

# A privileged Pod should produce exactly one denial.
test_denies_privileged_pod {
  msgs := deny with input as {
    "kind": "Pod",
    "spec": {"containers": [{"name": "app", "securityContext": {"privileged": true}}]},
  }
  count(msgs) == 1
}

# A non-privileged Pod should produce no denials.
test_allows_unprivileged_pod {
  msgs := deny with input as {
    "kind": "Pod",
    "spec": {"containers": [{"name": "app", "securityContext": {"privileged": false}}]},
  }
  count(msgs) == 0
}
