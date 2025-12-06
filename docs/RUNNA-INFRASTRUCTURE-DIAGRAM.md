# Runna AWS Infrastructure Architecture Diagram

## 전체 시스템 아키텍처

```mermaid
graph TB
    subgraph Internet["🌐 Internet"]
        USER[사용자]
    end
    
    subgraph DNS["☁️ Route53"]
        R53[api-runna.haifu.cloud]
    end
    
    subgraph VPC["🏢 VPC (10.0.0.0/16)"]
        subgraph PublicTier["📡 Public Tier (10.0.1-2.0/24)"]
            subgraph AZA_Public["AZ-A"]
                ALB_A[ALB<br/>Multi-AZ]
                NAT_A[NAT Gateway<br/>AZ-A]
            end
            subgraph AZB_Public["AZ-B"]
                ALB_B[ALB<br/>Multi-AZ]
                NAT_B[NAT Gateway<br/>AZ-B]
            end
        end
        
        subgraph PrivateApp["🖥️ Private-App Tier (10.0.11-12.0/24)"]
            subgraph AZA_App["AZ-A (10.0.11.0/24)"]
                WORKER_BACK[k8s-worker-back<br/>t3.small 2c/2g<br/>Backend API, Redis]
                WORKER_FUNC[k8s-worker-function<br/>m7i-flex.large 2c/8g<br/>Function Execution]
            end
            subgraph AZB_App["AZ-B (10.0.12.0/24)"]
                WORKER_OPS[k8s-worker-ops<br/>c7i-flex.large 2c/4g<br/>ArgoCD, Prometheus<br/>Grafana, Loki]
            end
        end
        
        subgraph PrivateControl["🎛️ Private-Control Tier (10.0.21-22.0/24)"]
            subgraph AZA_Control["AZ-A (10.0.21.0/24)"]
                MASTER[k8s-master<br/>m7i-flex.large 2c/8g<br/>Control Plane<br/>API Server, etcd]
            end
            subgraph AZB_Control["AZ-B (10.0.22.0/24)"]
                MASTER_STANDBY[예비 Master<br/>배치 가능]
            end
        end
        
        subgraph PrivateDB["🗄️ Private-DB Tier (10.0.31-32.0/24)"]
            subgraph AZA_DB["AZ-A (10.0.31.0/24)"]
                RDS_PRIMARY[RDS PostgreSQL<br/>Primary]
            end
            subgraph AZB_DB["AZ-B (10.0.32.0/24)"]
                RDS_STANDBY[RDS PostgreSQL<br/>Standby<br/>Multi-AZ]
            end
        end
        
        subgraph VPCEndpoints["🔒 VPC Endpoints"]
            EP_SSM[SSM]
            EP_EC2[EC2Messages]
            EP_S3[S3]
            EP_ECR[ECR.API/DKR]
            EP_LOGS[CloudWatch Logs]
            EP_SECRETS[Secrets Manager]
        end
    end
    
    subgraph AWS["☁️ AWS Services"]
        S3[S3<br/>Function Artifacts]
        ECR[ECR<br/>Container Images]
        CW[CloudWatch<br/>Logs & Metrics]
        SM[Secrets Manager<br/>DB Credentials]
    end
    
    USER -->|HTTPS| R53
    R53 -->|DNS Resolution| ALB_A
    R53 -->|DNS Resolution| ALB_B
    ALB_A -->|NodePort 30080| WORKER_BACK
    ALB_A -->|NodePort 30080| WORKER_FUNC
    ALB_B -->|NodePort 30080| WORKER_BACK
    ALB_B -->|NodePort 30080| WORKER_FUNC
    
    WORKER_BACK -->|NAT Gateway| NAT_A
    WORKER_FUNC -->|NAT Gateway| NAT_A
    WORKER_OPS -->|NAT Gateway| NAT_B
    
    WORKER_BACK -->|K8s API:6443| MASTER
    WORKER_FUNC -->|K8s API:6443| MASTER
    WORKER_OPS -->|K8s API:6443| MASTER
    
    WORKER_BACK -->|PostgreSQL:5432| RDS_PRIMARY
    WORKER_FUNC -->|PostgreSQL:5432| RDS_PRIMARY
    
    RDS_PRIMARY -.->|Replication| RDS_STANDBY
    
    WORKER_BACK -->|Private| EP_S3
    WORKER_FUNC -->|Private| EP_S3
    WORKER_OPS -->|Private| EP_ECR
    MASTER -->|Private| EP_SSM
    
    EP_S3 -.->|Private Link| S3
    EP_ECR -.->|Private Link| ECR
    EP_LOGS -.->|Private Link| CW
    EP_SECRETS -.->|Private Link| SM
    
    style PublicTier fill:#e1f5ff
    style PrivateApp fill:#fff4e1
    style PrivateControl fill:#ffe1f5
    style PrivateDB fill:#e1ffe1
    style VPCEndpoints fill:#f0f0f0
```

