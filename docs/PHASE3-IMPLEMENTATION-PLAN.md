# Phase 3: 멀티테넌시 구현 계획

## 🎯 목표

동규님이 지시한 두 가지 핵심 기능 구현:
1. **Namespace 자동 생성** - 사용자별 격리된 실행 환경
2. **Multi-tenancy Ingress Mapping** - 사용자 URL → Knative Service 자동 라우팅

## 📋 구현 순서

### Phase 3.1: Namespace 자동 생성 (1-2일)
### Phase 3.2: Ingress Mapping (3-4일) ⭐ 핵심!
### Phase 3.3: 통합 및 테스트 (1일)

---

## 🔧 Phase 3.1: Namespace 자동 생성

### 목표
사용자가 첫 함수를 생성할 때 자동으로 전용 Namespace 생성

### 아키텍처
```
사용자: 함수 생성 요청
  ↓
Backend API: /functions (POST)
  ↓
TenantService.ensure_namespace(user_id)
  ↓
K8s API: Namespace 존재 확인
  ↓
없으면 생성:
  - Namespace
  - ResourceQuota
  - NetworkPolicy
  - RBAC
  ↓
함수 배포 (Knative Service)
```

### 구현: TenantService

#### 파일 위치
```
backend-repo/app/services/tenant_service.py
```

