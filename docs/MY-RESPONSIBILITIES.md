# 내 담당 업무 정리

## 🎯 전체 역할

### A. CI/CD & GitOps (Phase 1-2 완료 ✅)
- GitHub Actions 기반 자동 빌드 & 배포
- ArgoCD GitOps 구조
- Argo Rollouts (Canary/Blue-Green)
- Helm Charts 템플릿
- 환경별 배포 전략

### B. 멀티테넌시 핵심 기능 (Phase 3 진행 중 🔨)
동규님이 직접 지시한 두 가지 핵심 기능:

#### 1️⃣ Namespace 자동 생성
**목표:** 사용자별 격리된 실행 환경 자동 생성

**구현:**
- Python FastAPI + Kubernetes Python Client
- 사용자 첫 함수 생성 시 자동 실행
- Namespace + ResourceQuota + NetworkPolicy + RBAC 자동 설정

**파일:**
- `backend-repo/app/services/tenant_service.py`

#### 2️⃣ Multi-tenancy Ingress Mapping ⭐
**목표:** 사용자 URL → Knative Service 자동 라우팅

**예시:**
```
사용자 URL: https://user001.runna.dev/my-function
  ↓ 자동 매핑
Knative: my-function.tenant-user001.svc.cluster.local
```

**구현:**
- Subdomain 기반 라우팅 (`{user_id}.runna.dev`)
- Ingress Rule 자동 생성
- TLS 인증서 자동 발급 (cert-manager)
- Knative Service와 연동

**파일:**
- `backend-repo/app/services/ingress_mapper.py`

**난이도:** 높음 (동규님도 "자기도 안 해봐서 어렵다"고 언급)

---

## 📊 현재 진행 상황

### ✅ 완료 (Phase 1-2)
1. **CI/CD 파이프라인**
   - GitHub Actions 워크플로우
   - Docker 빌드 자동화
   - ECR 푸시
   - Helm values 자동 업데이트

2. **GitOps 구조**
   - ArgoCD Applications (dev/staging/prod)
   - App-of-Apps 패턴
   - 자동 동기화

3. **Helm Charts**
   - platform-service 공통 템플릿
   - 환경별 values 파일
   - ENV 변수 주입 구조

4. **배포 전략**
   - Dev: 일반 Deployment
   - Staging: Canary (20%→50%→80%→100%)
   - Prod: Blue-Green (수동 승인)

5. **멀티테넌시 준비**
   - Namespace 템플릿 4개
   - ResourceQuota 설정
   - NetworkPolicy 설정
   - RBAC 설정
   - 설계 문서 작성

### 🔨 진행 중 (Phase 3)
1. **TenantService 구현**
   - Namespace 자동 생성 로직
   - K8s API 연동
   - Backend API 통합

2. **IngressMapper 구현** ⭐ 핵심!
   - Subdomain 라우팅
   - Ingress Rule 자동 생성
   - Knative Service 매핑
   - TLS 설정

3. **통합 테스트**
   - End-to-end 시나리오
   - 성능 테스트

---

## 📁 생성한 파일 목록

### CI/CD & GitOps
```
.github/workflows/ci-cd.yml
helm/charts/platform-service/
helm/values/values-backend-*.yaml
argocd/applications/backend-*.yaml
argocd/root-app.yaml
```

### 멀티테넌시
```
k8s/tenant-templates/
├── namespace.yaml
├── resource-quota.yaml
├── network-policy.yaml
└── rbac.yaml

docs/
├── PHASE3-MULTITENANCY-DESIGN.md
├── PHASE3-IMPLEMENTATION-PLAN.md
└── MY-RESPONSIBILITIES.md (이 파일)
```

### 검증 & 테스트
```
scripts/
├── validate-all-phase2.ps1
├── validate-tenant-templates.ps1
└── local-validation/

tests/
├── test_rollout_configuration.py
├── test_image_tag_uniqueness.py
└── test_helm_values_update.py
```

### 문서
```
docs/
├── PHASE1-COMPLETE.md
├── PHASE2-READY.md
├── PHASE2-COMPLETE-SUMMARY.md
├── PHASE3-MULTITENANCY-DESIGN.md
├── PHASE3-IMPLEMENTATION-PLAN.md
└── README 업데이트
```

---

## 🎯 다음 단계

### 즉시 (인프라 준비 후)
1. **Backend에 TenantService 추가**
   - `tenant_service.py` 작성
   - K8s Python Client 설정
   - API 통합

2. **Backend에 IngressMapper 추가**
   - `ingress_mapper.py` 작성
   - Subdomain 라우팅 구현
   - API 통합

3. **테스트**
   - 로컬 테스트
   - Staging 검증
   - Production 배포

### 추후 (선택사항)
1. **모니터링**
   - 테넌트별 리소스 사용량 추적
   - Ingress 트래픽 모니터링

2. **최적화**
   - Ingress Rule 캐싱
   - Namespace 재사용 전략

---

## 💡 핵심 포인트

### 왜 이 기능이 중요한가?

**1. Namespace 자동 생성**
- 사용자별 격리 → 보안
- 리소스 제한 → 공정한 사용
- 자동화 → 운영 부담 감소

**2. Ingress Mapping**
- 사용자 친화적 URL → UX 향상
- 자동 라우팅 → 개발자 편의성
- 멀티테넌시 핵심 → 플랫폼 확장성

### 기술적 도전

**Ingress Mapping의 어려움:**
1. Knative의 내부 URL 규칙 이해
2. Subdomain 기반 동적 라우팅
3. TLS 인증서 자동 발급
4. Namespace 간 네트워크 격리 유지
5. 성능 최적화 (많은 Ingress Rule 관리)

**해결 방법:**
- Kubernetes Ingress API 활용
- cert-manager로 TLS 자동화
- NetworkPolicy로 격리 유지
- Label selector로 효율적 관리

---

## 📚 참고 자료

### 내가 작성한 문서
- [Phase 3 멀티테넌시 설계](PHASE3-MULTITENANCY-DESIGN.md)
- [Phase 3 구현 계획](PHASE3-IMPLEMENTATION-PLAN.md)
- [Phase 1 완료 보고](PHASE1-COMPLETE.md)
- [Phase 2 준비 완료](PHASE2-READY.md)

### 외부 문서
- [Kubernetes Multi-tenancy](https://kubernetes.io/docs/concepts/security/multi-tenancy/)
- [Knative Serving](https://knative.dev/docs/serving/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [cert-manager](https://cert-manager.io/docs/)

---

## 🤝 협업 포인트

### 동규님과 협의 필요
- [ ] Knative Service 이름 규칙 확인
- [ ] Base domain 결정 (`runna.dev`?)
- [ ] TLS 인증서 발급 방식 (Let's Encrypt?)
- [ ] Namespace 리소스 제한 조정

### 소현님과 협의 필요
- [ ] K8s 클러스터 접근 권한
- [ ] DNS 설정 (Wildcard: `*.runna.dev`)
- [ ] Ingress Controller 설정
- [ ] cert-manager 설치

### 백엔드팀과 협의 필요
- [ ] API 엔드포인트 수정
- [ ] DB 스키마 업데이트 (namespace, public_url 필드)
- [ ] 에러 처리 방식

---

**작성일:** 2024-12-04
**작성자:** 서영
**상태:** Phase 1-2 완료, Phase 3 설계 완료, 구현 대기 중