## CI/CD 파이프라인 통합 아키텍처

```mermaid
graph LR
    subgraph Developer["👨‍💻 개발자"]
        DEV[코드 작성]
    end
    
    subgraph GitHub["🐙 GitHub"]
        REPO[runna-cicd<br/>Repository]
        BACKEND[runna-backend<br/>Repository]
    end
    
    subgraph GitHubActions["⚙️ GitHub Actions"]
        CHECKOUT[Checkout Code]
        BUILD[Docker Build]
        PUSH[Push to Docker Hub]
        UPDATE[Update Helm Values]
        COMMIT[Git Commit & Push]
    end
    
    subgraph DockerHub["🐳 Docker Hub"]
        REGISTRY[Container Registry<br/>backend:tag]
    end
    
    subgraph K8sCluster["☸️ Kubernetes Cluster"]
        ARGOCD[ArgoCD<br/>GitOps Controller]
        BACKEND_POD[Backend Pods]
        FUNCTION_POD[Function Pods]
        REDIS_POD[Redis Pods]
    end
    
    subgraph Monitoring["📊 Monitoring"]
        PROM[Prometheus]
        GRAF[Grafana]
        LOKI[Loki]
    end
    
    DEV -->|git push| REPO
    REPO -->|trigger| CHECKOUT
    CHECKOUT -->|clone| BACKEND
    BACKEND -->|source| BUILD
    BUILD -->|image| PUSH
    PUSH -->|store| REGISTRY
    PUSH -->|success| UPDATE
    UPDATE -->|modify| COMMIT
    COMMIT -->|push| REPO
    
    REPO -->|detect change| ARGOCD
    ARGOCD -->|pull image| REGISTRY
    ARGOCD -->|deploy| BACKEND_POD
    ARGOCD -->|deploy| FUNCTION_POD
    ARGOCD -->|deploy| REDIS_POD
    
    BACKEND_POD -->|metrics| PROM
    FUNCTION_POD -->|metrics| PROM
    PROM -->|visualize| GRAF
    BACKEND_POD -->|logs| LOKI
    FUNCTION_POD -->|logs| LOKI
    
    style Developer fill:#e1f5ff
    style GitHub fill:#f0f0f0
    style GitHubActions fill:#fff4e1
    style DockerHub fill:#e1ffe1
    style K8sCluster fill:#ffe1f5
    style Monitoring fill:#f5e1ff
```

## 4-Tier 망분리 보안 아키텍처

