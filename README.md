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
