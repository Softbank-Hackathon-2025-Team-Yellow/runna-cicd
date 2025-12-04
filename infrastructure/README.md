# Backend 배포 인프라 설정

이 디렉토리는 Backend 서비스를 AWS ECS Fargate에 배포하기 위한 인프라 설정 파일들을 포함합니다.

## 📁 디렉토리 구조

```
infrastructure/
├── codebuild/
│   └── backend-build-project.json    # CodeBuild 프로젝트 설정
├── codepipeline/
│   └── backend-pipeline.json         # CodePipeline 설정
├── ecs/
│   └── backend-task-definition.json  # ECS Task Definition
└── README.md
```

## 🚀 빠른 시작

### 1. 사전 준비
```bash
# IAM 계정 발급 (인프라팀에게 요청)
# AWS CLI 설정
aws configure

# GitHub Token 설정
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxx
```

### 2. GitHub 연결 설정
```bash
# Linux/Mac
./scripts/setup-github-connection.sh

# Windows PowerShell
.\scripts\setup-github-connection.ps1 -GitHubToken "ghp_xxxxxxxxxxxxx"
```

### 3. 설정 파일 수정
각 JSON 파일에서 다음 플레이스홀더를 실제 값으로 교체:
- `{AWS_ACCOUNT_ID}`: AWS 계정 ID
- `{AWS_REGION}`: AWS 리전 (예: us-east-1)
- `{GITHUB_OWNER}`: GitHub 사용자명 또는 조직명
- `{GITHUB_REPO}`: GitHub 저장소명
- `{ARTIFACT_BUCKET_NAME}`: S3 Artifact 버킷명

### 4. 인프라 생성
```bash
# CodeBuild 프로젝트 생성
aws codebuild create-project \
  --cli-input-json file://infrastructure/codebuild/backend-build-project.json

# ECS Task Definition 등록
aws ecs register-task-definition \
  --cli-input-json file://infrastructure/ecs/backend-task-definition.json

# CodePipeline 생성
aws codepipeline create-pipeline \
  --cli-input-json file://infrastructure/codepipeline/backend-pipeline.json
```

## 📚 상세 문서

- [배포 가이드](../docs/backend-deployment-guide.md)
- [배포 체크리스트](../docs/backend-deployment-checklist.md)

## 🔧 설정 파일 설명

### CodeBuild Project (`codebuild/backend-build-project.json`)
- Docker 이미지 빌드
- ECR에 이미지 푸시
- imagedefinitions.json 생성

### CodePipeline (`codepipeline/backend-pipeline.json`)
- Source: GitHub 저장소
- Build: CodeBuild 프로젝트
- Deploy: ECS Fargate

### ECS Task Definition (`ecs/backend-task-definition.json`)
- 컨테이너 설정 (CPU, 메모리)
- 환경변수 및 Secrets
- Health check 설정
- 로그 설정

## 🤝 협업 포인트

### 인프라팀에게 필요한 것
1. IAM 계정 및 권한
2. ECR 저장소 URL
3. VPC/Subnet/Security Group 정보
4. RDS/Redis 엔드포인트
5. S3 Artifact 버킷
6. Route53 도메인
7. ACM 인증서

### 백엔드팀에게 필요한 것
1. 환경변수 목록
2. Health check 엔드포인트
3. 포트 번호
4. Dockerfile 확인

## 🔍 트러블슈팅

### CodeBuild 빌드 실패
```bash
# 로그 확인
aws codebuild batch-get-builds --ids {BUILD_ID}
```

### ECS Task 시작 실패
```bash
# Task 상태 확인
aws ecs describe-tasks --cluster main-cluster --tasks {TASK_ARN}

# 로그 확인
aws logs tail /ecs/backend-service --follow
```

### Pipeline 실행 실패
```bash
# Pipeline 상태 확인
aws codepipeline get-pipeline-state --name backend-deployment-pipeline
```

## 📞 도움 요청
- IAM/권한: 현성님
- 네트워크/인프라: 소현님
- 모니터링: 동규님
