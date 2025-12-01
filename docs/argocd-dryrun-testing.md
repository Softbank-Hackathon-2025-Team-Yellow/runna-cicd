# ArgoCD Dry-Run Testing

## Overview

This document describes the ArgoCD dry-run testing approach for validating ArgoCD Application manifests before deployment.

## Purpose

The dry-run tests simulate ArgoCD synchronization by validating:
- ArgoCD Application manifest structure
- Required fields and configurations
- Helm values file references
- Sync policies and automation settings

## Test Scripts

### PowerShell (Windows)
```powershell
# Run the test directly
powershell -ExecutionPolicy Bypass -File scripts/test-argocd-dryrun.ps1

# Or use the test runner
powershell -ExecutionPolicy Bypass -File tests/run-argocd-dryrun-test.ps1
```

### Bash (Linux/Mac)
```bash
# Run the test directly
bash scripts/test-argocd-dryrun.sh

# Make executable first if needed
chmod +x scripts/test-argocd-dryrun.sh
./scripts/test-argocd-dryrun.sh
```

## What is Validated

### 1. Root Application (App-of-Apps)
- ✓ YAML structure validity
- ✓ Required fields (apiVersion, kind, metadata, spec)
- ✓ Project configuration
- ✓ Source configuration (repoURL, targetRevision, path)
- ✓ Destination configuration (server, namespace)

### 2. Child Applications
- ✓ YAML structure validity
- ✓ Application spec completeness
- ✓ Helm values file references (path resolution)
- ✓ Sync policy configuration
- ✓ Automated sync settings
- ✓ Prune and self-heal settings

## Test Output

### Success
```
=== ArgoCD Dry-Run Simulation Test ===

Validating Root Application...
File: argocd/root-app.yaml
✓ Root application YAML structure valid
✓ Root application spec valid

Validating Child Applications...

File: argocd/applications/backend-dev.yaml
✓ YAML structure valid
✓ Application spec valid
✓ Helm values reference valid
✓ Sync policy configured
  ✓ Automated sync enabled
  ✓ Prune enabled
  ✓ Self-heal enabled

=== Dry-Run Simulation Summary ===

✓ All ArgoCD applications are valid!

Dry-run simulation passed. Applications would sync successfully.
```

### Failure
```
=== ArgoCD Dry-Run Simulation Test ===

Validating Root Application...
File: argocd/root-app.yaml
✗ Root application not found

=== Dry-Run Simulation Summary ===

Errors found:
  ✗ Root application not found: argocd/root-app.yaml

Dry-run simulation failed. Fix the issues above before deploying.
```

## Actual ArgoCD CLI Commands

Once ArgoCD CLI is installed and configured, you can perform actual dry-runs:

```bash
# Dry-run sync (shows what would be applied)
argocd app sync backend-dev --dry-run
argocd app sync backend-staging --dry-run

# Show differences between Git and cluster
argocd app diff backend-dev
argocd app diff backend-staging

# Get application status
argocd app get backend-dev
argocd app get backend-staging
```

## Integration with CI/CD

The dry-run tests can be integrated into CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Validate ArgoCD Applications
  run: |
    powershell -ExecutionPolicy Bypass -File scripts/test-argocd-dryrun.ps1
```

## Requirements Validation

This test validates **Requirement 7.4**:
> WHEN 로컬에서 ArgoCD 동기화를 시뮬레이션하면 THEN THE System SHALL dry-run 모드로 변경사항을 미리 확인한다

## Limitations

The simulation test validates manifest structure and references but cannot:
- Connect to actual Kubernetes clusters
- Validate RBAC permissions
- Check resource quotas
- Verify network policies
- Test actual deployment behavior

For complete validation, use the actual ArgoCD CLI with a test cluster.

## Troubleshooting

### Issue: Helm values file not found
**Solution**: Ensure the path in the ArgoCD Application's `valueFiles` field correctly resolves relative to the chart path.

### Issue: Invalid YAML structure
**Solution**: Check for syntax errors in the ArgoCD Application manifest. Use a YAML validator or linter.

### Issue: Missing required fields
**Solution**: Ensure all required fields are present:
- `apiVersion: argoproj.io/v1alpha1`
- `kind: Application`
- `metadata.name`
- `spec.project`
- `spec.source` (with repoURL, targetRevision, path)
- `spec.destination` (with server, namespace)

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Application CRD](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