#### 코드 구조
```python
from kubernetes import client, config
from kubernetes.client.rest import ApiException
import logging

logger = logging.getLogger(__name__)

class TenantService:
    """
    사용자별 Namespace 관리 서비스
    """
    
    def __init__(self):
        """K8s 클라이언트 초기화"""
        try:
            # 클러스터 내부에서 실행 시
            config.load_incluster_config()
        except:
            # 로컬 개발 시
            config.load_kube_config()
        
        self.core_v1 = client.CoreV1Api()
        self.rbac_v1 = client.RbacAuthorizationV1Api()
        self.networking_v1 = client.NetworkingV1Api()
    
    def ensure_namespace(self, user_id: str) -> str:
        """
        Namespace 존재 확인 및 생성
        
        Args:
            user_id: 사용자 ID
            
        Returns:
            namespace_name: 생성된 Namespace 이름
        """
        namespace_name = f"tenant-{user_id}"
        
        # 1. Namespace 존재 확인
        if self._namespace_exists(namespace_name):
            logger.info(f"Namespace {namespace_name} already exists")
            return namespace_name
        
        logger.info(f"Creating namespace {namespace_name}")
        
        # 2. Namespace 생성
        self._create_namespace(namespace_name, user_id)
        
        # 3. ResourceQuota 생성
        self._create_resource_quota(namespace_name)
        
        # 4. NetworkPolicy 생성
        self._create_network_policy(namespace_name)
        
        # 5. RBAC 생성
        self._create_rbac(namespace_name)
        
        logger.info(f"Namespace {namespace_name} created successfully")
        return namespace_name
    
    def _namespace_exists(self, namespace_name: str) -> bool:
        """Namespace 존재 여부 확인"""
        try:
            self.core_v1.read_namespace(namespace_name)
            return True
        except ApiException as e:
            if e.status == 404:
                return False
            raise
    
    def _create_namespace(self, namespace_name: str, user_id: str):
        """Namespace 생성"""
        namespace = client.V1Namespace(
            metadata=client.V1ObjectMeta(
                name=namespace_name,
                labels={
                    "tenant": user_id,
                    "managed-by": "runna-platform",
                    "pod-security.kubernetes.io/enforce": "restricted"
                }
            )
        )
        self.core_v1.create_namespace(namespace)
    
    def _create_resource_quota(self, namespace_name: str):
        """ResourceQuota 생성"""
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
        self.core_v1.create_namespaced_resource_quota(
            namespace=namespace_name,
            body=quota
        )
    
    def _create_network_policy(self, namespace_name: str):
        """NetworkPolicy 생성 - 테넌트 간 격리"""
        # Ingress: 같은 네임스페이스 + Ingress Controller만 허용
        network_policy = client.V1NetworkPolicy(
            metadata=client.V1ObjectMeta(name="tenant-isolation"),
            spec=client.V1NetworkPolicySpec(
                pod_selector=client.V1LabelSelector(),
                policy_types=["Ingress", "Egress"],
                ingress=[
                    # 같은 네임스페이스
                    client.V1NetworkPolicyIngressRule(
                        from_=[client.V1NetworkPolicyPeer(
                            pod_selector=client.V1LabelSelector()
                        )]
                    ),
                    # Ingress Controller
                    client.V1NetworkPolicyIngressRule(
                        from_=[client.V1NetworkPolicyPeer(
                            namespace_selector=client.V1LabelSelector(
                                match_labels={"name": "ingress-nginx"}
                            )
                        )]
                    )
                ],
                egress=[
                    # 같은 네임스페이스
                    client.V1NetworkPolicyEgressRule(
                        to=[client.V1NetworkPolicyPeer(
                            pod_selector=client.V1LabelSelector()
                        )]
                    ),
                    # DNS
                    client.V1NetworkPolicyEgressRule(
                        to=[client.V1NetworkPolicyPeer(
                            namespace_selector=client.V1LabelSelector(
                                match_labels={"name": "kube-system"}
                            )
                        )],
                        ports=[client.V1NetworkPolicyPort(
                            protocol="UDP",
                            port=53
                        )]
                    ),
                    # 외부 인터넷
                    client.V1NetworkPolicyEgressRule(
                        to=[client.V1NetworkPolicyPeer(
                            namespace_selector=client.V1LabelSelector()
                        )],
                        ports=[
                            client.V1NetworkPolicyPort(protocol="TCP", port=443),
                            client.V1NetworkPolicyPort(protocol="TCP", port=80)
                        ]
                    )
                ]
            )
        )
        self.networking_v1.create_namespaced_network_policy(
            namespace=namespace_name,
            body=network_policy
        )
    
    def _create_rbac(self, namespace_name: str):
        """RBAC 생성 - ServiceAccount + Role + RoleBinding"""
        # ServiceAccount
        sa = client.V1ServiceAccount(
            metadata=client.V1ObjectMeta(name="tenant-sa")
        )
        self.core_v1.create_namespaced_service_account(
            namespace=namespace_name,
            body=sa
        )
        
        # Role (읽기 전용)
        role = client.V1Role(
            metadata=client.V1ObjectMeta(name="tenant-role"),
            rules=[
                client.V1PolicyRule(
                    api_groups=[""],
                    resources=["pods", "pods/log", "services"],
                    verbs=["get", "list", "watch"]
                ),
                client.V1PolicyRule(
                    api_groups=["serving.knative.dev"],
                    resources=["services", "revisions"],
                    verbs=["get", "list", "watch"]
                )
            ]
        )
        self.rbac_v1.create_namespaced_role(
            namespace=namespace_name,
            body=role
        )
        
        # RoleBinding
        role_binding = client.V1RoleBinding(
            metadata=client.V1ObjectMeta(name="tenant-rolebinding"),
            subjects=[client.V1Subject(
                kind="ServiceAccount",
                name="tenant-sa",
                namespace=namespace_name
            )],
            role_ref=client.V1RoleRef(
                api_group="rbac.authorization.k8s.io",
                kind="Role",
                name="tenant-role"
            )
        )
        self.rbac_v1.create_namespaced_role_binding(
            namespace=namespace_name,
            body=role_binding
        )
```

### Backend API 통합

#### 수정: `backend-repo/app/api/functions.py`

```python
from app.services.tenant_service import TenantService

tenant_service = TenantService()

@router.post("/", response_model=FunctionResponse)
async def create_function(
    function: FunctionCreate,
    current_user: User = Depends(get_current_user)
):
    """함수 생성"""
    
    # 1. Namespace 확인/생성
    namespace = tenant_service.ensure_namespace(current_user.id)
    
    # 2. 함수 생성 (기존 로직)
    # ...
    
    # 3. Knative Service 배포
    # namespace 파라미터 추가
    knative_service = deploy_knative_service(
        function_name=function.name,
        namespace=namespace,  # 사용자 전용 namespace
        code=function.code,
        runtime=function.runtime
    )
    
    return function_response
```

---

## 🌐 Phase 3.2: Multi-tenancy Ingress Mapping ⭐

### 목표
사용자 친화적 URL을 Knative Service 내부 URL로 자동 매핑

### 문제 정의

**사용자가 원하는 것:**
```
https://user001.runna.dev/my-function
```

**Knative가 생성하는 것:**
```
my-function.tenant-user001.svc.cluster.local
```

