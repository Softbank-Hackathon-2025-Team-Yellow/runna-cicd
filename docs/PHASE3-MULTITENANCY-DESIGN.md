# Phase 3: 멀티테넌시 설계

## 📋 개요

사용자별로 격리된 함수 실행 환경을 제공하는 멀티테넌트 서버리스 플랫폼 설계

## 🎯 목표

1. **테넌트 격리**: 사용자별 독립적인 실행 환경
2. **자동 프로비저닝**: 테넌트 생성 시 자동으로 리소스 할당
3. **보안**: 테넌트 간 데이터 및 리소스 격리
4. **확장성**: 수천 명의 사용자 지원

## 🏗️ 아키텍처

### 1. Namespace 기반 격리

```
kubernetes-cluster/
├── platform-system/          # 플랫폼 공통 서비스
│   ├── backend-api
│   ├── argocd
│   └── monitoring
│
├── tenant-user001/           # 사용자 1의 네임스페이스
│   ├── user-function-1
│   ├── user-function-2
│   └── resource-quota
│
├── tenant-user002/           # 사용자 2의 네임스페이스
│   ├── user-function-1
│   └── resource-quota
│
└── tenant-user003/           # 사용자 3의 네임스페이스
    └── user-function-1
```

### 2. 테넌트 생성 플로우

```
사용자 회원가입
  ↓
Backend API: 사용자 생성
  ↓
Namespace 자동 생성
  ↓
ResourceQuota 설정
  ↓
NetworkPolicy 적용
  ↓
ServiceAccount 생성
  ↓
테넌트 준비 완료
```

## 🔧 구현 방안

### 1. Namespace 자동 생성

#### 방법 A: Backend에서 직접 생성 (추천)

**장점:**
- 즉시 생성 가능
- 사용자 경험 좋음
- 간단한 구조

**단점:**
- Backend에 K8s 권한 필요
- RBAC 설정 필요

**구현:**
```python
# backend/app/services/tenant_service.py
from kubernetes import client, config

class TenantService:
    def __init__(self):
        config.load_incluster_config()
        self.v1 = client.CoreV1Api()
    
    async def create_tenant(self, user_id: str):
        namespace_name = f"tenant-{user_id}"
        
        # 1. Namespace 생성
        namespace = client.V1Namespace(
            metadata=client.V1ObjectMeta(
                name=namespace_name,
                labels={
                    "tenant": user_id,
                    "managed-by": "runna-platform"
                }
            )
        )
        self.v1.create_namespace(namespace)
        
        # 2. ResourceQuota 생성
        quota = client.V1ResourceQuota(
            metadata=client.V1ObjectMeta(name="tenant-quota"),
            spec=client.V1ResourceQuotaSpec(
                hard={
                    "requests.cpu": "2",
                    "requests.memory": "4Gi",
                    "limits.cpu": "4",
                    "limits.memory": "8Gi",
                    "pods": "10"
                }
            )
        )
        self.v1.create_namespaced_resource_quota(
            namespace=namespace_name,
            body=quota
        )
        
        # 3. NetworkPolicy 생성
        # (다음 섹션 참조)
        
        return namespace_name
```

#### 방법 B: ArgoCD Application 생성

**장점:**
- GitOps 방식
- 변경 이력 추적
- 선언적 관리

**단점:**
- 생성 시간 지연 (Git commit → ArgoCD sync)
- 복잡한 구조

**구현:**
```python
# backend/app/services/tenant_service.py
import yaml
from git import Repo

class TenantService:
    async def create_tenant_gitops(self, user_id: str):
        namespace_name = f"tenant-{user_id}"
        
        # 1. ArgoCD Application YAML 생성
        app_yaml = {
            "apiVersion": "argoproj.io/v1alpha1",
            "kind": "Application",
            "metadata": {
                "name": f"tenant-{user_id}",
                "namespace": "argocd"
            },
            "spec": {
                "project": "tenants",
                "source": {
                    "repoURL": "https://github.com/org/repo",
                    "path": f"tenants/{user_id}",
                    "targetRevision": "main"
                },
                "destination": {
                    "server": "https://kubernetes.default.svc",
                    "namespace": namespace_name
                },
                "syncPolicy": {
                    "automated": {
                        "prune": True,
                        "selfHeal": True
                    }
                }
            }
        }
        
        # 2. Git에 커밋
        repo = Repo("/path/to/repo")
        file_path = f"argocd/tenants/tenant-{user_id}.yaml"
        
        with open(file_path, 'w') as f:
            yaml.dump(app_yaml, f)
        
        repo.index.add([file_path])
        repo.index.commit(f"Create tenant: {user_id}")
        repo.remote().push()
        
        return namespace_name
```

