# runna-server 배포 리소스 구조

## 1. 배포 아키텍처

```
GitHub
  ↓ (CI) GitHub Actions
  ├─ Build Docker Image
  ├─ Run Tests
  ├─ Push → Docker Hub (ytjdud79/backend)
  └─ Commit updated manifest (tag update) to Git Repo
      ↓
ArgoCD (GitOps)
  ↓ (CD)
Kubernetes Cluster
  └─ runna-server Deployment (Pod)
```

## 2. 현재 리포지토리 구조

```
runna-cicd/
├── .github/workflows/
│   └── ci-cd.yml                    # CI 파이프라인
│
├── argocd/
│   ├── root-app.yaml                # ArgoCD Root Application
│   └── applications/
│       ├── backend-dev.yaml         # Dev 환경 Application
│       ├── backend-staging.yaml     # Staging 환경 Application
│       └── backend-prod.yaml        # Production 환경 Application
│
├── helm/
│   ├── charts/
│   │   └── platform-service/        # Helm Chart
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       └── templates/
│   │           ├── deployment.yaml
│   │           ├── service.yaml
│   │           ├── ingress.yaml
│   │           └── rollout.yaml     # Argo Rollouts
│   │
│   └── values/
│       ├── values-backend-dev.yaml      # Dev 환경 설정
│       ├── values-backend-staging.yaml  # Staging 환경 설정
│       └── values-backend-prod.yaml     # Production 환경 설정
│
└── backend-repo/                    # Backend 소스코드 (submodule)
    ├── Dockerfile
    └── app/
```

## 3. ArgoCD Application 설정

### Root Application (App of Apps 패턴)

```yaml
# argocd/root-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: serverless-platform
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Softbank-Hackathon-2025-Team-Yellow/runna-cicd
    path: argocd/applications
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Backend Application (예시: Production)

```yaml
# argocd/applications/backend-prod.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend-prod
  namespace: argocd
  labels:
    environment: production
    service: backend
spec:
  project: default
  source:
    repoURL: https://github.com/Softbank-Hackathon-2025-Team-Yellow/runna-cicd
    targetRevision: main
    path: helm/charts/platform-service
    helm:
      valueFiles:
        - ../../values/values-backend-prod.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## 4. CI/CD 워크플로우

### CI (GitHub Actions)

1. **Trigger**: `backend-repo/` 또는 `helm/` 변경 시
2. **Build**: Docker 이미지 빌드
3. **Push**: Docker Hub에 푸시 (`ytjdud79/backend:${GITHUB_SHA:0:15}`)
4. **Update**: Helm values 파일의 이미지 태그 자동 업데이트
5. **Commit**: 변경사항을 Git에 커밋

### CD (ArgoCD)

1. **Watch**: Git 리포지토리 모니터링
2. **Detect**: Helm values 변경 감지
3. **Sync**: Kubernetes 클러스터에 자동 배포
4. **Health Check**: 배포 상태 모니터링

## 5. 배포 전략

### Development
- **Strategy**: Rolling Update
- **Auto Sync**: Enabled
- **Replicas**: 1

### Staging
- **Strategy**: Canary (10% → 50% → 100%)
- **Auto Sync**: Enabled
- **Replicas**: 2

### Production
- **Strategy**: Blue-Green
- **Auto Sync**: Enabled (Manual Promotion)
- **Replicas**: 3
- **HPA**: 3-20 replicas

## 6. 배포 순서

### 초기 설정

```bash
# 1. ArgoCD Root App 배포
kubectl apply -f argocd/root-app.yaml

# 2. Applications 자동 생성 확인
kubectl get applications -n argocd

# 3. 동기화 상태 확인
kubectl get applications -n argocd -o wide
```

### 이후 배포

```bash
# 1. 코드 변경 후 main 브랜치에 push
git push origin main

# 2. GitHub Actions가 자동으로:
#    - Docker 이미지 빌드 & 푸시
#    - Helm values 업데이트
#    - Git 커밋

# 3. ArgoCD가 자동으로:
#    - 변경사항 감지
#    - Kubernetes에 배포
```

## 7. 환경별 설정

| 환경 | Namespace | Replicas | Strategy | Auto-Promotion |
|------|-----------|----------|----------|----------------|
| Dev | development | 1 | Rolling | Yes |
| Staging | staging | 2 | Canary | Yes |
| Production | production | 3-20 | Blue-Green | Manual |

## 8. 필요한 Secrets

각 환경별로 다음 Secret이 필요합니다:

```yaml
# backend-secrets
apiVersion: v1
kind: Secret
metadata:
  name: backend-secrets
  namespace: {environment}
type: Opaque
data:
  database-url: <base64-encoded>
  redis-password: <base64-encoded>
  secret-key: <base64-encoded>
```

```yaml
# dockerhub-secret
apiVersion: v1
kind: Secret
metadata:
  name: dockerhub-secret
  namespace: {environment}
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded>
```

## 9. 모니터링

### ArgoCD UI
- URL: (ALB DNS 설정 후 제공)
- Applications 상태 확인
- Sync 히스토리 확인
- Rollback 기능

### Kubernetes
```bash
# Pod 상태 확인
kubectl get pods -n production

# Rollout 상태 확인
kubectl argo rollouts get rollout backend -n production

# 로그 확인
kubectl logs -f deployment/backend -n production
```

## 10. 트러블슈팅

### ArgoCD Sync 실패
```bash
# Application 상태 확인
kubectl describe application backend-prod -n argocd

# Sync 재시도
kubectl patch application backend-prod -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

### Image Pull 실패
```bash
# Secret 확인
kubectl get secret dockerhub-secret -n production

# Secret 재생성
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=ytjdud79 \
  --docker-password=<token> \
  -n production
```

### Rollout 실패
```bash
# Rollout 상태 확인
kubectl argo rollouts get rollout backend -n production

# Rollout 중단
kubectl argo rollouts abort backend -n production

# 이전 버전으로 롤백
kubectl argo rollouts undo backend -n production
```