**우리가 해야 할 것:**
이 둘을 자동으로 연결하는 Ingress Rule 생성!

### 아키텍처

```
사용자 요청: https://user001.runna.dev/my-function
  ↓
Ingress Controller (Nginx)
  ↓
Ingress Rule 확인
  - Host: user001.runna.dev
  - Path: /my-function
  ↓
Backend Service 매핑
  - Service: my-function.tenant-user001.svc.cluster.local
  ↓
Knative Service (사용자 함수 실행)
  ↓
응답 반환
```

### 라우팅 전략

#### 옵션 A: Subdomain 기반 (추천!)
```
user001.runna.dev/hello    → hello.tenant-user001.svc.cluster.local
user001.runna.dev/world    → world.tenant-user001.svc.cluster.local
user002.runna.dev/test     → test.tenant-user002.svc.cluster.local
```

**장점:**
- 사용자별 명확한 격리
- URL이 깔끔함
- TLS 인증서 관리 용이 (Wildcard: `*.runna.dev`)

#### 옵션 B: Path 기반
```
runna.dev/user001/hello    → hello.tenant-user001.svc.cluster.local
runna.dev/user002/test     → test.tenant-user002.svc.cluster.local
```

**단점:**
- URL이 길어짐
- Path rewrite 복잡

**결정: 옵션 A (Subdomain) 사용**

### 구현: IngressMapper

#### 파일 위치
```
backend-repo/app/services/ingress_mapper.py
```

#### 코드 구조

```python
from kubernetes import client, config
from kubernetes.client.rest import ApiException
import logging

logger = logging.getLogger(__name__)

class IngressMapper:
    """
    Multi-tenancy Ingress 매핑 서비스
    사용자 URL → Knative Service 자동 라우팅
    """
    
    def __init__(self):
        """K8s 클라이언트 초기화"""
        try:
            config.load_incluster_config()
        except:
            config.load_kube_config()
        
        self.networking_v1 = client.NetworkingV1Api()
        self.base_domain = "runna.dev"  # 환경변수로 설정 가능
    
    def create_function_ingress(
        self,
        user_id: str,
        function_name: str,
        namespace: str
    ) -> str:
        """
        함수용 Ingress Rule 생성
        
        Args:
            user_id: 사용자 ID
            function_name: 함수 이름
            namespace: Knative Service가 배포된 Namespace
            
        Returns:
            public_url: 사용자가 접근할 수 있는 URL
        """
        ingress_name = f"{function_name}-ingress"
        host = f"{user_id}.{self.base_domain}"
        path = f"/{function_name}"
        
        # Knative Service 이름
        # Knative는 Service와 동일한 이름의 K8s Service를 생성
        knative_service_name = function_name
        
        logger.info(f"Creating Ingress: {host}{path} → {knative_service_name}.{namespace}")
        
        # Ingress 생성
        ingress = client.V1Ingress(
            metadata=client.V1ObjectMeta(
                name=ingress_name,
                namespace=namespace,
                labels={
                    "app": function_name,
                    "tenant": user_id,
                    "managed-by": "runna-platform"
                },
                annotations={
                    # Nginx Ingress 설정
                    "kubernetes.io/ingress.class": "nginx",
                    "cert-manager.io/cluster-issuer": "letsencrypt-prod",
                    
                    # Path rewrite (선택사항)
                    # /my-function → / 로 변환
                    "nginx.ingress.kubernetes.io/rewrite-target": "/",
                    
                    # CORS 설정
                    "nginx.ingress.kubernetes.io/enable-cors": "true",
                    "nginx.ingress.kubernetes.io/cors-allow-origin": "*",
                    
                    # Timeout 설정 (서버리스 함수용)
                    "nginx.ingress.kubernetes.io/proxy-read-timeout": "300",
                    "nginx.ingress.kubernetes.io/proxy-send-timeout": "300"
                }
            ),
            spec=client.V1IngressSpec(
                tls=[
                    client.V1IngressTLS(
                        hosts=[host],
                        secret_name=f"{user_id}-tls"
                    )
                ],
                rules=[
                    client.V1IngressRule(
                        host=host,
                        http=client.V1HTTPIngressRuleValue(
                            paths=[
                                client.V1HTTPIngressPath(
                                    path=path,
                                    path_type="Prefix",
                                    backend=client.V1IngressBackend(
                                        service=client.V1IngressServiceBackend(
                                            name=knative_service_name,
                                            port=client.V1ServiceBackendPort(
                                                number=80
                                            )
                                        )
                                    )
                                )
                            ]
                        )
                    )
                ]
            )
        )
        
        try:
            self.networking_v1.create_namespaced_ingress(
                namespace=namespace,
                body=ingress
            )
            logger.info(f"Ingress {ingress_name} created successfully")
        except ApiException as e:
            if e.status == 409:  # Already exists
                logger.info(f"Ingress {ingress_name} already exists, updating...")
                self.networking_v1.patch_namespaced_ingress(
                    name=ingress_name,
                    namespace=namespace,
                    body=ingress
                )
            else:
                raise
        
        # 공개 URL 반환
        public_url = f"https://{host}{path}"
        return public_url
    
    def delete_function_ingress(
        self,
        function_name: str,
        namespace: str
    ):
        """함수 삭제 시 Ingress Rule 제거"""
        ingress_name = f"{function_name}-ingress"
        
        try:
            self.networking_v1.delete_namespaced_ingress(
                name=ingress_name,
                namespace=namespace
            )
            logger.info(f"Ingress {ingress_name} deleted")
        except ApiException as e:
            if e.status == 404:
                logger.warning(f"Ingress {ingress_name} not found")
            else:
                raise
    
    def list_user_ingresses(self, user_id: str) -> list:
        """사용자의 모든 Ingress 조회"""
        namespace = f"tenant-{user_id}"
        
        try:
            ingresses = self.networking_v1.list_namespaced_ingress(
                namespace=namespace,
                label_selector=f"tenant={user_id}"
            )
            
            return [
                {
                    "name": ing.metadata.name,
                    "host": ing.spec.rules[0].host if ing.spec.rules else None,
                    "path": ing.spec.rules[0].http.paths[0].path if ing.spec.rules else None,
                    "url": f"https://{ing.spec.rules[0].host}{ing.spec.rules[0].http.paths[0].path}" if ing.spec.rules else None
                }
                for ing in ingresses.items
            ]
        except ApiException as e:
            if e.status == 404:
                return []
            raise
```

