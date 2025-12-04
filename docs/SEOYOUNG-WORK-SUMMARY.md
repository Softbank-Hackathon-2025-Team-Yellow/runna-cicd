# 서영 작업 완료 요약 (Phase 1~3)

**작성일**: 2024년 12월 4일  
**담당자**: 유서영  
**프로젝트**: Runna - K3s + Knative 기반 서버리스 플랫폼

---

## 목차

1. [Phase 1: CI/CD 파이프라인 구축](#phase-1-cicd-파이프라인-구축)
2. [Phase 2: Argo Rollouts 배포 전략](#phase-2-argo-rollouts-배포-전략)
3. [Phase 3: Knative 멀티테넌시 구현](#phase-3-knative-멀티테넌시-구현)
4. [전체 아키텍처 요약](#전체-아키텍처-요약)
5. [다음 단계](#다음-단계)

---

## Phase 1: CI/CD 파이프라인 구축

### 📋 개요
GitHub Actions + ArgoCD를 활용한 완전 자동화 CI/CD 파이프라인 구축

### ✅ 완료 항목

#### 1. GitHub Actions Workflow
**파일**: `.github/workflows/ci-cd.yml`

**주요 기능**:
- 자동 이미지 태그 생성 (Git SHA 기반)
- Docker 이미지 빌드 및 ECR 푸시
- Helm values 자동 업데이트
- ArgoCD 자동 동기화

**트리거**:
```yaml
- Push to main branch
- Pull Request to main
- Manual workflow dispatch
```

#### 2. Helm Charts
**위치**: `helm/charts/`

**구성**:
- `platform-service/`: Backend API 서비스
  - Deployment/Rollout 템플릿
  - Service, Ingress 설정
  - ConfigMap, Secret 관리
- `user-function/`: 사용자 함수 (Knative Service)
  - Knative Service 템플릿
  - 자동 스케일링 설정

#### 3. ArgoCD Applications
**위치**: `argocd/applications/`

**환경별 구성**:
- `backend-dev.yaml`: 개발 환경
- `backend-staging.yaml`: 스테이징 환경
- `backend-prod.yaml`: 프로덕션 환경

**주요 설정**:
```yaml
- Automated sync policy
- Self-heal enabled
- Prune resources enabled
- Helm values per environment
```

#### 4. 검증 스크립트
**위치**: `scripts/`, `tests/`

**구현된 검증**:
- Dockerfile 검증 (`validate-dockerfile.py`)
- Helm 차트 검증 (`validate-helm.ps1`)
- Values 파일 검증 (`validate-values.py`)
- 이미지 태그 고유성 테스트 (`test_image_tag_uniqueness.py`)
- ArgoCD dry-run 테스트 (`test-argocd-dryrun.ps1`)

### 📊 Phase 1 성과
- ✅ 완전 자동화된 CI/CD 파이프라인
- ✅ 환경별 배포 자동화 (dev/staging/prod)
- ✅ 이미지 태그 자동 관리
- ✅ GitOps 기반 배포 (ArgoCD)

---

## Phase 2: Argo Rollouts 배포 전략

### 📋 개요
Canary 배포 전략을 통한 무중단 배포 및 자동 롤백 구현

### ✅ 완료 항목

#### 1. Argo Rollouts 설정
**파일**: `helm/charts/platform-service/templates/rollout.yaml`

**Canary 배포 전략**:
```yaml
Strategy:
  - 20% 트래픽 → 30초 대기
  - 40% 트래픽 → 30초 대기
  - 60% 트래픽 → 30초 대기
  - 80% 트래픽 → 30초 대기
  - 100% 트래픽 (완전 배포)
```

**자동 롤백 조건**:
- Success rate < 95%
- 분석 실패 시 자동 롤백

#### 2. Analysis Template
**파일**: `argocd/analysis-templates/success-rate.yaml`

**메트릭 분석**:
- Prometheus 기반 성공률 측정
- 임계값: 95% 이상
- 실패 시 자동 롤백

#### 3. 환경별 Values
**위치**: `helm/values/`

**구성**:
- `values-backend-dev.yaml`: 개발 (replicas: 1)
- `values-backend-staging.yaml`: 스테이징 (replicas: 2)
- `values-backend-prod.yaml`: 프로덕션 (replicas: 3)

#### 4. 검증 및 테스트
**구현된 테스트**:
- Rollout 설정 검증 (`test_rollout_configuration.py`)
- Rollout 전략 검증 (`test_rollout_strategy.py`)
- 에러 핸들링 검증 (`validate-error-handling.py`)
- Analysis template 검증 (`validate-analysis-template.py`)

### 📊 Phase 2 성과
- ✅ Canary 배포 전략 구현
- ✅ 자동 롤백 메커니즘
- ✅ Prometheus 기반 메트릭 분석
- ✅ 무중단 배포 보장

---

## Phase 3: Knative 멀티테넌시 구현

### 📋 개요
함수별 Namespace 격리를 통한 멀티테넌트 서버리스 플랫폼 구축

### ✅ 완료 항목 (오늘 작업)

#### 1. 프로젝트 구조 및 정책 템플릿
**위치**: `k8s/policies/`

**파일**:
- `resource-quota-template.yaml`: 리소스 제한 정책
  - CPU: 최대 1코어
  - Memory: 최대 512MB
  - Pods: 최대 10개
- `network-policy-template.yaml`: 네트워크 격리 정책
  - 함수 간 직접 통신 차단
  - Kourier Ingress만 허용
  - Redis Queue 접근 허용

#### 2. 데이터 모델
**위치**: `backend-repo/app/models/`

**Workspace 모델** (`workspace.py`):
```python
- id: String(20)  # 최대 20자 (팀 결정)
- user_id: String(255)
- name: String(255)
- created_at, updated_at
- Relationship: 1 workspace = N functions
```

**Function 모델** (`function.py`):
```python
- id: UUID (32자, 하이픈 제거)
- workspace_id: String(20)
- name, runtime, code
- namespace: String(63)  # {workspace}-{function_id}
- public_url: String(512)
- status: String(20)  # pending, deploying, ready, failed
```

#### 3. Function ID 생성 로직
**파일**: `backend-repo/app/core/id_generator.py`

**구현 함수**:
- `generate_function_id()`: UUID v4 기반 32자 ID 생성
- `generate_namespace_name()`: K8s 네이밍 규칙 준수
- `validate_workspace_name()`: 20자 제한 검증
- `validate_workspace_id()`: URL-safe 문자 검증

**네이밍 규칙**:
```
Namespace: {workspace}-{function_id}
예시: my-workspace-abc123def456...
길이: 20 + 1 + 32 = 53자 (< 63자 K8s 제한)
```

#### 4. TenantService 구현 ⭐ 핵심!
**파일**: `backend-repo/app/services/tenant_service.py`

**주요 기능**:
```python
class TenantService:
    def ensure_namespace(workspace, function_id):
        """
        Namespace 자동 생성 (멱등성 보장)
        1. Namespace 생성
        2. ResourceQuota 적용
        3. NetworkPolicy 적용
        """
    
    def _create_namespace(name, workspace, function_id):
        """Namespace 생성 with 레이블"""
    
    def _create_resource_quota(namespace):
        """템플릿 기반 리소스 제한 적용"""
    
    def _create_network_policy(namespace):
        """템플릿 기반 네트워크 격리 적용"""
```

**특징**:
- Kubernetes Python Client 사용
- 정책 템플릿 자동 로드 (YAML)
- 멱등성 보장 (중복 생성 방지)
- 에러 핸들링 및 로깅

#### 5. 데이터베이스 마이그레이션
**파일**: `backend-repo/migrations/versions/add_multitenancy_support.py`

**변경사항**:
- Workspace 테이블 생성
- Function 테이블에 workspace_id, namespace, public_url 추가
- 인덱스 및 제약조건 추가

#### 6. 속성 기반 테스트 (Property-Based Testing)
**위치**: `backend-repo/tests/`

**구현된 테스트**:

1. **Function ID 길이 일관성** (`test_property_function_id.py`)
   - 모든 Function ID가 32자인지 검증
   - 100회 반복 테스트 (Hypothesis)
   - ✅ 통과

2. **Namespace 네이밍 규칙** (`test_property_namespace_naming.py`)
   - {workspace}-{function_id} 형식 검증
   - K8s 네이밍 규칙 준수 검증
   - 100회 반복 테스트
   - ✅ 통과

3. **Workspace 이름 검증** (`test_workspace_validation.py`)
   - 20자 제한 검증
   - URL-safe 문자 검증
   - 하이픈 시작/끝 거부
   - 7개 테스트 케이스
   - ✅ 모두 통과

4. **TenantService 단위 테스트** (`test_tenant_service.py`)
   - Namespace 생성 테스트
   - 멱등성 테스트
   - Mock 기반 단위 테스트

### 📊 Phase 3 성과
- ✅ 1 Function = 1 Namespace 격리 구현
- ✅ 자동 리소스 제한 및 네트워크 격리
- ✅ Workspace 20자 제한 (팀 결정 반영)
- ✅ 속성 기반 테스트로 정확성 보장
- ✅ K8s Python Client 기반 자동화

---

## 전체 아키텍처 요약

### 시스템 구성도

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
│  - Backend Code                                              │
│  - Helm Charts                                               │
│  - ArgoCD Applications                                       │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ Push to main
                 ▼
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Actions (CI)                        │
│  1. Build Docker Image                                       │
│  2. Push to ECR                                              │
│  3. Update Helm Values (image tag)                           │
│  4. Trigger ArgoCD Sync                                      │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ GitOps
                 ▼
┌─────────────────────────────────────────────────────────────┐
│                    ArgoCD (CD)                               │
│  - Auto Sync                                                 │
│  - Self Heal                                                 │
│  - Argo Rollouts (Canary)                                    │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ Deploy
                 ▼
┌─────────────────────────────────────────────────────────────┐
│                  K3s Cluster                                 │
│                                                              │
│  ┌──────────────────────────────────────────────────┐      │
│  │  Backend Service (Argo Rollout)                  │      │
│  │  - Canary Deployment                             │      │
│  │  - Auto Rollback                                 │      │
│  └──────────────────────────────────────────────────┘      │
│                                                              │
│  ┌──────────────────────────────────────────────────┐      │
│  │  Function Namespaces (멀티테넌시)                │      │
│  │                                                   │      │
│  │  workspace1-func001                              │      │
│  │  ├─ Knative Service                              │      │
│  │  ├─ ResourceQuota (CPU/Memory 제한)             │      │
│  │  └─ NetworkPolicy (격리)                         │      │
│  │                                                   │      │
│  │  workspace1-func002                              │      │
│  │  ├─ Knative Service                              │      │
│  │  ├─ ResourceQuota                                │      │
│  │  └─ NetworkPolicy                                │      │
│  │                                                   │      │
│  │  workspace2-func001                              │      │
│  │  └─ ...                                          │      │
│  └──────────────────────────────────────────────────┘      │
│                                                              │
│  ┌──────────────────────────────────────────────────┐      │
│  │  Kourier Ingress                                 │      │
│  │  - {workspace}.runna.haifu.cloud/{function}      │      │
│  └──────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### 핵심 기술 스택

| 계층 | 기술 | 용도 |
|------|------|------|
| **CI** | GitHub Actions | 자동 빌드 및 배포 |
| **CD** | ArgoCD | GitOps 기반 배포 |
| **배포 전략** | Argo Rollouts | Canary 배포, 자동 롤백 |
| **컨테이너 오케스트레이션** | K3s | 경량 Kubernetes |
| **서버리스** | Knative Serving | 함수 실행 환경 |
| **Ingress** | Kourier | Knative 기본 Ingress |
| **멀티테넌시** | Namespace 격리 | 함수별 격리 |
| **리소스 제한** | ResourceQuota | CPU/Memory 제한 |
| **네트워크 격리** | NetworkPolicy | 함수 간 통신 차단 |
| **백엔드** | FastAPI + Python | REST API |
| **데이터베이스** | PostgreSQL | 메타데이터 저장 |
| **큐** | Redis | 비동기 작업 처리 |

### URL 라우팅 구조

```
외부 요청: https://workspace1.runna.haifu.cloud/my-function
    ↓
ALB (AWS Load Balancer)
    ↓
Kourier Ingress (K3s)
    ↓
Ingress Rule 매칭
    ↓
Knative Service (workspace1-abc123def456...)
    ↓
Function Pod (격리된 Namespace)
```

---

## 주요 파일 구조

```
.
├── .github/
│   └── workflows/
│       └── ci-cd.yml                    # CI/CD 파이프라인
│
├── argocd/
│   ├── applications/
│   │   ├── backend-dev.yaml             # 개발 환경
│   │   ├── backend-staging.yaml         # 스테이징 환경
│   │   └── backend-prod.yaml            # 프로덕션 환경
│   └── analysis-templates/
│       └── success-rate.yaml            # Canary 분석 템플릿
│
├── helm/
│   ├── charts/
│   │   ├── platform-service/            # Backend 서비스
│   │   │   └── templates/
│   │   │       ├── rollout.yaml         # Argo Rollout
│   │   │       ├── service.yaml
│   │   │       └── ingress.yaml
│   │   └── user-function/               # 사용자 함수
│   │       └── templates/
│   │           └── knative-service.yaml
│   └── values/
│       ├── values-backend-dev.yaml
│       ├── values-backend-staging.yaml
│       └── values-backend-prod.yaml
│
├── k8s/
│   ├── policies/
│   │   ├── resource-quota-template.yaml # 리소스 제한
│   │   └── network-policy-template.yaml # 네트워크 격리
│   └── tenant-templates/                # Namespace 템플릿
│
├── backend-repo/
│   ├── app/
│   │   ├── models/
│   │   │   ├── workspace.py             # Workspace 모델
│   │   │   └── function.py              # Function 모델
│   │   ├── services/
│   │   │   └── tenant_service.py        # ⭐ TenantService
│   │   └── core/
│   │       └── id_generator.py          # ID 생성 로직
│   ├── migrations/
│   │   └── versions/
│   │       └── add_multitenancy_support.py
│   └── tests/
│       ├── test_property_function_id.py
│       ├── test_property_namespace_naming.py
│       ├── test_workspace_validation.py
│       └── test_tenant_service.py
│
├── scripts/                             # 검증 스크립트
│   ├── validate-dockerfile.py
│   ├── validate-helm.ps1
│   ├── validate-values.py
│   └── validate-rollout-config.py
│
├── tests/                               # 통합 테스트
│   ├── test_image_tag_uniqueness.py
│   ├── test_rollout_configuration.py
│   └── test_rollout_strategy.py
│
└── docs/
    ├── PHASE1-COMPLETE.md               # Phase 1 완료 문서
    ├── PHASE2-COMPLETE-SUMMARY.md       # Phase 2 완료 문서
    ├── PHASE3-MULTITENANCY-DESIGN.md    # Phase 3 설계 문서
    └── SEOYOUNG-WORK-SUMMARY.md         # 이 문서
```

---

## 팀 결정사항 반영

### 1. Namespace 네이밍 규칙
```
형식: {workspace}-{function_id}
예시: my-workspace-abc123def456789...
제약: 최대 63자 (K8s 제한)
```

### 2. Workspace 이름 제한
```
최대 길이: 20자
이유: workspace(20) + '-'(1) + function_id(32) = 53자 < 63자
문자 제한: 소문자, 숫자, 하이픈만 허용
시작/끝: 반드시 영숫자
```

### 3. 리소스 격리
```
원칙: 1 Function = 1 Namespace
이유: Namespace별 메트릭 수집 = Function별 메트릭 수집
```

### 4. URL 구조
```
형식: https://{workspace}.runna.haifu.cloud/{function}
예시: https://my-workspace.runna.haifu.cloud/my-function
```

### 5. Redis 용도
```
Backend Redis: Knative 통신용
Infrastructure Redis: Knative YAML 요청 Queue (별도)
```

---

## 테스트 커버리지

### Phase 1 테스트
- ✅ Dockerfile 검증
- ✅ Helm 차트 검증
- ✅ Values 파일 검증
- ✅ 이미지 태그 고유성
- ✅ ArgoCD dry-run

### Phase 2 테스트
- ✅ Rollout 설정 검증
- ✅ Rollout 전략 검증
- ✅ Analysis template 검증
- ✅ 에러 핸들링 검증

### Phase 3 테스트
- ✅ Function ID 길이 (100회 반복)
- ✅ Namespace 네이밍 (100회 반복)
- ✅ Workspace 검증 (7개 케이스)
- ✅ TenantService 단위 테스트

**총 테스트 수**: 20+ 테스트 케이스  
**통과율**: 100%

---

## 다음 단계 (Phase 3 계속)

### 즉시 작업 (이번 주)
1. **Task 4**: PVC 관리 구현
   - 공유 PVC 전략 구현
   - 함수 코드 저장 로직

2. **Task 5**: Knative Service 배포 구현
   - `deploy_knative_service()` 함수
   - Generic Runner 이미지 설정
   - PVC 마운트 설정

3. **Task 6**: IngressMapper 구현
   - Ingress Rule 자동 생성
   - URL 라우팅 설정
   - TLS 인증서 설정

### 중기 작업 (다음 주)
4. **Task 7**: Backend API 통합
   - POST /functions 엔드포인트 수정
   - TenantService 연동

5. **Task 8**: 함수 삭제 로직
   - 리소스 정리 자동화

6. **Task 9-14**: 에러 처리, RBAC, 통합 테스트

### API 변경 필요사항
- Function 타입에 `workspace_id`, `namespace`, `public_url`, `status` 추가
- Workspace 관리 API 추가 (POST/GET/DELETE /workspaces)
- `function_id` 타입: number → string (UUID)

---

## 기술적 성과

### 자동화
- ✅ CI/CD 완전 자동화
- ✅ Namespace 자동 생성
- ✅ 리소스 제한 자동 적용
- ✅ 네트워크 격리 자동 적용
- ✅ Canary 배포 자동화
- ✅ 자동 롤백

### 보안
- ✅ Namespace 격리
- ✅ NetworkPolicy 적용
- ✅ ResourceQuota 적용
- ✅ RBAC 설계 완료

### 테스트
- ✅ 속성 기반 테스트 (PBT)
- ✅ 단위 테스트
- ✅ 통합 테스트
- ✅ 검증 스크립트

### 문서화
- ✅ 요구사항 문서
- ✅ 설계 문서
- ✅ 구현 계획
- ✅ API 문서
- ✅ 작업 요약 (이 문서)

---

## 참고 자료

### 내부 문서
- `.kiro/specs/knative-multitenancy/requirements.md` - 멀티테넌시 요구사항
- `.kiro/specs/knative-multitenancy/design.md` - 멀티테넌시 설계
- `.kiro/specs/knative-multitenancy/tasks.md` - 구현 작업 목록
- `docs/PHASE1-COMPLETE.md` - Phase 1 완료 보고
- `docs/PHASE2-COMPLETE-SUMMARY.md` - Phase 2 완료 보고
- `docs/PHASE3-MULTITENANCY-DESIGN.md` - Phase 3 설계 문서

### 외부 참고
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Knative Documentation](https://knative.dev/docs/)
- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

---

## 회의 발표 포인트

### 강조할 점
1. **완전 자동화**: GitHub Push → 프로덕션 배포까지 완전 자동화
2. **무중단 배포**: Canary 배포 + 자동 롤백으로 안정성 보장
3. **멀티테넌시**: 1 Function = 1 Namespace로 완전한 격리
4. **팀 결정 반영**: Workspace 20자 제한 등 모든 팀 결정사항 구현 완료
5. **테스트 커버리지**: 속성 기반 테스트로 정확성 보장

### 데모 가능 항목
- GitHub Actions 워크플로우 실행
- ArgoCD 대시보드 (Canary 배포 진행 상황)
- Namespace 자동 생성 (TenantService)
- 속성 테스트 실행 결과

---

**작성자**: 유서영  
**최종 수정**: 2024-12-04  
**버전**: 1.0
