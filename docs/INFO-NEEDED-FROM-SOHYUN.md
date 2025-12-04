# 소현님께 필요한 정보 체크리스트

## 🎯 인프라 프로비저닝 완료 후 필요한 정보

### 1. AWS 기본 정보

#### 리전 & 계정
- [ ] **AWS 리전** (예: `ap-northeast-2`, `us-east-1`)
- [ ] **AWS Account ID**
- [ ] **VPC ID**

#### Subnet IDs
- [ ] **Public Subnet A ID**
- [ ] **Public Subnet B ID**
- [ ] **Private-App Subnet A ID**
- [ ] **Private-App Subnet B ID**
- [ ] **Private-Control Subnet ID**
- [ ] **Private-DB Subnet A ID**
- [ ] **Private-DB Subnet B ID**

---

### 2. ECR (Container Registry)

- [ ] **ECR 레지스트리 URL**
  ```
  예: 123456789012.dkr.ecr.ap-northeast-2.amazonaws.com
  ```

- [ ] **ECR 저장소 이름**
  ```
  - backend
  - worker
  - user-functions (선택)
  ```

---

### 3. S3 (Functions Storage)

- [ ] **S3 Bucket 이름**
  ```
  예: runna-functions
  ```

- [ ] **S3 Bucket 리전** (VPC와 동일한지 확인)

---

### 4. RDS (Database)

- [ ] **RDS 엔드포인트**
  ```
  예: runna-db.xxxxx.ap-northeast-2.rds.amazonaws.com:5432
  ```

- [ ] **Database 이름**
  ```
  예: runna_db
  ```

- [ ] **Master Username**
  ```
  예: postgres
  ```

- [ ] **Master Password** (Secrets Manager에 저장 권장)

- [ ] **Secrets Manager ARN** (DB 정보 저장용)

---

### 5. ALB (Load Balancer)

- [ ] **ALB DNS 이름**
  ```
  예: runna-alb-123456.ap-northeast-2.elb.amazonaws.com
  ```

- [ ] **ALB ARN**

- [ ] **Target Group ARN** (Backend용)

---

### 6. TLS/SSL 인증서

- [ ] **ACM Certificate ARN**
  ```
  예: arn:aws:acm:ap-northeast-2:123456789012:certificate/xxxxx
  ```

- [ ] **도메인 이름**
  ```
  - api.runna.dev (Backend API)
  - *.runna.dev (Wildcard for user functions)
  ```

---

### 7. K3s 클러스터 접근

#### kubectl 설정
- [ ] **kubeconfig 파일** 또는 클러스터 접근 방법
- [ ] **클러스터 엔드포인트**
  ```
  예: https://10.0.1.10:6443
  ```

#### Node 정보
- [ ] **k8s-master IP**
- [ ] **k8s-worker-ops IP**
- [ ] **k8s-worker-build IP**
- [ ] **k8s-worker-run IP**

#### Node Labels 확인
```bash
kubectl get nodes --show-labels
```

- [ ] **worker-ops 노드 Label**
  ```
  예: role=ops
  ```

- [ ] **worker-build 노드 Label**
  ```
  예: role=build
  ```

- [ ] **worker-run 노드 Label**
  ```
  예: role=run
  ```

---

### 8. Ingress Controller

- [ ] **Ingress Controller 종류**
  ```
  - [ ] AWS ALB Ingress Controller
  - [ ] Traefik (K3s 기본)
  - [ ] Nginx Ingress
  - [ ] Knative Kourier
  - [ ] Istio
  ```

- [ ] **Ingress Class 이름**
  ```
  예: alb, traefik, nginx
  ```

---

### 9. IAM Roles & Permissions

#### GitHub Actions용
- [ ] **IAM Role ARN** (OIDC 인증용)
  ```
  예: arn:aws:iam::123456789012:role/GitHubActionsRole
  ```

- [ ] **권한 확인**
  - [ ] ECR Push
  - [ ] S3 Read/Write
  - [ ] Secrets Manager Read