### Knative Service와 통합

#### 중요: Knative Service 이름 규칙

Knative는 Service를 생성하면 자동으로 K8s Service도 생성합니다:
```
Knative Service: my-function
  ↓ 자동 생성
K8s Service: my-function (같은 이름!)
  ↓
내부 DNS: my-function.tenant-user001.svc.cluster.local
```

따라서 Ingress의 backend는 Knative Service 이름을 그대로 사용하면 됩니다!

### Backend API 통합

#### 수정: `backend-repo/app/api/functions.py`

```python
from app.services.tenant_service import TenantService
from app.services.ingress_mapper import IngressMapper

tenant_service = TenantService()
ingress_mapper = IngressMapper()

@router.post("/", response_model=FunctionResponse)
async def create_function(
    function: FunctionCreate,
    current_user: User = Depends(get_current_user)
):
    """함수 생성"""
    
    # 1. Namespace 확인/생성
    namespace = tenant_service.ensure_namespace(current_user.id)
    
    # 2. Knative Service 배포
    knative_service = deploy_knative_service(
        function_name=function.name,
        namespace=namespace,
        code=function.code,
        runtime=function.runtime
    )
    
    # 3. Ingress Mapping 생성 ⭐ 새로 추가!
    public_url = ingress_mapper.create_function_ingress(
        user_id=current_user.id,
        function_name=function.name,
        namespace=namespace
    )
    
    # 4. DB에 저장
    db_function = Function(
        name=function.name,
        user_id=current_user.id,
        namespace=namespace,
        public_url=public_url,  # 사용자에게 제공할 URL
        knative_service=knative_service.name
    )
    db.add(db_function)
    db.commit()
    
    return FunctionResponse(
        id=db_function.id,
        name=db_function.name,
        url=public_url,  # https://user001.runna.dev/my-function
        status="deployed"
    )

@router.delete("/{function_id}")
async def delete_function(
    function_id: str,
    current_user: User = Depends(get_current_user)
):
    """함수 삭제"""
    
    function = db.query(Function).filter(
        Function.id == function_id,
        Function.user_id == current_user.id
    ).first()
    
    if not function:
        raise HTTPException(status_code=404, detail="Function not found")
    
    # 1. Ingress 삭제
    ingress_mapper.delete_function_ingress(
        function_name=function.name,
        namespace=function.namespace
    )
    
    # 2. Knative Service 삭제
    delete_knative_service(function.name, function.namespace)
    
    # 3. DB에서 삭제
    db.delete(function)
    db.commit()
    
    return {"message": "Function deleted"}
```

