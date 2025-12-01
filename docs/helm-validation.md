# Helm Chart Validation Guide

## Overview

This document describes how to validate Helm charts for the serverless platform using `helm lint` and `helm template` commands.

**Requirements:** 7.2, 7.3

## Prerequisites

- Helm 3.x installed ([Installation Guide](https://helm.sh/docs/intro/install/))

## Validation Scripts

We provide validation scripts for both Windows (PowerShell) and Linux/Mac (Bash):

- **Windows:** `scripts/validate-helm.ps1`
- **Linux/Mac:** `scripts/validate-helm.sh`

## Manual Validation

### 1. Helm Lint (Syntax Validation)

Validates the chart structure and template syntax for errors.

```bash
# Validate platform-service chart
helm lint helm/charts/platform-service

# Validate with specific values file
helm lint helm/charts/platform-service -f helm/values/values-backend-prod.yaml
```

**What it checks:**
- Chart.yaml structure and required fields
- Template syntax errors
- YAML formatting issues
- Missing required values
- Deprecated Kubernetes API versions

**Expected output:**
```
==> Linting helm/charts/platform-service
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

### 2. Helm Template (Rendering Test)

Renders the templates to verify they produce valid Kubernetes manifests.

```bash
# Render templates with default values
helm template test-release helm/charts/platform-service

# Render with specific values file
helm template backend-prod helm/charts/platform-service \
  -f helm/values/values-backend-prod.yaml

# Render and save to file for inspection
helm template backend-prod helm/charts/platform-service \
  -f helm/values/values-backend-prod.yaml \
  > rendered-manifests.yaml
```

**What it checks:**
- Templates render without errors
- All variables are properly substituted
- Conditional logic works correctly
- Output is valid YAML
- Kubernetes resource definitions are complete

**Expected output:**
```yaml
---
# Source: platform-service/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
  labels:
    app: backend
spec:
  type: ClusterIP
  ports:
    - port: 8000
      targetPort: http
      protocol: TCP
      name: http
  selector:
    app: backend
---
# Source: platform-service/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  labels:
    app: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: 123456789.dkr.ecr.us-east-1.amazonaws.com/backend:latest
          imagePullPolicy: IfNotPresent
          ports:
            - name: http
              containerPort: 8000
              protocol: TCP
          resources:
            limits:
              cpu: 1000m
              memory: 1Gi
            requests:
              cpu: 500m
              memory: 512Mi
```

## Using Validation Scripts

### Windows (PowerShell)

```powershell
# Validate default chart
.\scripts\validate-helm.ps1

# Validate with specific values
.\scripts\validate-helm.ps1 -ChartPath "helm/charts/platform-service" -ValuesPath "helm/values/values-backend-prod.yaml"
```

### Linux/Mac (Bash)

```bash
# Make script executable
chmod +x scripts/validate-helm.sh

# Validate default chart
./scripts/validate-helm.sh

# Validate with specific values
./scripts/validate-helm.sh helm/charts/platform-service helm/values/values-backend-prod.yaml
```

## Validation Checklist

Before deploying any Helm chart, ensure:

- [ ] `helm lint` passes with no errors
- [ ] `helm template` renders successfully
- [ ] All required values are defined
- [ ] Conditional logic (if/else) works as expected
- [ ] Resource names follow naming conventions
- [ ] Labels and selectors are consistent
- [ ] Container images use proper tags (not `latest` in production)
- [ ] Resource limits and requests are appropriate
- [ ] Ingress configuration is correct (if enabled)
- [ ] Rollout configuration is valid (if enabled)

## Environment-Specific Validation

Validate each environment configuration:

```bash
# Development
helm lint helm/charts/platform-service -f helm/values/values-backend-dev.yaml
helm template backend-dev helm/charts/platform-service -f helm/values/values-backend-dev.yaml

# Staging
helm lint helm/charts/platform-service -f helm/values/values-backend-staging.yaml
helm template backend-staging helm/charts/platform-service -f helm/values/values-backend-staging.yaml

# Production
helm lint helm/charts/platform-service -f helm/values/values-backend-prod.yaml
helm template backend-prod helm/charts/platform-service -f helm/values/values-backend-prod.yaml
```

## Common Issues and Solutions

### Issue: Missing required values

**Error:**
```
Error: template: platform-service/templates/deployment.yaml:10:20: executing "platform-service/templates/deployment.yaml" at <.Values.service.name>: nil pointer evaluating interface {}.name
```

**Solution:** Ensure all required values are defined in values.yaml or the values file being used.

### Issue: Invalid YAML syntax

**Error:**
```
Error: YAML parse error on platform-service/templates/deployment.yaml: error converting YAML to JSON
```

**Solution:** Check for proper indentation and YAML syntax in templates.

### Issue: Deprecated API versions

**Warning:**
```
[WARNING] templates/deployment.yaml: Deployment "backend" is using deprecated API version "apps/v1beta1"
```

**Solution:** Update to current API versions (e.g., `apps/v1` for Deployments).

## Integration with CI/CD

The validation scripts are designed to be integrated into CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Validate Helm Charts
  run: |
    helm lint helm/charts/platform-service
    helm template test helm/charts/platform-service
```

## Additional Validation Tools

For more comprehensive validation, consider:

- **kubeval:** Validates Kubernetes manifests against schemas
  ```bash
  helm template backend helm/charts/platform-service | kubeval --strict
  ```

- **kube-score:** Analyzes manifests for best practices
  ```bash
  helm template backend helm/charts/platform-service | kube-score score -
  ```

- **Polaris:** Checks for security and reliability issues
  ```bash
  helm template backend helm/charts/platform-service | polaris audit --format=pretty
  ```

## References

- [Helm Lint Documentation](https://helm.sh/docs/helm/helm_lint/)
- [Helm Template Documentation](https://helm.sh/docs/helm/helm_template/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
