# Serverless Platform - CI/CD & GitOps

서버리스 플랫폼의 CI/CD 파이프라인 및 GitOps 배포 시스템

## 🏗️ 아키텍처

```
코드 푸시 (GitHub)
  ↓
GitHub Actions (CI)
  ↓
Docker 빌드 → Docker Hub 푸시
  ↓
Manifests 업데이트 → Git 커밋
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
│   └── temp.yml               # Backend CI/CD (Docker + Manifests 업데이트)
```

## 🚀 백엔드 CI/CD 워크플로우 가이드

### 워크플로우 개요

백엔드 서비스를 위한 완전 자동화된 CI/CD 파이프라인으로, Docker 이미지 빌드부터 Kubernetes 매니페스트 업데이트까지 처리합니다.

### 트리거 조건

워크플로우는 다음 조건에서 자동 실행됩니다:

```yaml
on:
  push:
    branches: [ main ]
    paths:
      - 'services/backend/**'      # 백엔드 코드 변경 시
      - '.github/workflows/**'      # 워크플로우 파일 변경 시
```

### 파이프라인 단계

#### 1️⃣ 백엔드 코드 체크아웃

```yaml
- name: Checkout backend repo
  uses: actions/checkout@v4
  with:
    repository: Softbank-Hackathon-2025-Team-Yellow/runna-backend
    token: ${{ secrets.BACKEND_PAT }}
    path: backend-repo
```

**동작:**
- 별도의 백엔드 저장소에서 코드를 가져옵니다
- `BACKEND_PAT`: 저장소 접근 권한이 있는 GitHub Classic Personal Access Token
- `backend-repo` 폴더에 코드를 체크아웃합니다

#### 2️⃣ Docker Hub 로그인

```yaml
- name: Login to Docker Hub
  uses: docker/login-action@v3
  with:
    registry: docker.io
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
```

**동작:**
- Docker Hub에 인증하여 이미지를 푸시할 수 있도록 준비합니다

#### 3️⃣ 이미지 태그 생성

```yaml
- name: Set image tag from git SHA
  run: |
    IMAGE_TAG=${GITHUB_SHA::7}
    echo "IMAGE_TAG=$IMAGE_TAG" >> $GITHUB_ENV
```

**동작:**
- Git 커밋 SHA의 앞 7자리를 이미지 태그로 사용합니다
- 예: `abc1234` → `docker.io/username/backend:abc1234`
- 각 빌드마다 고유한 태그를 보장하여 버전 추적이 가능합니다

#### 4️⃣ Docker 이미지 빌드 및 푸시

```yaml
- name: Build and push Docker image
  run: |
    IMAGE_NAME=${{ secrets.DOCKERHUB_USERNAME }}/backend
    docker build -t $IMAGE_NAME:$IMAGE_TAG backend-repo
    docker push $IMAGE_NAME:$IMAGE_TAG
```

**동작:**
- 백엔드 코드를 기반으로 Docker 이미지를 빌드합니다
- 생성된 이미지를 Docker Hub에 푸시합니다
- 이미지 형식: `username/backend:abc1234`

#### 5️⃣ Manifests 저장소 클론

```yaml
- name: Clone manifests repo
  run: |
    git clone "https://${{ secrets.CLASSIC_PAT }}@github.com/${{ secrets.MANIFESTS_REPO }}.git" manifests-repo
```

**동작:**
- Kubernetes 매니페스트 파일이 있는 별도 저장소를 클론합니다
- `MANIFESTS_REPO`: 매니페스트 저장소 경로 (예: `org/repo-name`)
- GitOps 패턴을 위해 매니페스트와 애플리케이션 코드를 분리합니다

#### 6️⃣ Deployment 매니페스트 업데이트

```yaml
- name: Update image tag in manifests
  run: |
    cd manifests-repo
    sed -i "s|image: .*backend:.*|image: docker.io/${DOCKERHUB_USERNAME}/backend:${IMAGE_TAG}|g" deployment.yaml
```

**동작:**
- `deployment.yaml` 파일에서 이미지 태그를 최신 버전으로 업데이트합니다
- `sed` 명령어로 이미지 라인을 교체합니다
- 변경 전/후 로그를 출력하여 확인 가능합니다

#### 7️⃣ 변경사항 커밋 및 푸시

```yaml
- name: Commit and push manifests changes
  run: |
    cd manifests-repo
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git add .
    git commit -m "chore: update backend image to ${IMAGE_TAG}"
    git push origin main
```