```mermaid
graph TB
    subgraph Tier1["🌐 Tier 1: Public Subnet"]
        T1_DESC["인터넷 게이트웨이 연결<br/>ALB (외부 트래픽 수신)<br/>NAT Gateway (아웃바운드)"]
        T1_CIDR["10.0.1-2.0/24"]
    end
    
    subgraph Tier2["🖥️ Tier 2: Private-App Subnet"]
        T2_DESC["Kubernetes Worker 노드<br/>애플리케이션 실행<br/>NAT Gateway를 통한 외부 접근<br/>ALB에서만 인바운드 허용"]
        T2_CIDR["10.0.11-12.0/24"]
    end
    
    subgraph Tier3["🎛️ Tier 3: Private-Control Subnet"]
        T3_DESC["Kubernetes Master 노드<br/>클러스터 관리 전용<br/>Worker 노드에서만 접근<br/>외부 인터넷 접근 불가"]
        T3_CIDR["10.0.21-22.0/24"]
    end
    
    subgraph Tier4["🗄️ Tier 4: Private-DB Subnet"]
        T4_DESC["RDS PostgreSQL<br/>완전 격리<br/>App Subnet에서만 접근<br/>인터넷 접근 완전 차단"]
        T4_CIDR["10.0.31-32.0/24"]
    end
    
    Tier1 -->|NodePort 30080| Tier2
    Tier2 -->|K8s API 6443| Tier3
    Tier2 -->|PostgreSQL 5432| Tier4
    
    style Tier1 fill:#e1f5ff
    style Tier2 fill:#fff4e1
    style Tier3 fill:#ffe1f5
    style Tier4 fill:#e1ffe1
```

## Multi-AZ 고가용성 전략

```mermaid
graph TB
    subgraph AZA["🏢 Availability Zone A"]
        subgraph AZA_Public["Public Subnet"]
            ALB_A[ALB]
            NAT_A[NAT Gateway]
        end
        subgraph AZA_App["Private-App Subnet"]
            WORKER_BACK_A[k8s-worker-back<br/>Backend API, Redis]
            WORKER_FUNC_A[k8s-worker-function<br/>Function Execution]
        end
        subgraph AZA_Control["Private-Control Subnet"]
            MASTER_A[k8s-master<br/>Control Plane]
        end
        subgraph AZA_DB["Private-DB Subnet"]
            RDS_A[RDS Primary]
        end
    end
    
    subgraph AZB["🏢 Availability Zone B"]
        subgraph AZB_Public["Public Subnet"]
            ALB_B[ALB]
            NAT_B[NAT Gateway]
        end
        subgraph AZB_App["Private-App Subnet"]
            WORKER_OPS_B[k8s-worker-ops<br/>ArgoCD, Monitoring]
        end
        subgraph AZB_Control["Private-Control Subnet"]
            MASTER_B[예비 Master<br/>배치 가능]
        end
        subgraph AZB_DB["Private-DB Subnet"]
            RDS_B[RDS Standby]
        end
    end
    
    ALB_A -.->|Health Check| WORKER_BACK_A
    ALB_B -.->|Health Check| WORKER_BACK_A
    ALB_A -.->|Health Check| WORKER_FUNC_A
    ALB_B -.->|Health Check| WORKER_FUNC_A
    
    RDS_A -.->|Replication| RDS_B
    RDS_A -.->|Auto Failover| RDS_B
    
    WORKER_BACK_A -->|Outbound| NAT_A
    WORKER_FUNC_A -->|Outbound| NAT_A
    WORKER_OPS_B -->|Outbound| NAT_B
    
    style AZA fill:#e1f5ff
    style AZB fill:#fff4e1
```

## VPC Endpoint Private 통신

```mermaid
graph LR
    subgraph PrivateSubnet["🔒 Private Subnet"]
        EC2[EC2 Instance<br/>No Public IP]
    end
    
    subgraph VPCEndpoints["🔗 VPC Endpoints"]
        EP_SSM[SSM Endpoint]
        EP_S3[S3 Endpoint]
        EP_ECR[ECR Endpoint]
        EP_LOGS[Logs Endpoint]
        EP_SECRETS[Secrets Endpoint]
    end
    
    subgraph AWSServices["☁️ AWS Services"]
        SSM[Systems Manager<br/>Session Manager]
        S3[S3<br/>Function Artifacts]
        ECR[ECR<br/>Container Images]
        CW[CloudWatch Logs]
        SM[Secrets Manager]
    end
    
    EC2 -->|Private Link| EP_SSM
    EC2 -->|Private Link| EP_S3
    EC2 -->|Private Link| EP_ECR
    EC2 -->|Private Link| EP_LOGS
    EC2 -->|Private Link| EP_SECRETS
    
    EP_SSM -.->|Private| SSM
    EP_S3 -.->|Private| S3
    EP_ECR -.->|Private| ECR
    EP_LOGS -.->|Private| CW
    EP_SECRETS -.->|Private| SM
    
    style PrivateSubnet fill:#ffe1f5
    style VPCEndpoints fill:#f0f0f0
    style AWSServices fill:#e1ffe1
```

