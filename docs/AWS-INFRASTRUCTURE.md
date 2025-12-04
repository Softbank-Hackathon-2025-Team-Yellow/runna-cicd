# AWS Infrastructure 구조

## 📋 개요

**소현님 담당 인프라 구조**

### 핵심 포인트
- **Frontend**: AWS Amplify (VPC 외부)
- **Backend**: K3s 기반 EC2 클러스터 (Private Subnet)
- **Database**: RDS PostgreSQL (Private Subnet)
- **Storage**: S3 (User Function Storage)
- **접속**: AWS SSM (No Bastion)

---

## 🏗️ VPC 구조

### CIDR
```
10.0.0.0/16
```

### Subnet 분할

#### Public Subnet A/B
```
- ALB (Application Load Balancer)
- NAT Gateway
```

#### Private-App Subnet A/B
```
- ECS Fargate Tasks (Backend API) ⚠️ 우리는 K3s 사용
- K8s Worker - ops
- K8s Worker - build
- K8s Worker - run
```

#### Private-Control Subnet
```
- K8s Master
- K8s etcd (선택)
```

#### Private-DB Subnet A/B
```
- RDS PostgreSQL (Multi-AZ)
```

#### Management Subnet
```
- VPC Endpoint (SSM, EC2 Messages)
- VPC Endpoint (S3, ECR, CloudWatch Logs)
- Secrets Manager
```

---

## 🖥️ K3s 클러스터 구성

### EC2 인스턴스

| Name | vCPU | RAM | Subnet | 역할 |
|------|------|-----|--------|------|
| k8s-master | 2 | 4GB | Private-Control | 클러스터 관리 |
| k8s-worker-ops | 2 | 6GB | Private-App | 운영 도구 (ArgoCD, Monitoring) |
| k8s-worker-build | 4 | 8GB | Private-App | 함수 빌드 전용 |
| k8s-worker-run | 2 | 6GB | Private-App | 함수 실행 (Knative) |

### 특징
- ✅ Public IP 없음 (완전 Private)
- ✅ SSM Agent로 접속
- ✅ VPC Endpoint로 ECR/S3 접근
- ✅ NAT Gateway로 외부 통신

### Node Labels (예상)
```yaml
k8s-worker-ops:
  role: ops
  
k8s-worker-build:
  role: build
  
k8s-worker-run:
  role: run
```

---

## 🌐 네트워크 구조

### 3-Tier 망분리

| Zone | 구성 요소 |
|------|-----------|
| **Public Zone** | ALB, NAT Gateway |
| **App Private Zone** | ECS, K8s Workers |
| **Data Private Zone** | RDS PostgreSQL |

### 트래픽 흐름

```
[사용자]
  ↓
[Amplify Frontend]
  ↓ HTTPS
[ALB - Public]
  ↓
[K8s Ingress - Private]
  ↓
[Backend API / Knative Service]
  ↓
[RDS PostgreSQL]
```

### Security Group 규칙

```
ALB → K8s Ingress: 허용
K8s → RDS: 허용 (특정 SG만)
K8s → 외부: NAT Gateway
K8s → ECR/S3: VPC Endpoint
```

---

## 🔐 보안 구조

### SSM 기반 EC2 접속
```
개발자
  ↓
AWS SSM Session Manager
  ↓
VPC Endpoint (ssm, ssmmessages)
  ↓
EC2 (Private Subnet)
```

**장점:**
- ✅ Bastion 불필요
- ✅ Public IP 불필요
- ✅ 완전 내부망 접속
- ✅ 접속 로그 자동 기록

### VPC Endpoint 목록
```
- com.amazonaws.{region}.ssm
- com.amazonaws.{region}.ssmmessages
- com.amazonaws.{region}.ec2messages
- com.amazonaws.{region}.s3
- com.amazonaws.{region}.ecr.api
- com.amazonaws.{region}.ecr.dkr
- com.amazonaws.{region}.logs
- com.amazonaws.{region}.secretsmanager
```

