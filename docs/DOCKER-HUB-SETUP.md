# Docker Hub 설정 가이드

이 문서는 ECR에서 Docker Hub로 전환하는 과정을 설명합니다.

## 📋 완료된 작업

### ✅ 1. GitHub Actions 수정
- ECR 인증 → Docker Hub 인증으로 변경
- AWS OIDC 제거
- Docker Hub 로그인 추가
- 이미지 경로 변경: `ECR_REGISTRY` → `DOCKERHUB_USERNAME`

### ✅ 2. Helm Values 수정
모든 Values 파일에서 이미지 저장소 변경:
```yaml
# 변경 전 (ECR)
image:
  repository: 123456789.dkr.ecr.us-east-1.amazonaws.com/backend

# 변경 후 (Docker Hub)
image:
  repository: docker.io/YOUR_DOCKERHUB_USERNAME/backend

# imagePullSecrets 추가 (Private Repository용)
imagePullSecrets:
  - name: dockerhub-secret
```

### ✅ 3. K8s Secret 설정 스크립트 생성
- `scripts/setup-dockerhub-secret.ps1` (Windows PowerShell)
- `scripts/setup-dockerhub-secret.sh` (Linux/Mac Bash)

## 🎯 다음 단계 (수동 작업 필요)

### 1. Docker Hub Username 업데이트

**모든 Helm Values 파일에서 `YOUR_DOCKERHUB_USERNAME`을 실제 username으로 변경:**

#### Windows (PowerShell)
```powershell
# 일괄 변경
Get-ChildItem helm/values -Filter "*.yaml" | ForEach-Object {
    (Get-Content $_.FullName) -replace 'YOUR_DOCKERHUB_USERNAME', 'your-actual-username' | Set-Content $_.FullName
}
```

#### Linux/Mac (Bash)
```bash
# 일괄 변경
find helm/values -name "*.yaml" -exec sed -i 's/YOUR_DOCKERHUB_USERNAME/your-actual-username/g' {} +
```

### 2. K8s Secret 생성

**Docker Hub 인증 정보를 K8s에 저장:**

#### Windows (PowerShell) - 권장
```powershell
# 환경 변수 설정
$env:DOCKERHUB_USERNAME = "your-username"
$env:DOCKERHUB_TOKEN = "dckr_pat_xxxxxxxxxxxxx"
$env:DOCKERHUB_EMAIL = "your-email@example.com"

# Secret 생성 스크립트 실행
.\scripts\setup-dockerhub-secret.ps1

# 또는 파라미터로 직접 전달
.\scripts\setup-dockerhub-secret.ps1 -Username "your-username" -Token "dckr_pat_xxxxxxxxxxxxx" -Email "your-email@example.com"

# 특정 Namespace에 생성
.\scripts\setup-dockerhub-secret.ps1 -Username "your-username" -Token "dckr_pat_xxxxxxxxxxxxx" -Namespace "production"
```

#### Linux/Mac (Bash)
```bash
# 환경 변수 설정
export DOCKERHUB_USERNAME="your-username"
export DOCKERHUB_TOKEN="dckr_pat_xxxxxxxxxxxxx"
export DOCKERHUB_EMAIL="your-email@example.com"

# Secret 생성 스크립트 실행
chmod +x scripts/setup-dockerhub-secret.sh
./scripts/setup-dockerhub-secret.sh
```

#### 직접 kubectl 명령어 사용
```bash
kubectl create secret docker-registry dockerhub-secret \
    --docker-server=docker.io \
    --docker-username=your-username \
    --docker-password=dckr_pat_xxxxxxxxxxxxx \
    --docker-email=your-email@example.com
```

### 3. GitHub Secrets 확인

**GitHub Repository Settings → Secrets and variables → Actions에서 확인:**

- ✅ `DOCKERHUB_USERNAME`: your-username
- ✅ `DOCKERHUB_TOKEN`: dckr_pat_xxxxxxxxxxxxx

### 4. 테스트

**코드 푸시하여 CI/CD 파이프라인 테스트:**

```bash
git add .
git commit -m "feat: migrate from ECR to Docker Hub"
git push origin main
```

## 🔍 확인 방법

### GitHub Actions 로그 확인
1. GitHub Repository → Actions 탭
2. 최신 워크플로우 실행 확인
3. "Login to Docker Hub" 단계 성공 확인
4. "Push to Docker Hub" 단계 성공 확인

### Docker Hub 확인
1. https://hub.docker.com 로그인
2. Repositories → backend 확인
3. 새로운 태그 업로드 확인

### K8s Pod 확인
```bash
# Pod 상태 확인
kubectl get pods

# 이미지 Pull 로그 확인
kubectl describe pod <pod-name>

# Secret 확인
kubectl get secret dockerhub-secret
```

## ⚠️ 주의사항

### 1. Private Repository
- Docker Hub Free 계정: Private Repository 1개만 무료
- 더 필요하면 Pro 계정 ($5/월) 필요

### 2. Rate Limit
- Anonymous: 100 pulls/6시간
- Authenticated: 200 pulls/6시간
- 초과 시 배포 실패 가능

### 3. 보안
- Access Token을 절대 코드에 하드코딩하지 마세요
- GitHub Secrets와 K8s Secret에만 저장
- 정기적으로 Token 갱신 권장

### 4. 네임스페이스
- `dockerhub-secret`은 default namespace에 생성됨
- 다른 namespace에서 사용하려면 해당 namespace에도 생성 필요

```bash
# 특정 namespace에 Secret 생성
kubectl create secret docker-registry dockerhub-secret \
    --docker-server=docker.io \
    --docker-username=your-username \
    --docker-password=dckr_pat_xxxxxxxxxxxxx \
    --docker-email=your-email@example.com \
    --namespace=your-namespace
```

## 🚀 프로덕션 전환 계획

나중에 ECR로 다시 전환하거나 Organization 계정으로 업그레이드할 때:

1. **Organization 계정 생성**
2. **Repository 이전**
3. **GitHub Secrets 업데이트**
4. **Helm Values 업데이트**
5. **K8s Secret 업데이트**

## 📞 문제 해결

### Docker Hub 로그인 실패
```
Error: unauthorized: authentication required
```
→ GitHub Secrets 확인 (DOCKERHUB_USERNAME, DOCKERHUB_TOKEN)

### K8s ImagePullBackOff
```
Failed to pull image: unauthorized
```
→ dockerhub-secret 생성 확인
→ imagePullSecrets 설정 확인

### Rate Limit 초과
```
Too Many Requests
```
→ 잠시 대기 후 재시도
→ Pro 계정 업그레이드 고려

## 📚 참고 자료

- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [Kubernetes imagePullSecrets](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)
- [GitHub Actions Docker Login](https://github.com/docker/login-action)

## 🎯 빠른 시작 체크리스트

- [ ] 1. Docker Hub Username을 Helm Values 파일에 업데이트
- [ ] 2. K8s Secret 생성 (PowerShell 스크립트 실행)
- [ ] 3. GitHub Secrets 확인 (DOCKERHUB_USERNAME, DOCKERHUB_TOKEN)
- [ ] 4. 코드 푸시 및 CI/CD 테스트
- [ ] 5. Docker Hub에서 이미지 업로드 확인
- [ ] 6. K8s Pod가 정상적으로 이미지 Pull 하는지 확인