**추천: 방법 A (Backend 직접 생성)**
- 해커톤에서는 빠른 구현이 중요
- 사용자 경험이 더 좋음
- 나중에 GitOps로 전환 가능

### 2. ResourceQuota 설정

각 테넌트의 리소스 사용량 제한:

```yaml
# k8s/tenant-templates/resource-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-quota
spec:
  hard:
    # CPU 제한
    requests.cpu: "2"      # 최소 보장 2 코어
    limits.cpu: "4"        # 최대 4 코어
    
    # 메모리 제한
    requests.memory: "4Gi" # 최소 보장 4GB
    limits.memory: "8Gi"   # 최대 8GB
    
    # Pod 개수 제한
    pods: "10"             # 최대 10개 함수
    
    # 스토리지 제한
    persistentvolumeclaims: "5"
    requests.storage: "10Gi"
```

### 3. NetworkPolicy 설정

테넌트 간 네트워크 격리:

```yaml
# k8s/tenant-templates/network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: tenant-isolation
spec:
  podSelector: {}  # 네임스페이스 내 모든 Pod
  
  policyTypes:
    - Ingress
    - Egress
  
  # Ingress: 들어오는 트래픽
  ingress:
    # 1. 같은 네임스페이스 내 통신 허용
    - from:
      - podSelector: {}
    
    # 2. Ingress Controller에서 들어오는 트래픽 허용
    - from:
      - namespaceSelector:
          matchLabels:
            name: ingress-nginx
    
    # 3. 모니터링 시스템 접근 허용
    - from:
      - namespaceSelector:
          matchLabels:
            name: monitoring
      ports:
        - protocol: TCP
          port: 9090  # Prometheus metrics
  
  # Egress: 나가는 트래픽
  egress:
    # 1. 같은 네임스페이스 내 통신 허용
    - to:
      - podSelector: {}
    
    # 2. DNS 조회 허용
    - to:
      - namespaceSelector:
          matchLabels:
            name: kube-system
      ports:
        - protocol: UDP
          port: 53
    
    # 3. 외부 인터넷 접근 허용 (필요시)
    - to:
      - namespaceSelector: {}
      ports:
        - protocol: TCP
          port: 443  # HTTPS
        - protocol: TCP
          port: 80   # HTTP
    
    # 4. Backend API 접근 허용
    - to:
      - namespaceSelector:
          matchLabels:
            name: platform-system
      - podSelector:
          matchLabels:
            app: backend
      ports:
        - protocol: TCP
          port: 8000
```

### 4. 라우팅 전략

#### 옵션 A: Subdomain 기반 (추천)

```
https://user001.functions.runna.io/my-function
https://user002.functions.runna.io/my-function
```

**Ingress 설정:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tenant-ingress
  namespace: tenant-user001
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - "user001.functions.runna.io"
      secretName: tenant-user001-tls
  rules:
    - host: "user001.functions.runna.io"
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: user-function
                port:
                  number: 80
```

#### 옵션 B: Path 기반

```
https://functions.runna.io/user001/my-function
https://functions.runna.io/user002/my-function
```

**Ingress 설정:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shared-ingress
  namespace: ingress-nginx
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
    - host: "functions.runna.io"
      http:
        paths:
          - path: /user001(/|$)(.*)
            pathType: Prefix
            backend:
              service:
                name: user-function
                namespace: tenant-user001
                port:
                  number: 80
```

**추천: 옵션 A (Subdomain)**
- 더 깔끔한 URL
- 테넌트 격리가 명확
- TLS 인증서 관리 용이

### 5. 보안 고려사항

#### ServiceAccount & RBAC

각 테넌트는 자신의 네임스페이스에만 접근:

```yaml
# k8s/tenant-templates/rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tenant-sa
  namespace: tenant-user001

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: tenant-role
  namespace: tenant-user001
rules:
  # Pod 조회만 허용
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
  
  # Service 조회만 허용
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: tenant-rolebinding
  namespace: tenant-user001
subjects:
  - kind: ServiceAccount
    name: tenant-sa
    namespace: tenant-user001
roleRef:
  kind: Role
  name: tenant-role
  apiGroup: rbac.authorization.k8s.io
```

