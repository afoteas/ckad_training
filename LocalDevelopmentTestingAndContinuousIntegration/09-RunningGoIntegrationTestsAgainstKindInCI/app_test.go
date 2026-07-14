//go:build integration

package integration

import (
	"os/exec"
	"testing"
)

// TestKindClusterReachable validates kubectl connectivity to the CI kind cluster.
func TestKindClusterReachable(t *testing.T) {
	cmd := exec.Command("kubectl", "cluster-info", "--context", "kind-ci")
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("kind cluster not reachable: %v\n%s", err, string(out))
	}
}