---

## 💾 Storage 구조

### S3 Functions Bucket
```
s3://runna-functions/
├── function-A/
│   ├── source.zip
│   ├── metadata.json
│   └── build/
│       └── image.tar
├── function-B/
│   ├── source.zip
│   └── metadata.json
└── ...
```

**접근 권한:**
- `k8s-worker-build`: Read/Write (빌드 결과 저장)
- `k8s-worker-run`: Read (함수 실행)
- Backend API: Read/Write (메타데이터 관리)

### ECR (Elastic Container Registry)
```
{account-id}.dkr.ecr.{region}.amazonaws.com/
├── backend
├── worker
└── user-functions/
    ├── function-A
    └── function-B
```

---

## 🔄 CI/CD 흐름

### Backend 배포
```
GitHub
  ↓
GitHub Actions
  ↓
Docker Build
  ↓
ECR Push (VPC Endpoint)
  ↓
Helm Values Update
  ↓
Git Commit & Push
  ↓
ArgoCD Sync (k8s-worker-ops)
  ↓
K8s Deployment
```

### 사용자 함수 배포
```
사용자: 함수 생성
  ↓
Backend API: 코드 저장 (S3)
  ↓
k8s-worker-build: 빌드
  ↓
ECR Push
  ↓
Knative Service 생성 (k8s-worker-run)
  ↓
함수 실행 준비 완료
```

---

## 📊 Observability

### CloudWatch Logs
```
- /aws/ec2/k8s-master
- /aws/ec2/k8s-worker-ops
- /aws/ec2/k8s-worker-build
- /aws/ec2/k8s-worker-run
- /aws/rds/postgresql
- /aws/lambda/functions
```

### Monitoring
```
- CloudWatch Metrics
- X-Ray (선택)
- S3 Access Logs
- ALB Access Logs
- VPC Flow Logs
```

### Security
```
- GuardDuty
- Security Hub
- AWS Config
- CloudTrail
```

---

## 🎯 우리가 반영해야 할 사항

### 1. Ingress Controller
**현재:** Nginx Ingress
**실제:** ALB Ingress Controller

**수정 필요:**
```yaml
annotations:
  kubernetes.io/ingress.class: "alb"
  alb.ingress.kubernetes.io/scheme: internet-facing
  alb.ingress.kubernetes.io/target-type: ip
```

### 2. NodeSelector
**추가 필요:**
```yaml
# Knative Service
nodeSelector:
  role: run

# ArgoCD
nodeSelector:
  role: ops
```

### 3. ENV 변수
**추가 필요:**
```yaml
- name: S3_FUNCTIONS_BUCKET
  value: "runna-functions"
- name: AWS_REGION
  value: "{region}"
```

### 4. IAM Role
**필요:**
- Backend Pod → S3/ECR 접근
- Worker-build Pod → ECR Push
- Worker-run Pod → S3/ECR 접근

---

## 📋 소현님께 확인 필요한 정보

### 필수 정보
- [ ] AWS 리전
- [ ] ECR 레지스트리 URL
- [ ] S3 Functions Bucket 이름
- [ ] ALB DNS 이름
- [ ] RDS 엔드포인트
- [ ] VPC ID
- [ ] Subnet IDs

### K3s 클러스터 정보
- [ ] kubectl config 파일
- [ ] 클러스터 엔드포인트
- [ ] Node Labels 확인
- [ ] Ingress Controller 종류 (ALB? Traefik?)
- [ ] cert-manager 설치 여부

### 권한 정보
- [ ] IAM Role ARN (GitHub Actions용)
- [ ] IAM Role ARN (Pod용)
- [ ] ECR 접근 권한
- [ ] S3 접근 권한

---

**작성일:** 2024-12-04
**작성자:** 서영
**출처:** 소현님 인프라 설계 문서
