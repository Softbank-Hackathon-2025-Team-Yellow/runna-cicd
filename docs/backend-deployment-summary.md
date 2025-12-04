# Backend 배포 설정 완료 요약

## ✅ 생성된 파일들

### 1. 빌드 설정
- `services/backend/buildspec.yml` - CodeBuild 빌드 스크립트

### 2. 인프라 설정
- `infrastructure/codebuild/backend-build-project.json` - CodeBuild 프로젝트 정의
- `infrastructure/codepipeline/backend-pipeline.json` - CodePipeline 정의
- `infrastructure/ecs/backend-task-definition.json` - ECS Task Definition

### 3. 스크립트
- `scripts/setup-github-connection.sh` - GitHub 연결 설정 (Linux/Mac)
- `scripts/setup-github-connection.ps1` - GitHub 연결 설정 (Windows)

### 4. 문서
- `docs/backend-deployment-guide.md` - 상세 배포 가이드
- `docs/backend-deployment-checklist.md` - 단계별 체크리스트
- `infrastructure/README.md` - 인프라 설정 README

---

## 🎯 IAM 없이 지금 할 수 있는 것

### ✅ 1. 설정 파일 검토 및 수정
모든 JSON 파일에서 플레이스홀더를 실제 값으로 교체 준비:
- `{AWS_ACCOUNT_ID}` → 실제 AWS 계정 ID
- `{AWS_REGION}` → us-east-1 (또는 사용할 리전)
- `{GITHUB_OWNER}` → GitHub 사용자명
- `{GITHUB_REPO}` → 저장소명
- `{ARTIFACT_BUCKET_NAME}` → S3 버킷명

### ✅ 2. GitHub Token 준비
1. GitHub → Settings → Developer settings → Personal access tokens
2. "Generate new token (classic)" 클릭
3. 권한 선택:
   - ✅ `repo` (전체 저장소 접근)
   - ✅ `admin:repo_hook` (웹훅 생성)
4. Token 복사해서 안전하게 보관

### ✅ 3. 백엔드팀과 협업
확인할 사항:
- [ ] Backend Dockerfile 위치 확인 (`services/backend/Dockerfile`)
- [ ] 필요한 환경변수 목록 받기
  - DATABASE_URL
  - REDIS_URL
  - 기타
- [ ] Health check 엔드포인트 확인 (기본: `/`)
- [ ] 포트 번호 확인 (기본: 8000)
- [ ] 로컬에서 Docker 빌드 테스트

### ✅ 4. 로컬 Docker 테스트
```bash
# Backend 디렉토리로 이동
cd services/backend

# Docker 이미지 빌드
docker build -t backend-test .

# 컨테이너 실행
docker run -p 8000:8000 backend-test

# 다른 터미널에서 테스트
curl http://localhost:8000/
curl http://localhost:8000/docs
```

### ✅ 5. 인프라팀에게 요청 준비
필요한 정보 목록 작성:
- [ ] IAM 계정 (현성님)
- [ ] ECR 저장소 URL (소현님)
- [ ] VPC/Subnet/Security Group 정보 (소현님)
- [ ] RDS PostgreSQL 엔드포인트 (소현님)
- [ ] Redis 엔드포인트 (소현님)
- [ ] S3 Artifact 버킷 (소현님)
- [ ] Route53 도메인 (소현님)
- [ ] ACM 인증서 (소현님)

### ✅ 6. 문서 읽기 및 이해
- `docs/backend-deployment-guide.md` 읽기
- `docs/backend-deployment-checklist.md` 검토
- 배포 플로우 이해하기

---

## 🚀 IAM 받은 후 실행 순서

### Phase 1: GitHub 연결 (5분)
```bash
# Windows PowerShell
.\scripts\setup-github-connection.ps1 -GitHubToken "ghp_xxxxxxxxxxxxx"
```

### Phase 2: 설정 파일 수정 (10분)
모든 JSON 파일의 플레이스홀더를 실제 값으로 교체

### Phase 3: CodeBuild 생성 (5분)
```bash
aws codebuild create-project \
  --cli-input-json file://infrastructure/codebuild/backend-build-project.json
```

