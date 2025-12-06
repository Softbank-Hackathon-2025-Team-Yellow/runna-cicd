# Serverless Platform - CI/CD & GitOps

서버리스 플랫폼의 CI/CD 파이프라인 및 GitOps 배포 시스템

## 🏗️ 아키텍처

```
코드 푸시 (GitHub)
  ↓
GitHub Actions (CI)
  ↓
Docker 빌드 → ECR 푸시
  ↓
Helm values 업데이트 → Git 커밋
  ↓
ArgoCD 감지 (GitOps)
  ↓
K8s 배포 (Argo Rollouts)
  ↓
Canary/Blue-Green 배포
```

## 📁 프로젝트 구조

```
.
├── .github/workflows/
│   └── ci-cd.yml              # GitHub Actions CI/CD
```
```
코드 푸시 → GitHub Actions 빌드 → ECR 푸시 
→ Helm values 업데이트 → Git 커밋 
→ ArgoCD 감지 → K8s 배포 
→ Argo Rollouts (20% → 50% → 80% → 100%)
```

## 아키텍처

```
┌─────────────┐
│  개발자     │
│  코드 푸시  │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│     GitHub Actions (CI)             │
│  - Docker 빌드                      │
│  - ECR 푸시                         │
│  - Helm values 업데이트             │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│     Git Repository                  │
│  - Helm Charts                      │
│  - Values Files                     │
│  - ArgoCD Applications              │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│     ArgoCD (GitOps)                 │
│  - Git 모니터링                     │
│  - 자동 동기화                      │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│     Kubernetes Cluster              │
│  - Argo Rollouts                    │
│  - Canary/Blue-Green 배포           │
└─────────────────────────────────────┘
```

## 기술 스택

- **CI**: GitHub Actions
- **컨테이너**: Docker + Amazon ECR
- **패키징**: Helm Charts
- **배포**: ArgoCD (GitOps)
- **점진적 배포**: Argo Rollouts
- **인프라**: Kubernetes (EKS)
- **모니터링**: Prometheus + Grafana (별도 담당)

## 프로젝트 구조

```
.
├── .github/
│   └── workflows/
│       └── ci-cd.yml              # GitHub Actions 워크플로우
│
├── services/
│   ├── backend/                   # Backend 서비스
│   │   └── Dockerfile
│   ├── frontend/                  # Frontend 서비스
│   │   └── Dockerfile
│   └── worker/                    # Worker 서비스
│       └── Dockerfile
│
├── helm/
│   ├── charts/
│   │   ├── platform-service/     # 플랫폼 서비스 공통 차트
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   └── templates/
│   │   │       ├── deployment.yaml
│   │   │       ├── service.yaml
│   │   │       ├── ingress.yaml
│   │   │       └── rollout.yaml
│   │   │
│   │   └── user-function/        # 사용자 함수 차트
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       └── templates/
│   │
│   └── values/                   # 환경별 values 파일
│       ├── values-backend-dev.yaml
│       ├── values-backend-staging.yaml
│       ├── values-backend-prod.yaml
│       ├── values-frontend-dev.yaml
│       ├── values-frontend-staging.yaml
│       └── values-frontend-prod.yaml
│
├── argocd/
│   ├── root-app.yaml             # App-of-Apps 패턴
│   ├── applications/             # 개별 Application 정의
│   │   ├── backend-dev.yaml
│   │   ├── backend-staging.yaml
│   │   └── backend-prod.yaml
│   │
│   └── analysis-templates/       # Rollout 분석 템플릿
│       └── success-rate.yaml
│
└── docs/                         # 문서
    ├── aws-setup.md
    └── operations.md
```

## 시작하기

### 사전 요구사항

- Docker
- kubectl
- helm (v3+)
- argocd CLI
- AWS CLI (ECR 접근용)
- GitHub 계정

### 로컬 개발 환경 설정

1. **저장소 클론**
   ```bash
   git clone https://github.com/your-org/serverless-platform.git
   cd serverless-platform
   ```

2. **Docker 이미지 로컬 빌드**
   ```bash
   cd services/backend
   docker build -t backend:local .
   ```

3. **Helm 차트 검증**
   ```bash
   helm lint helm/charts/platform-service
   ```

4. **Helm 템플릿 렌더링 테스트**
   ```bash
   helm template backend helm/charts/platform-service \
     -f helm/values/values-backend-dev.yaml
   ```

## 사용법

### 새 서비스 배포

1. **Dockerfile 작성**
   ```bash
   mkdir -p services/new-service
   # Dockerfile 작성
   ```

2. **Helm values 생성**
   ```bash
   cp helm/values/values-backend-prod.yaml \
      helm/values/values-new-service-prod.yaml
   # values 파일 수정
   ```