## 보안 계층 구조

```mermaid
graph TB
    subgraph Layer1["🌐 Layer 1: Network Security"]
        L1_1[4-Tier 망분리]
        L1_2[Security Groups]
        L1_3[Network ACLs]
        L1_4[Private Subnets Only]
    end
    
    subgraph Layer2["🔐 Layer 2: Access Control"]
        L2_1[IAM Roles & Policies]
        L2_2[Session Manager<br/>No SSH Keys]
        L2_3[MFA 강제]
        L2_4[최소 권한 원칙]
    end
    
    subgraph Layer3["🔒 Layer 3: Data Protection"]
        L3_1[RDS 암호화 AES-256]
        L3_2[EBS 볼륨 암호화]
        L3_3[Secrets Manager]
        L3_4[TLS 1.2+ 강제]
    end
    
    subgraph Layer4["📊 Layer 4: Monitoring & Audit"]
        L4_1[CloudTrail<br/>모든 API 기록]
        L4_2[CloudWatch Logs]
        L4_3[VPC Flow Logs]
        L4_4[GuardDuty 위협 탐지]
    end
    
    Layer1 --> Layer2
    Layer2 --> Layer3
    Layer3 --> Layer4
    
    style Layer1 fill:#e1f5ff
    style Layer2 fill:#fff4e1
    style Layer3 fill:#ffe1f5
    style Layer4 fill:#e1ffe1
```

## 비용 구조 분석

```mermaid
pie title 월간 인프라 비용 분석 ($371)
    "EC2 (4대)" : 155
    "NAT Gateway (2개)" : 70
    "VPC Endpoints (8개)" : 56
    "RDS Single-AZ" : 50
    "ALB" : 20
    "데이터 전송" : 20
```

## 워크로드 배치 전략

```mermaid
graph TB
    subgraph Master["🎛️ Master Node (m7i-flex.large, 8GB)"]
        M1[Control Plane]
        M2[API Server]
        M3[Scheduler]
        M4[etcd]
    end
    
    subgraph WorkerBack["🖥️ Worker-Back (t3.small, 2GB)"]
        WB1[Backend API Pods]
        WB2[Redis Pods]
    end
    
    subgraph WorkerFunc["⚡ Worker-Function (m7i-flex.large, 8GB)"]
        WF1[Function Execution Pods]
        WF2[높은 메모리 요구사항]
    end
    
    subgraph WorkerOps["📊 Worker-Ops (c7i-flex.large, 4GB)"]
        WO1[ArgoCD]
        WO2[Prometheus]
        WO3[Grafana]
        WO4[Loki]
    end
    
    Master -->|Schedule| WorkerBack
    Master -->|Schedule| WorkerFunc
    Master -->|Schedule| WorkerOps
    
    style Master fill:#ffe1f5
    style WorkerBack fill:#e1f5ff
    style WorkerFunc fill:#fff4e1
    style WorkerOps fill:#e1ffe1
```

## 배포 흐름도

