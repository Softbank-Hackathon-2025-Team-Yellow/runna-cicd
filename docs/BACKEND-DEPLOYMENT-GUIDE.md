# Backend 배포 가이드 🚀

## 📋 받은 환경변수 정보

```env
DATABASE_URL=postgresql://user:password@localhost:5432/runna_db
SECRET_KEY=b7b482449580b9fdf430e28d39b9f3b0bbb570de441a2e3dc69697ffbb307d91
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
DEBUG=true
ENVIRONMENT=production
KUBERNETES_IN_CLUSTER=true
BASE_DOMAIN=runna.haifu.cloud
K8S_PYTHON_IMAGE=docker.io/sbyellow/python-runtime:latest
K8S_NODEJS_IMAGE=docker.io/sbyellow/node-runner:v1
GATEWAY_NAME=3scale-kourier-gateway
```

## 🔐 Step 1: Kubernetes Secret 생성

### 방법 1: 자동 스크립트 사용 (권장)

```powershell
# PowerShell에서 실행
.\scripts\create-backend-secrets-direct.ps1
```

### 방법 2: kubectl 명령어 직접 실행

```bash
kubectl create secret generic backend-secrets \
  --from-literal=database-url='postgresql://user:password@localhost:5432/runna_db' \
  --from-literal=secret-key='b7b482449580b9fdf430e28d39b9f3b0bbb570de441a2e3dc69697ffbb307d91' \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Secret 확인

```bash
# Secret 존재 확인
kubectl get secret backend-secrets

# Secret 상세 정보
kubectl describe secret backend-secrets

# Secret 값 확인 (디코딩)
kubectl get secret backend-secrets -o jsonpath='{.data.database-url}' | base64 --decode
kubectl get secret backend-secrets -o jsonpath='{.data.secret-key}' | base64 --decode
```

## 📦 Step 2: Helm Values 확인

업데이트된 환경변수들이 `helm/values/values-backend-dev.yaml`에 반영되었습니다:

```yaml
env:
  # Database (Secret에서 가져옴)
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: backend-secrets
        key: database-url
  
  # Security (Secret에서 가져옴)
  - name: SECRET_KEY
    valueFrom:
      secretKeyRef:
        name: backend-secrets
        key: secret-key
  
  - name: ALGORITHM
    value: "HS256"
  
  - name: ACCESS_TOKEN_EXPIRE_MINUTES
    value: "30"
  
  # Environment
  - name: ENVIRONMENT
    value: "production"
  
  - name: DEBUG
    value: "true"
  
  # Kubernetes Configuration
  - name: KUBERNETES_IN_CLUSTER
    value: "true"
  
  - name: BASE_DOMAIN
    value: "runna.haifu.cloud"
  
  - name: K8S_NAMESPACE_PREFIX
    value: "tenant-"
  
  # Runtime Images
  - name: K8S_PYTHON_IMAGE
    value: "docker.io/sbyellow/python-runtime:latest"
  
  - name: K8S_NODEJS_IMAGE
    value: "docker.io/sbyellow/node-runner:v1"
  
  # Gateway API Configuration
  - name: GATEWAY_NAME
    value: "3scale-kourier-gateway"
```

## 🚀 Step 3: Backend 배포

### ArgoCD를 통한 자동 배포

1. **Git에 변경사항 커밋:**
```bash
git add helm/values/values-backend-dev.yaml
git commit -m "feat: Update backend environment variables"
git push origin main
```

2. **ArgoCD가 자동으로 감지하고 배포:**
```bash
# ArgoCD 앱 상태 확인
kubectl get applications -n argocd

# 수동 동기화 (필요시)
argocd app sync backend-dev
```

### 수동 Helm 배포 (테스트용)

```bash
# Helm 차트 검증
helm lint helm/charts/platform-service

# Dry-run으로 확인
helm upgrade --install backend \
  helm/charts/platform-service \
  -f helm/values/values-backend-dev.yaml \
  --dry-run --debug

# 실제 배포
helm upgrade --install backend \
  helm/charts/platform-service \
  -f helm/values/values-backend-dev.yaml \
  --namespace default
```

## ✅ Step 4: 배포 확인

### Pod 상태 확인

```bash
# Pod 목록
kubectl get pods -l app=backend

# Pod 로그
kubectl logs -l app=backend --tail=100 -f

# Pod 상세 정보
kubectl describe pod -l app=backend
```

### 환경변수 확인

```bash
# Pod 내부 환경변수 확인
kubectl exec -it <pod-name> -- env | grep -E "DATABASE_URL|SECRET_KEY|ENVIRONMENT|BASE_DOMAIN"
```

### 서비스 확인

```bash
# Service 확인
kubectl get svc backend

# Ingress 확인
kubectl get ingress

# Health Check
kubectl exec -it <pod-name> -- curl http://localhost:8000/health
```

## 🔍 트러블슈팅

### Secret을 찾을 수 없는 경우

```bash
# Secret 재생성
kubectl delete secret backend-secrets
.\scripts\create-backend-secrets-direct.ps1
```

### Pod가 시작되지 않는 경우

```bash
# Pod 이벤트 확인
kubectl describe pod -l app=backend

# Pod 로그 확인
kubectl logs -l app=backend --previous
```

### 환경변수가 제대로 주입되지 않는 경우

```bash
# Helm values 확인
helm get values backend

# Pod 환경변수 확인
kubectl exec -it <pod-name> -- env
```

## 📊 환경변수 매핑

| .env 변수 | Helm Values | Secret/ConfigMap |
|-----------|-------------|------------------|
| DATABASE_URL | ✅ | Secret (backend-secrets) |
| SECRET_KEY | ✅ | Secret (backend-secrets) |
| ALGORITHM | ✅ | Values (직접) |
| ACCESS_TOKEN_EXPIRE_MINUTES | ✅ | Values (직접) |
| DEBUG | ✅ | Values (직접) |
| ENVIRONMENT | ✅ | Values (직접) |
| KUBERNETES_IN_CLUSTER | ✅ | Values (직접) |
| BASE_DOMAIN | ✅ | Values (직접) |
| K8S_PYTHON_IMAGE | ✅ | Values (직접) |
| K8S_NODEJS_IMAGE | ✅ | Values (직접) |
| GATEWAY_NAME | ✅ | Values (직접) |

## 🔄 다음 단계

1. ✅ Secret 생성 완료
2. ✅ Helm Values 업데이트 완료
3. ⏭️ Git Push
4. ⏭️ ArgoCD 자동 배포 확인
5. ⏭️ Backend API 테스트

---

**작성일:** 2024-12-06  
**작성자:** 서영  
**용도:** 백엔드 배포 가이드