#### Pod Security Standards

```yaml
# k8s/tenant-templates/pod-security.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-user001
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

## 📊 데이터베이스 설계

### 테넌트 테이블

```sql
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    namespace_name VARCHAR(63) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'creating',
    resource_quota JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    CONSTRAINT valid_namespace_name 
        CHECK (namespace_name ~ '^tenant-[a-z0-9]+$')
);

CREATE INDEX idx_tenants_user_id ON tenants(user_id);
CREATE INDEX idx_tenants_status ON tenants(status);
```

### 함수 테이블 (테넌트 연결)

```sql
CREATE TABLE functions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    name VARCHAR(255) NOT NULL,
    runtime VARCHAR(50) NOT NULL,
    code TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    knative_service_name VARCHAR(63),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    UNIQUE(tenant_id, name)
);

CREATE INDEX idx_functions_tenant_id ON functions(tenant_id);
```

## 🔄 함수 배포 플로우

```
사용자: 함수 생성 요청
  ↓
Backend: 함수 정보 저장 (DB)
  ↓
Backend: Knative Service YAML 생성
  ↓
Backend: K8s API로 배포 (테넌트 네임스페이스)
  ↓
Knative: 컨테이너 빌드 & 배포
  ↓
Backend: 함수 상태 업데이트 (ready)
  ↓
사용자: 함수 URL 받음
```

## 🎯 구현 우선순위

### Phase 3.1: 기본 멀티테넌시 (필수)
1. ✅ Namespace 자동 생성
2. ✅ ResourceQuota 설정
3. ✅ 테넌트별 함수 배포
4. ✅ 기본 라우팅

### Phase 3.2: 보안 강화 (중요)
1. ✅ NetworkPolicy 적용
2. ✅ RBAC 설정
3. ✅ Pod Security Standards

### Phase 3.3: 고급 기능 (선택)
1. ⏸️ 테넌트별 모니터링
2. ⏸️ 리소스 사용량 추적
3. ⏸️ 자동 스케일링 정책

## 📝 구현 체크리스트

### Backend 수정
- [ ] `TenantService` 클래스 작성
- [ ] Namespace 생성 API
- [ ] ResourceQuota 생성 로직
- [ ] NetworkPolicy 생성 로직
- [ ] 테넌트 상태 관리

### K8s 템플릿
- [ ] `k8s/tenant-templates/namespace.yaml`
- [ ] `k8s/tenant-templates/resource-quota.yaml`
- [ ] `k8s/tenant-templates/network-policy.yaml`
- [ ] `k8s/tenant-templates/rbac.yaml`

### 데이터베이스
- [ ] `tenants` 테이블 마이그레이션
- [ ] `functions` 테이블에 `tenant_id` 추가

### 테스트
- [ ] 테넌트 생성 테스트
- [ ] 네트워크 격리 테스트
- [ ] 리소스 제한 테스트

## 🚀 배포 시나리오

### 시나리오 1: 신규 사용자 가입

```bash
# 1. 사용자 회원가입
POST /api/auth/register
{
  "email": "user@example.com",
  "password": "password123"
}

# 2. 자동으로 테넌트 생성
# Backend가 자동으로:
# - Namespace 생성: tenant-user001
# - ResourceQuota 설정
# - NetworkPolicy 적용

# 3. 사용자 첫 함수 생성
POST /api/functions
{
  "name": "hello-world",
  "runtime": "python3.9",
  "code": "def handler(event): return 'Hello!'"
}

# 4. 함수 배포
# Backend가:
# - Knative Service 생성 (tenant-user001 네임스페이스)
# - 함수 URL 반환: https://user001.functions.runna.io/hello-world
```

### 시나리오 2: 리소스 제한 초과

```bash
# 사용자가 11번째 함수 생성 시도 (제한: 10개)
POST /api/functions
{
  "name": "function-11",
  "runtime": "python3.9",
  "code": "..."
}

# 응답:
{
  "error": "ResourceQuotaExceeded",
  "message": "테넌트 리소스 제한 초과: 최대 10개 함수까지 생성 가능"
}
```

## 📚 참고 자료

- [Kubernetes Multi-tenancy](https://kubernetes.io/docs/concepts/security/multi-tenancy/)
- [Knative Multi-tenancy](https://knative.dev/docs/serving/services/multi-tenancy/)
- [NetworkPolicy Guide](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

---

**작성일:** 2024-12-04
**작성자:** 서영