**동작:**
- 업데이트된 매니페스트를 Git에 커밋합니다
- `chore: update backend image to abc1234` 형식의 커밋 메시지 생성
- main 브랜치에 푸시하여 ArgoCD가 감지할 수 있도록 합니다

### 필수 GitHub Secrets 설정

워크플로우가 작동하려면 다음 Secrets를 설정해야 합니다:

| Secret 이름 | 설명 | 예시 |
|------------|------|------|
| `BACKEND_PAT` | 백엔드 저장소 접근용 Classic PAT | `ghp_xxxxxxxxxxxx` |
| `DOCKERHUB_USERNAME` | Docker Hub 사용자 이름 | `myusername` |
| `DOCKERHUB_TOKEN` | Docker Hub 액세스 토큰 | `dckr_pat_xxxx` |
| `CLASSIC_PAT` | Manifests 저장소 푸시용 PAT | `ghp_xxxxxxxxxxxx` |
| `MANIFESTS_REPO` | Manifests 저장소 경로 | `org/repo-name` |
| `GIT_USER_NAME` | (선택) Git 커밋 사용자 이름 | `CI Bot` |
| `GIT_USER_EMAIL` | (선택) Git 커밋 이메일 | `ci@example.com` |

### Secrets 설정 방법

1. GitHub 저장소 → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** 클릭
3. 위 표의 각 Secret을 추가

### 전체 워크플로우 흐름

```
코드 푸시 (main 브랜치)
  ↓
백엔드 저장소 체크아웃
  ↓
Docker Hub 로그인
  ↓
Git SHA로 이미지 태그 생성 (예: abc1234)
  ↓
Docker 이미지 빌드
  ↓
Docker Hub에 이미지 푸시 (username/backend:abc1234)
  ↓
Manifests 저장소 클론
  ↓
deployment.yaml 이미지 태그 업데이트
  ↓
변경사항 Git 커밋 및 푸시
  ↓
ArgoCD가 변경 감지 (GitOps)
  ↓
Kubernetes에 자동 배포
  ↓
Argo Rollouts로 점진적 배포 (Canary/Blue-Green)
```

### 워크플로우 실행 확인

1. **GitHub Actions 페이지 접속**
   ```
   https://github.com/your-org/your-repo/actions
   ```

2. **워크플로우 실행 확인**
   - "Backend CI/CD (Docker + Manifests Update)" 워크플로우 클릭
   - 각 단계별 로그 확인 가능

3. **Docker Hub에서 이미지 확인**
   ```
   https://hub.docker.com/r/your-username/backend/tags
   ```

4. **Manifests 저장소에서 커밋 확인**
   - Manifests 저장소의 커밋 히스토리 확인
   - `deployment.yaml` 파일의 이미지 태그가 업데이트되었는지 확인

### 트러블슈팅

#### ❌ 인증 실패

**문제:** `Authentication failed` 또는 `Permission denied`

**해결:**
- GitHub Secrets가 올바르게 설정되었는지 확인
- PAT(Personal Access Token)의 권한 확인:
  - `repo` (전체 저장소 접근)
  - `workflow` (워크플로우 수정)
- Docker Hub Token이 유효한지 확인

#### ❌ 이미지 빌드 실패

**문제:** Docker build 중 오류 발생

**해결:**
```bash
# 로컬에서 빌드 테스트
cd backend-repo
docker build -t test:local .
```

#### ❌ Manifests 업데이트 실패

**문제:** `sed` 명령어가 이미지를 찾지 못함

**해결:**
- `deployment.yaml` 파일의 이미지 형식 확인:
  ```yaml
  # 올바른 형식
  image: docker.io/username/backend:abc1234
  ```
- Manifests 저장소 경로가 올바른지 확인

### 로컬 테스트

워크플로우를 푸시하기 전에 로컬에서 테스트:

```bash
# 1. 백엔드 코드 체크아웃
git clone https://github.com/Softbank-Hackathon-2025-Team-Yellow/runna-backend backend-repo

# 2. Docker 이미지 빌드
cd backend-repo
docker build -t backend:test .

# 3. 이미지 실행 테스트
docker run -p 8080:8080 backend:test

# 4. Manifests 업데이트 테스트
cd ../manifests-repo
sed -i "s|image: .*backend:.*|image: docker.io/username/backend:test|g" deployment.yaml
git diff deployment.yaml
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
│  - Docker Hub 푸시                  │
│  - Manifests 업데이트               │
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
- **컨테이너**: Docker + Docker Hub
- **배포**: ArgoCD (GitOps)
- **점진적 배포**: Argo Rollouts
- **인프라**: Kubernetes
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
- argocd CLI
- GitHub 계정
- Docker Hub 계정

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
