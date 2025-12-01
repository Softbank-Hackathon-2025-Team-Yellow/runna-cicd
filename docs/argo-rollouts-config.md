# Argo Rollouts Configuration

## Overview

This document describes the Argo Rollouts configuration for the serverless platform CI/CD pipeline. Argo Rollouts provides advanced deployment strategies (Canary and Blue-Green) for Kubernetes applications.

## Configuration Structure

### Rollout Template

Location: `helm/charts/platform-service/templates/rollout.yaml`

The Rollout template is conditionally enabled based on the `rollout.enabled` value in the Helm values file.

### Deployment Strategies

#### 1. Canary Deployment (Staging Environment)

**Configuration:**
```yaml
rollout:
  enabled: true
  strategy: canary
```

**Traffic Progression:**
- **Step 1:** 20% of traffic → new version (pause 2 minutes)
- **Step 2:** 50% of traffic → new version (pause 2 minutes)
- **Step 3:** 80% of traffic → new version (pause 2 minutes)
- **Step 4:** 100% of traffic → new version (complete)

**Services Created:**
- `{service-name}-canary`: Routes traffic to canary pods
- `{service-name}-stable`: Routes traffic to stable pods

**Requirements Validated:**
- ✅ Requirement 3.1: Uses Argo Rollouts for Canary deployment
- ✅ Requirement 3.2: Initial 20% traffic routing
- ✅ Requirement 3.3: Progressive traffic increase (20% → 50% → 80% → 100%)
- ✅ Requirement 3.4: Automatic progression after 2-minute pauses

#### 2. Blue-Green Deployment (Production Environment)

**Configuration:**
```yaml
rollout:
  enabled: true
  strategy: blueGreen
```

**Deployment Process:**
1. New version (Green) is deployed alongside current version (Blue)
2. Green version is fully tested in preview environment
3. Manual approval required to switch traffic
4. Traffic switches 100% from Blue to Green instantly
5. Blue version remains available for quick rollback

**Services Created:**
- `{service-name}`: Active service (Blue)
- `{service-name}-preview`: Preview service (Green)

**Key Setting:**
```yaml
autoPromotionEnabled: false  # Requires manual approval
```

**Requirements Validated:**
- ✅ Requirement 3.5: Blue-Green deployment with manual approval
- ✅ Requirement 5.4: Production uses Blue-Green strategy

#### 3. Standard Deployment (Development Environment)

**Configuration:**
```yaml
rollout:
  enabled: false
```

When Rollout is disabled, the standard Kubernetes Deployment is used (defined in `deployment.yaml`).

**Requirements Validated:**
- ✅ Requirement 5.2: Dev environment uses immediate deployment

## Environment-Specific Configuration

### Development (`values-backend-dev.yaml`)
```yaml
rollout:
  enabled: false  # Uses standard Deployment
  strategy: canary
```
- **Purpose:** Fast iteration, no progressive rollout needed
- **Deployment:** Immediate, all pods updated at once

### Staging (`values-backend-staging.yaml`)
```yaml
rollout:
  enabled: true
  strategy: canary  # Progressive rollout
```
- **Purpose:** Test progressive deployment before production
- **Deployment:** Canary with 20% → 50% → 80% → 100% progression

### Production (`values-backend-prod.yaml`)
```yaml
rollout:
  enabled: true
  strategy: blueGreen  # Manual approval required
```
- **Purpose:** Maximum safety with manual control
- **Deployment:** Blue-Green with manual promotion

## Rollout Resource Structure

### Canary Strategy YAML

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: backend
spec:
  replicas: 2
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
          image: 123456789.dkr.ecr.us-east-1.amazonaws.com/backend:abc123
          ports:
            - name: http
              containerPort: 8000
  strategy:
    canary:
      canaryService: backend-canary
      stableService: backend-stable
      steps:
        - setWeight: 20
        - pause: {duration: 2m}
        - setWeight: 50
        - pause: {duration: 2m}
        - setWeight: 80
        - pause: {duration: 2m}
```

### Blue-Green Strategy YAML

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: backend
spec:
  replicas: 3
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
          image: 123456789.dkr.ecr.us-east-1.amazonaws.com/backend:abc123
          ports:
            - name: http
              containerPort: 8000
  strategy:
    blueGreen:
      activeService: backend
      previewService: backend-preview
      autoPromotionEnabled: false  # Manual approval required
```

## Operations

### Monitoring Rollout Status

```bash
# Check rollout status
kubectl argo rollouts get rollout backend -n staging

# Watch rollout progress
kubectl argo rollouts get rollout backend -n staging --watch

# List all rollouts
kubectl argo rollouts list rollouts -n staging
```

### Manual Promotion (Blue-Green)

```bash
# Promote preview to active
kubectl argo rollouts promote backend -n production

# Abort rollout
kubectl argo rollouts abort backend -n production
```

### Manual Progression (Canary)

```bash
# Skip pause and proceed to next step
kubectl argo rollouts promote backend -n staging

# Abort canary rollout
kubectl argo rollouts abort backend -n staging
```

### Rollback

```bash
# Rollback to previous version
kubectl argo rollouts undo backend -n production

# Rollback to specific revision
kubectl argo rollouts undo backend -n production --to-revision=3
```

## Validation

### Verify Configuration

Run the validation script:
```bash
python scripts/validate-rollout-config.py
```

Expected output:
```
✅ All Argo Rollouts configurations are valid!

📝 Configuration Details:
  • Dev: Standard Deployment (rollout disabled)
  • Staging: Canary deployment (20% → 50% → 80% → 100%, 2m pauses)
  • Production: Blue-Green deployment (manual approval)
```

### Test Canary Deployment

1. Update image tag in `values-backend-staging.yaml`
2. Commit and push changes
3. ArgoCD will detect changes and trigger Rollout
4. Monitor progression:
   ```bash
   kubectl argo rollouts get rollout backend -n staging --watch
   ```

### Test Blue-Green Deployment

1. Update image tag in `values-backend-prod.yaml`
2. Commit and push changes
3. ArgoCD will deploy preview version
4. Verify preview service:
   ```bash
   kubectl get svc backend-preview -n production
   ```
5. Manually promote when ready:
   ```bash
   kubectl argo rollouts promote backend -n production
   ```

## Troubleshooting

### Rollout Stuck in Progressing State

**Symptom:** Rollout doesn't progress past a certain step

**Solutions:**
1. Check pod status: `kubectl get pods -n <namespace>`
2. Check rollout events: `kubectl describe rollout backend -n <namespace>`
3. Manually promote if needed: `kubectl argo rollouts promote backend -n <namespace>`

### Rollout Fails Immediately

**Symptom:** Rollout transitions to Degraded state

**Solutions:**
1. Check pod logs: `kubectl logs -l app=backend -n <namespace>`
2. Verify image exists in ECR
3. Check resource limits and requests
4. Rollback: `kubectl argo rollouts undo backend -n <namespace>`

### Services Not Created

**Symptom:** Canary/Preview services missing

**Solutions:**
1. Verify `rollout.enabled: true` in values file
2. Check Helm template rendering: `helm template backend helm/charts/platform-service -f helm/values/values-backend-staging.yaml`
3. Verify ArgoCD sync status: `argocd app get backend-staging`

## References

- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
- [Canary Deployment Strategy](https://argoproj.github.io/argo-rollouts/features/canary/)
- [Blue-Green Deployment Strategy](https://argoproj.github.io/argo-rollouts/features/bluegreen/)
- Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 5.2, 5.3, 5.4