#### K8s Pod용 (IRSA - IAM Roles for Service Accounts)
- [ ] **Backend Pod IAM Role ARN**
  - [ ] S3 Read/Write (Functions Bucket)
  - [ ] ECR Pull
  - [ ] Secrets Manager Read
  - [ ] RDS Connect

- [ ] **Worker-build Pod IAM Role ARN**
  - [ ] ECR Push
  - [ ] S3 Read/Write

- [ ] **Worker-run Pod IAM Role ARN**
  - [ ] S3 Read
  - [ ] ECR Pull

---

### 10. K3s 클러스터 구성 확인

#### 설치된 컴포넌트
- [ ] **ArgoCD 설치 여부**
  ```bash
  kubectl get pods -n argocd
  ```

- [ ] **Argo Rollouts 설치 여부**
  ```bash
  kubectl get pods -n argo-rollouts
  ```

- [ ] **cert-manager 설치 여부**
  ```bash
  kubectl get pods -n cert-manager
  ```

- [ ] **Knative Serving 설치 여부**
  ```bash
  kubectl get pods -n knative-serving
  ```

#### 설치 필요 여부
- [ ] ArgoCD 설치 필요?
- [ ] Argo Rollouts 설치 필요?
- [ ] cert-manager 설치 필요?
- [ ] AWS ALB Ingress Controller 설치 필요?

---

### 11. VPC Endpoint 확인

- [ ] **SSM VPC Endpoint**
- [ ] **EC2 Messages VPC Endpoint**
- [ ] **S3 VPC Endpoint**
- [ ] **ECR API VPC Endpoint**
- [ ] **ECR DKR VPC Endpoint**
- [ ] **CloudWatch Logs VPC Endpoint**
- [ ] **Secrets Manager VPC Endpoint**

---

### 12. Security Groups

- [ ] **ALB Security Group ID**
- [ ] **K8s Master Security Group ID**
- [ ] **K8s Worker Security Group ID**
- [ ] **RDS Security Group ID**

---

### 13. CloudWatch Logs

- [ ] **Log Group 이름**
  ```
  - /aws/ec2/k8s-master
  - /aws/ec2/k8s-worker-ops
  - /aws/ec2/k8s-worker-build
  - /aws/ec2/k8s-worker-run
  ```

---

### 14. DNS 설정

- [ ] **Route53 Hosted Zone ID** (있는 경우)
- [ ] **도메인 네임서버** 설정 완료 여부

---

## 📋 정보 제공 방법

### 옵션 1: 문서로 정리
```
위 체크리스트를 채워서 공유
```

### 옵션 2: AWS Console 스크린샷
```
- VPC 대시보드
- ECR 저장소 목록
- RDS 엔드포인트
- ALB 정보
```

### 옵션 3: AWS CLI 명령어 결과
```bash
# VPC 정보
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=runna-vpc"

# ECR 정보
aws ecr describe-repositories

# RDS 정보
aws rds describe-db-instances

# ALB 정보
aws elbv2 describe-load-balancers
```

---

## 🚀 정보 받은 후 우리가 할 일

1. **Helm Values 업데이트**
   - ECR URL
   - S3 Bucket 이름
   - AWS 리전
   - ACM Certificate ARN

2. **GitHub Actions Secrets 설정**
   - AWS_ROLE_ARN
   - AWS_REGION
   - ECR_REGISTRY

3. **K8s Secret 생성**
   - DATABASE_URL
   - SECRET_KEY
   - S3_FUNCTIONS_BUCKET

4. **ArgoCD Application 배포**
   - repoURL 업데이트
   - 실제 값으로 변경

5. **첫 배포 테스트**
   - Backend API 배포
   - Health Check 확인
   - RDS 연결 확인

---

**작성일:** 2024-12-04
**작성자:** 서영
**용도:** 인프라 프로비저닝 완료 후 필요한 정보 수집