---

## 🧪 Phase 3.3: 테스트

### 테스트 시나리오

#### 1. Namespace 자동 생성 테스트
```python
# tests/test_tenant_service.py
def test_namespace_creation():
    service = TenantService()
    
    # 첫 번째 호출: 생성
    ns1 = service.ensure_namespace("test-user-001")
    assert ns1 == "tenant-test-user-001"
    
    # 두 번째 호출: 이미 존재 (재사용)
    ns2 = service.ensure_namespace("test-user-001")
    assert ns2 == ns1
    
    # ResourceQuota 확인
    quota = service.core_v1.read_namespaced_resource_quota(
        name="tenant-quota",
        namespace=ns1
    )
    assert quota.spec.hard["pods"] == "10"
```

#### 2. Ingress Mapping 테스트
```python
# tests/test_ingress_mapper.py
def test_ingress_creation():
    mapper = IngressMapper()
    
    # Ingress 생성
    url = mapper.create_function_ingress(
        user_id="test-user-001",
        function_name="hello-world",
        namespace="tenant-test-user-001"
    )
    
    assert url == "https://test-user-001.runna.dev/hello-world"
    
    # Ingress 확인
    ingress = mapper.networking_v1.read_namespaced_ingress(
        name="hello-world-ingress",
        namespace="tenant-test-user-001"
    )
    
    assert ingress.spec.rules[0].host == "test-user-001.runna.dev"
    assert ingress.spec.rules[0].http.paths[0].path == "/hello-world"
```

#### 3. 통합 테스트
```bash
# 1. 사용자 생성
curl -X POST https://api.runna.dev/auth/register \
  -d '{"email":"test@example.com","password":"test123"}'

# 2. 함수 생성
curl -X POST https://api.runna.dev/functions \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name":"hello",
    "runtime":"python3.9",
    "code":"def handler(event): return {\"message\": \"Hello!\"}"
  }'

# 응답:
# {
#   "id": "func-123",
#   "name": "hello",
#   "url": "https://user001.runna.dev/hello",
#   "status": "deployed"
# }

# 3. 함수 호출
curl https://user001.runna.dev/hello

# 응답:
# {"message": "Hello!"}
```

---

## 📋 구현 체크리스트

### Phase 3.1: Namespace 자동 생성
- [ ] `TenantService` 클래스 작성
- [ ] Namespace 생성 로직
- [ ] ResourceQuota 설정
- [ ] NetworkPolicy 설정
- [ ] RBAC 설정
- [ ] Backend API 통합
- [ ] 단위 테스트 작성

### Phase 3.2: Ingress Mapping
- [ ] `IngressMapper` 클래스 작성
- [ ] Subdomain 기반 라우팅 구현
- [ ] Ingress Rule 자동 생성
- [ ] TLS 인증서 설정 (cert-manager)
- [ ] Knative Service 연동
- [ ] Backend API 통합
- [ ] 단위 테스트 작성

### Phase 3.3: 통합 및 테스트
- [ ] 통합 테스트 시나리오 작성
- [ ] End-to-end 테스트
- [ ] 성능 테스트
- [ ] 문서 작성

---

## 🚀 배포 순서

1. **Backend 코드 배포**
   - `TenantService` 추가
   - `IngressMapper` 추가
   - API 수정

2. **K8s 권한 설정**
   - Backend ServiceAccount에 ClusterRole 부여
   - Namespace 생성 권한
   - Ingress 생성 권한

3. **DNS 설정**
   - Wildcard DNS: `*.runna.dev` → Ingress Controller IP

4. **TLS 인증서**
   - cert-manager 설치
   - ClusterIssuer 설정 (Let's Encrypt)

5. **테스트**
   - 개발 환경에서 테스트
   - Staging 환경 검증
   - Production 배포

---

**작성일:** 2024-12-04
**작성자:** 서영
**동규님 지시사항 반영**