```mermaid
sequenceDiagram
    participant Dev as 개발자
    participant GH as GitHub
    participant GHA as GitHub Actions
    participant DH as Docker Hub
    participant Argo as ArgoCD
    participant K8s as Kubernetes
    participant ALB as ALB
    participant User as 사용자
    
    Dev->>GH: git push (코드 변경)
    GH->>GHA: Trigger Workflow
    GHA->>GHA: Checkout Code
    GHA->>GHA: Docker Build
    GHA->>DH: Push Image (tag: git-sha)
    GHA->>GH: Update Helm Values
    GHA->>GH: Git Commit & Push
    
    GH->>Argo: Detect Change (GitOps)
    Argo->>DH: Pull Image
    Argo->>K8s: Deploy Pods
    K8s->>K8s: Rolling Update
    K8s->>ALB: Register Target
    ALB->>ALB: Health Check
    
    User->>ALB: HTTPS Request
    ALB->>K8s: Forward to Pod
    K8s->>ALB: Response
    ALB->>User: HTTPS Response
```

## 장애 복구 시나리오

```mermaid
graph TB
    subgraph Scenario1["🔴 시나리오 1: AZ-A 장애"]
        S1_1[AZ-A 전체 장애 발생]
        S1_2[RDS Auto Failover<br/>AZ-B로 전환 1-2분]
        S1_3[ALB 자동 라우팅<br/>AZ-B로 트래픽 전환]
        S1_4[Worker 노드 재배치<br/>Kubernetes 자동 처리]
        S1_5[서비스 정상화<br/>다운타임 최소화]
    end
    
    subgraph Scenario2["🟡 시나리오 2: 인스턴스 장애"]
        S2_1[Worker 노드 장애 감지]
        S2_2[새 인스턴스 생성]
        S2_3[K3s Join]
        S2_4[Pod 자동 재배치]
        S2_5[서비스 정상화]
    end
    
    subgraph Scenario3["🟢 시나리오 3: 데이터베이스 장애"]
        S3_1[RDS Primary 장애]
        S3_2[Multi-AZ Standby로<br/>자동 전환]
        S3_3[애플리케이션<br/>자동 재연결]
        S3_4[서비스 정상화<br/>데이터 손실 없음]
    end
    
    S1_1 --> S1_2 --> S1_3 --> S1_4 --> S1_5
    S2_1 --> S2_2 --> S2_3 --> S2_4 --> S2_5
    S3_1 --> S3_2 --> S3_3 --> S3_4
    
    style Scenario1 fill:#ffe1e1
    style Scenario2 fill:#fff4e1
    style Scenario3 fill:#e1ffe1
```

---

## 다이어그램 설명

### 1. 전체 시스템 아키텍처
- VPC 내 4-Tier 망분리 구조
- Multi-AZ 고가용성 배치
- VPC Endpoint를 통한 Private 통신

### 2. CI/CD 파이프라인 통합
- GitHub Actions → Docker Hub → ArgoCD → Kubernetes
- GitOps 기반 자동 배포
- 통합 모니터링 (Prometheus, Grafana, Loki)

### 3. 4-Tier 망분리 보안
- Public → Private-App → Private-Control → Private-DB
- 계층별 접근 제어 및 격리

### 4. Multi-AZ 고가용성
- NAT Gateway, ALB, Worker 노드 이중화
- RDS Multi-AZ 자동 Failover

### 5. VPC Endpoint Private 통신
- 인터넷 경유 없이 AWS 서비스 접근
- 보안 강화 및 비용 절감

### 6. 보안 계층 구조
- Network → Access Control → Data Protection → Monitoring
- 다층 방어 전략

### 7. 비용 구조 분석
- 월 $371 총 비용 분석
- 항목별 비용 비율

### 8. 워크로드 배치 전략
- Master, Worker-Back, Worker-Function, Worker-Ops
- 워크로드별 최적화된 인스턴스 타입

### 9. 배포 흐름도
- 개발자 → GitHub → CI/CD → Kubernetes → 사용자
- 전체 배포 프로세스 시퀀스

### 10. 장애 복구 시나리오
- AZ 장애, 인스턴스 장애, 데이터베이스 장애
- 각 시나리오별 자동 복구 프로세스