3. **ArgoCD Application 생성**
   ```bash
   cp argocd/applications/backend-prod.yaml \
      argocd/applications/new-service-prod.yaml
   # Application 파일 수정
   ```

4. **GitHub Actions에 추가**
   - `.github/workflows/ci-cd.yml`의 matrix.service에 추가

### 수동 배포

```bash
# ArgoCD 동기화
argocd app sync backend-prod

# 동기화 상태 확인
argocd app get backend-prod
```

### 롤백

```bash
# ArgoCD를 통한 롤백
argocd app rollback backend-prod

# 또는 Git을 통한 롤백
cd helm/values
git revert HEAD
git push
```

## 배포 전략

### Dev 환경
- **전략**: 일반 Deployment (Argo Rollouts 비활성화)
- **자동 배포**: 즉시
- **용도**: 개발 및 테스트
- **설정**: `rollout.enabled: false`

### Staging 환경
- **전략**: Canary 배포
- **단계**: 20% → 50% → 80% → 100%
- **대기 시간**: 각 단계마다 2분
- **자동 진행**: 각 단계 후 자동으로 다음 단계 진행
- **용도**: 프로덕션 전 검증
- **설정**: `rollout.enabled: true`, `rollout.strategy: canary`
- **요구사항**: 3.1, 3.2, 3.3, 3.4

**Canary 배포 흐름:**
```
새 버전 배포 시작
  ↓
20% 트래픽 → 새 버전 (2분 대기)
  ↓
50% 트래픽 → 새 버전 (2분 대기)
  ↓
80% 트래픽 → 새 버전 (2분 대기)
  ↓
100% 트래픽 → 새 버전 (완료)
```

### Production 환경
- **전략**: Blue-Green 배포
- **승인**: 수동 승인 필요 (`autoPromotionEnabled: false`)
- **용도**: 실제 서비스
- **설정**: `rollout.enabled: true`, `rollout.strategy: blueGreen`
- **요구사항**: 3.5, 5.4

**Blue-Green 배포 흐름:**
```
새 버전(Green) 배포
  ↓
Preview 서비스에서 테스트
  ↓
수동 승인 대기
  ↓
트래픽 100% 전환 (Blue → Green)
  ↓
이전 버전(Blue) 대기 (롤백 가능)
```

**Argo Rollouts 명령어:**
```bash
# Rollout 상태 확인
kubectl argo rollouts get rollout backend -n staging

# Rollout 진행 상황 모니터링
kubectl argo rollouts get rollout backend -n staging --watch

# 수동 승인 (Blue-Green)
kubectl argo rollouts promote backend -n production

# Canary 단계 건너뛰기
kubectl argo rollouts promote backend -n staging

# Rollout 중단
kubectl argo rollouts abort backend -n staging

# 이전 버전으로 롤백
kubectl argo rollouts undo backend -n production
```

자세한 내용은 `docs/argo-rollouts-config.md`를 참조하세요.

## 환경 설정

### GitHub Secrets 설정

다음 secrets를 GitHub 저장소에 추가해야 합니다:

- `AWS_ROLE_ARN`: AWS IAM Role ARN (OIDC 인증용)
- `AWS_REGION`: AWS 리전 (예: us-east-1)
- `ECR_REGISTRY`: ECR 레지스트리 URL

### AWS IAM Role 설정

GitHub Actions에서 사용할 IAM Role을 생성하고 OIDC 신뢰 관계를 설정합니다.

자세한 내용은 `docs/aws-setup.md`를 참조하세요.

### ArgoCD 설정

1. **ArgoCD 설치**
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

2. **Root Application 배포**
   ```bash
   kubectl apply -f argocd/root-app.yaml
   ```

3. **ArgoCD UI 접속**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

### Argo Rollouts 설정

1. **Argo Rollouts 설치**
   ```bash
   kubectl create namespace argo-rollouts
   kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
   ```

2. **Argo Rollouts CLI 설치**
   ```bash
   # Linux/Mac
   curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
   chmod +x kubectl-argo-rollouts-linux-amd64
   sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
   
   # Windows (PowerShell)
   Invoke-WebRequest -Uri https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-windows-amd64 -OutFile kubectl-argo-rollouts.exe
   ```

3. **Rollout 대시보드 접속**
   ```bash
   kubectl argo rollouts dashboard
   # http://localhost:3100 에서 접속
   ```

## 테스트

### 속성 기반 테스트 (Property-Based Testing)

프로젝트는 Hypothesis를 사용한 속성 기반 테스트를 포함합니다:

```bash
# 필요한 패키지 설치
pip install -r tests/requirements.txt

# 이미지 태그 고유성 테스트
python tests/test_image_tag_uniqueness.py

# Helm values 업데이트 일관성 테스트
python tests/test_helm_values_update.py

# Rollout 전략 일관성 테스트
python tests/test_rollout_strategy.py
```

각 테스트는 100회 반복 실행되어 다양한 입력에 대한 정확성을 검증합니다.

### Argo Rollouts 설정 테스트

Rollout 템플릿과 환경별 설정을 검증하는 테스트:

```bash
# Rollout 설정 검증
python scripts/validate-rollout-config.py

# 포괄적인 Rollout 테스트
python tests/test_rollout_configuration.py

# 통합 테스트 (PowerShell)
powershell -ExecutionPolicy Bypass -File tests/run-rollout-config-test.ps1
```

이 테스트는 다음을 검증합니다:
- Rollout 템플릿 구조 및 API 버전
- Canary 전략 (20% → 50% → 80% → 100%, 2분 대기)
- Blue-Green 전략 (수동 승인)
- 환경별 배포 전략 설정
- 요구사항 3.1, 3.2, 3.3, 3.4, 3.5 준수

### ArgoCD Dry-Run 테스트

ArgoCD Application 매니페스트를 검증하는 dry-run 시뮬레이션 테스트:

```bash
# PowerShell (Windows)
powershell -ExecutionPolicy Bypass -File scripts/test-argocd-dryrun.ps1

# 또는 테스트 러너 사용
powershell -ExecutionPolicy Bypass -File tests/run-argocd-dryrun-test.ps1

# Bash (Linux/Mac)
bash scripts/test-argocd-dryrun.sh
```

이 테스트는 다음을 검증합니다:
- ArgoCD Application YAML 구조
- 필수 필드 및 설정
- Helm values 파일 참조
- Sync 정책 및 자동화 설정

자세한 내용은 `docs/argocd-dryrun-testing.md`를 참조하세요.

## 멀티테넌시 (Phase 3)

### 개요

사용자별로 격리된 함수 실행 환경을 제공하는 멀티테넌트 아키텍처

### 테넌트 격리 전략

**Namespace 기반 격리:**
```
kubernetes-cluster/
├── platform-system/          # 플랫폼 공통 서비스
│   ├── backend-api
│   ├── argocd
│   └── monitoring
│
├── tenant-user001/           # 사용자 1의 네임스페이스
│   ├── user-function-1
│   ├── user-function-2
│   └── resource-quota
│
└── tenant-user002/           # 사용자 2의 네임스페이스
    └── user-function-1
```

### 테넌트 생성 플로우

```
사용자 회원가입
  ↓
Backend API: 사용자 생성
  ↓
Namespace 자동 생성 (tenant-{user_id})
  ↓
ResourceQuota 설정 (CPU/메모리/Pod 제한)
  ↓
NetworkPolicy 적용 (테넌트 간 격리)
  ↓
ServiceAccount & RBAC 설정
  ↓
테넌트 준비 완료
```

### 리소스 제한

각 테넌트는 다음 리소스 제한을 가집니다:

- **CPU**: 최소 2코어, 최대 4코어
- **메모리**: 최소 4GB, 최대 8GB
- **Pod 개수**: 최대 10개 함수
- **스토리지**: 최대 10GB

### 보안

- **NetworkPolicy**: 테넌트 간 네트워크 격리
- **RBAC**: 테넌트는 자신의 네임스페이스만 접근
- **Pod Security Standards**: Restricted 정책 적용

자세한 내용은 `docs/PHASE3-MULTITENANCY-DESIGN.md`를 참조하세요.

## 트러블슈팅

### 빌드 실패

```bash
# GitHub Actions 로그 확인
# Repository → Actions → 실패한 워크플로우 클릭
```

### ArgoCD 동기화 실패

```bash
# ArgoCD 상태 확인
argocd app get backend-prod

# 상세 로그 확인
argocd app logs backend-prod
```

### Rollout 실패

```bash
# Rollout 상태 확인
kubectl argo rollouts get rollout backend -n production

# Rollout 중단 및 롤백
kubectl argo rollouts abort backend -n production
kubectl argo rollouts undo backend -n production
```

## 기여하기

1. Feature 브랜치 생성
2. 변경사항 커밋
3. Pull Request 생성
4. 코드 리뷰 후 병합

## 라이선스

MIT License

## 연락처

- 프로젝트 관리자: [이름]
- 이메일: [이메일]
- Slack: #serverless-platform

---

**해커톤 참고사항**

이 프로젝트는 해커톤을 위해 설계되었습니다. 핵심 기능(작업 1-11)에 집중하여 빠르게 MVP를 완성하는 것을 목표로 합니다.