### Phase 4: ECS 설정 (15분)
```bash
# Task Definition 등록
aws ecs register-task-definition \
  --cli-input-json file://infrastructure/ecs/backend-task-definition.json

# Service 생성 (ALB 정보 필요)
aws ecs create-service ...
```

### Phase 5: CodePipeline 생성 (5분)
```bash
aws codepipeline create-pipeline \
  --cli-input-json file://infrastructure/codepipeline/backend-pipeline.json
```

### Phase 6: 배포 테스트 (10분)
```bash
# Pipeline 수동 실행
aws codepipeline start-pipeline-execution \
  --name backend-deployment-pipeline

# 상태 확인
aws codepipeline get-pipeline-state \
  --name backend-deployment-pipeline
```

### Phase 7: 도메인 & SSL (20분)
- ALB에 HTTPS Listener 추가
- Route53에 A 레코드 추가
- HTTPS 테스트

**총 예상 시간: 약 1-2시간**

---

## 📋 배포 플로우

```
개발자가 코드 푸시
    ↓
GitHub (main 브랜치)
    ↓
CodePipeline 자동 트리거
    ↓
CodeBuild (Docker 이미지 빌드)
    ↓
ECR (이미지 저장)
    ↓
ECS Fargate (자동 배포)
    ↓
ALB (로드밸런싱)
    ↓
Route53 + ACM (도메인 + SSL)
    ↓
사용자가 HTTPS로 API 사용
```

---

## 🎯 최종 목표

### 배포 완료 시 달성되는 것
1. ✅ Backend API가 `https://api.yourdomain.com`으로 제공됨
2. ✅ `/docs`에서 Swagger 문서 확인 가능
3. ✅ GitHub에 코드 푸시하면 자동으로 배포됨
4. ✅ ECS Fargate에서 컨테이너 실행됨
5. ✅ CloudWatch에서 로그 확인 가능
6. ✅ ALB를 통한 로드밸런싱
7. ✅ SSL 인증서로 HTTPS 보안 통신

### 검증 방법
```bash
# API 테스트
curl https://api.yourdomain.com/
curl https://api.yourdomain.com/docs

# 상태 확인
aws ecs describe-services --cluster main-cluster --services backend-service
aws codepipeline get-pipeline-state --name backend-deployment-pipeline

# 로그 확인
aws logs tail /ecs/backend-service --follow
```

---

## 🤝 협업 체크리스트

### 인프라팀 (현성/소현/동규)
- [ ] IAM 계정 발급 (현성)
- [ ] ECR 저장소 생성 (소현)
- [ ] VPC/Subnet/SG 정보 제공 (소현)
- [ ] RDS/Redis 엔드포인트 제공 (소현)
- [ ] S3 Artifact 버킷 생성 (소현)
- [ ] Route53 도메인 설정 (소현)
- [ ] ACM 인증서 생성 (소현)
- [ ] Prometheus/Grafana 연동 (동규)

### 백엔드팀
- [ ] 환경변수 목록 제공
- [ ] Health check 엔드포인트 확인
- [ ] Dockerfile 검증
- [ ] 로컬 테스트 완료

### 서영님 (본인)
- [ ] GitHub Token 생성
- [ ] 설정 파일 수정
- [ ] CodeBuild 프로젝트 생성
- [ ] ECS Task Definition 등록
- [ ] ECS Service 생성
- [ ] CodePipeline 생성
- [ ] 배포 테스트
- [ ] 도메인 & SSL 설정
- [ ] 문서화

---

## 📞 질문이 있을 때

### 기술적 질문
- AWS 설정: 소현님
- IAM/권한: 현성님
- 모니터링: 동규님
- Backend 코드: 백엔드팀

### 긴급 상황
- 배포 실패: CloudWatch Logs 확인 후 팀에 공유
- 서비스 다운: ECS Service 상태 확인 후 롤백

---

## 🎉 다음 단계

IAM 계정을 받으면:
1. `docs/backend-deployment-checklist.md` 열기
2. 체크리스트 따라 하나씩 진행
3. 막히는 부분은 팀원들에게 질문
4. 완료되면 팀에 공유!

**화이팅! 🚀**
