# 🧪 로컬 검증 스크립트

실제 배포 전에 로컬 환경에서 모든 구성 요소를 검증하는 스크립트 모음입니다.

## 📋 사전 요구사항

### 필수 설치
- ✅ **Docker Desktop** (Windows)
- ✅ **PowerShell** 5.1 이상

### 선택 설치 (권장)
- 🔧 **Helm** - Helm Chart 검증용
  ```powershell
  choco install kubernetes-helm
  ```
- 🔧 **kubeval** - YAML 유효성 검증용
  ```powershell
  choco install kubeval
  ```
- 🔧 **Act** - GitHub Actions 로컬 테스트용
  ```powershell
  choco install act-cli
  ```

## 🚀 빠른 시작

### 전체 검증 실행 (권장)
```powershell
# 프로젝트 루트에서 실행
.\scripts\local-validation\run-all-tests.ps1
```

이 명령어는 다음을 순차적으로 실행합니다:
1. Dockerfile 빌드 테스트
2. 컨테이너 실행 테스트
3. Helm Chart 검증
4. GitHub Actions 워크플로우 검증
5. 전체 요약

### 개별 테스트 실행

#### 1. Dockerfile 빌드 테스트
```powershell
.\scripts\local-validation\01-test-backend-dockerfile.ps1
```

**검증 내용:**
- ✅ Dockerfile 존재 확인
- ✅ Docker 실행 상태 확인
- ✅ 이미지 빌드 성공
- ✅ 이미지 크기 확인
- ✅ 멀티 스테이지 빌드 확인

**예상 소요 시간:** 2-5분 (첫 빌드)

#### 2. 컨테이너 실행 테스트
```powershell
.\scripts\local-validation\02-test-backend-container.ps1
```

**검증 내용:**
- ✅ 컨테이너 실행
- ✅ 포트 바인딩 (8000)
- ✅ Health Check 엔드포인트
- ✅ API 문서 접근
- ✅ 리소스 사용량 확인

**예상 소요 시간:** 30초

**접근 URL:**
- Health Check: http://localhost:8000/health
- API 문서: http://localhost:8000/docs

#### 3. Helm Chart 검증
```powershell
.\scripts\local-validation\03-test-helm-chart.ps1
```

**검증 내용:**
- ✅ Helm 설치 확인
- ✅ Chart.yaml 검증
- ✅ Helm Lint 실행
- ✅ Template 렌더링
- ✅ Dry-run 테스트

**예상 소요 시간:** 1분

#### 4. GitHub Actions 검증
```powershell
.\scripts\local-validation\04-test-github-actions.ps1
```

**검증 내용:**
- ✅ 워크플로우 파일 존재
- ✅ YAML 문법 검증
- ✅ 필수 요소 확인
- ✅ Secrets 사용 확인
- ✅ Matrix Strategy 확인

**예상 소요 시간:** 10초

#### 5. 전체 요약
```powershell
.\scripts\local-validation\05-validation-summary.ps1
```

**제공 정보:**
- 📊 전체 검증 결과 요약
- 🎯 다음 단계 안내
- 🔧 유용한 명령어
- 📚 참고 문서

## 🎯 검증 시나리오

### 시나리오 1: 처음 검증하는 경우
```powershell
# 전체 검증 실행
.\scripts\local-validation\run-all-tests.ps1

# 결과 확인
# - 모든 테스트 통과 시: 실제 배포 준비 완료
# - 일부 실패 시: 해당 스크립트 개별 실행하여 디버깅
```

### 시나리오 2: Dockerfile만 수정한 경우
```powershell
# Dockerfile 빌드만 재테스트
.\scripts\local-validation\01-test-backend-dockerfile.ps1

# 컨테이너 실행 테스트
.\scripts\local-validation\02-test-backend-container.ps1
```

### 시나리오 3: Helm Chart만 수정한 경우
```powershell
# Helm Chart 검증만 실행
.\scripts\local-validation\03-test-helm-chart.ps1
```

### 시나리오 4: 특정 테스트 건너뛰기
```powershell
# Docker 테스트 건너뛰기 (이미 빌드된 경우)
.\scripts\local-validation\run-all-tests.ps1 -SkipDocker

# 컨테이너 테스트 건너뛰기
.\scripts\local-validation\run-all-tests.ps1 -SkipContainer

# 여러 테스트 건너뛰기
.\scripts\local-validation\run-all-tests.ps1 -SkipDocker -SkipContainer
```

## 🔧 문제 해결

### Docker 빌드 실패
```powershell
# Docker Desktop 실행 확인
docker version

# 디스크 공간 확인
docker system df

# 캐시 정리
docker system prune -a
```

### 컨테이너 실행 실패
```powershell
# 포트 충돌 확인
netstat -ano | findstr :8000

# 기존 컨테이너 정리
docker rm -f backend-test

# 로그 확인
docker logs backend-test
```

### Helm 검증 실패
```powershell
# Helm 설치 확인
helm version

# Chart 문법 확인
helm lint helm/charts/platform-service

# 상세 에러 확인
helm template backend helm/charts/platform-service --debug
```

### Health Check 실패
**원인:** 데이터베이스 연결 필요

**해결:**
- 로컬 PostgreSQL 실행
- 또는 환경변수에서 DATABASE_URL 제거
- 또는 Health Check 엔드포인트 수정

## 📊 검증 결과 해석

### ✅ 모든 테스트 통과
```
통과: 4 / 4 (100%)
  ✅ Dockerfile
  ✅ Container
  ✅ HelmChart
  ✅ GitHubActions
```

**의미:** 로컬 검증 완료! 실제 배포 준비 가능

**다음 단계:**
1. 팀원들에게 필요한 정보 요청
2. K8s 클러스터 설정
3. 실제 배포 시작

### ⚠️ 일부 테스트 실패
```
통과: 2 / 4 (50%)
  ✅ Dockerfile
  ❌ Container
  ✅ HelmChart
  ❌ GitHubActions
```

**의미:** 일부 구성 요소에 문제 있음

**조치:**
1. 실패한 테스트 개별 실행
2. 에러 메시지 확인
3. 문제 해결 후 재테스트

## 🧹 정리

### 테스트 컨테이너 정리
```powershell
# 컨테이너 중지 및 제거
docker stop backend-test
docker rm backend-test

# 이미지 제거
docker rmi backend-local-test:latest
```

### 전체 정리
```powershell
# 모든 미사용 리소스 정리
docker system prune -a

# 볼륨까지 정리
docker system prune -a --volumes
```

## 📚 참고 문서

- [실제 배포 체크리스트](../../docs/real-deployment-checklist.md)
- [필요한 정보 목록](../../docs/deployment-info-needed.md)
- [설계 문서](../../.kiro/specs/serverless-cicd-pipeline/design.md)
- [작업 목록](../../.kiro/specs/serverless-cicd-pipeline/tasks.md)

## 💡 팁

### 빠른 반복 테스트
```powershell
# 이미지 빌드 + 컨테이너 실행 + 요약
.\scripts\local-validation\01-test-backend-dockerfile.ps1
.\scripts\local-validation\02-test-backend-container.ps1
.\scripts\local-validation\05-validation-summary.ps1
```

### 로그 실시간 확인
```powershell
# 컨테이너 로그 실시간 확인
docker logs -f backend-test

# 다른 터미널에서 Health Check
curl http://localhost:8000/health
```

### 이미지 크기 최적화 확인
```powershell
# 이미지 레이어 분석
docker history backend-local-test:latest

# 이미지 크기 비교
docker images | findstr backend
```

## 🚀 다음 단계

로컬 검증이 완료되면:

1. **정보 수집**
   - K8s 클러스터 접근 권한
   - AWS 리소스 정보
   - 도메인 정보

2. **백엔드 저장소 통합**
   - Dockerfile PR 생성
   - GitHub Actions 추가
   - .dockerignore 추가

3. **실제 배포**
   - Namespace 생성
   - Secrets 생성
   - ArgoCD 설치
   - 첫 배포 실행

---

**문제가 있으면 팀 슬랙에 공유해주세요! 🙌**
