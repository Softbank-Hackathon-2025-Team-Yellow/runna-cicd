# 설계 문서

## 개요

본 시스템은 K3s + Knative + Kourier 기반의 멀티테넌트 서버리스 플랫폼입니다. 함수별로 격리된 Namespace를 자동 생성하고, Knative Service를 통해 함수를 배포하며, Ingress Rule을 통해 사용자 친화적인 URL로 라우팅합니다.

**설계 원칙:**
- **함수별 격리**: 1 function = 1 namespace로 완전한 격리 보장
- **자동화 우선**: Namespace, Knative Service, Ingress Rule 자동 생성
- **유연한 스토리지**: 공유 PVC 또는 함수별 PVC 전략 선택 가능
- **보안 강화**: NetworkPolicy, ResourceQuota, RBAC를 통한 다층 보안

**핵심 흐름:**
```
함수 생성 요청
  ↓
Namespace 자동 생성 ({workspace}-{function_id})
  ↓
ResourceQuota + NetworkPolicy 적용
  ↓
PVC에 함수 코드 저장
  ↓
Knative Service 배포 (worker-run 노드)
  ↓
Ingress Rule 생성
  ↓
공개 URL 반환 (https://{workspace}.runna.haifu.cloud/{function})
```

**기술 스택:**
- 클러스터: K3s
- 서버리스: Knative Serving
- Ingress: Kourier
- 스토리지: PVC (ReadOnlyMany)
- Queue: Redis (queue-redis-master.default.svc.cluster.local)
- 런타임: Generic Runner (Python/Node.js/etc)


## 아키텍처

```mermaid
graph TB
    subgraph "사용자"
        USER[사용자] -->|함수 생성| API[Backend API]
    end
    
    subgraph "Backend 서비스"
        API -->|1. Namespace 생성| TS[TenantService]
        API -->|2. 코드 저장| PVC[PVC Storage]
        API -->|3. 함수 배포| KS[Knative Service]
        API -->|4. 라우팅 설정| IM[IngressMapper]
    end
    
    subgraph "K8s 클러스터"
        TS -->|생성| NS[Namespace: {workspace}-{function_id}]
        NS -->|포함| RQ[ResourceQuota]
        NS -->|포함| NP[NetworkPolicy]
        
        KS -->|배포| KSVC[Knative Service]
        KSVC -->|실행| POD[Generic Runner Pod]
        POD -->|마운트| PVC
        
        IM -->|생성| ING[Ingress Rule]
        ING -->|라우팅| KOURIER[Kourier Gateway]
    end
    
    subgraph "외부 접근"
        KOURIER -->|트래픽| POD
        USER2[외부 사용자] -->|HTTPS| URL[{workspace}.runna.haifu.cloud/{function}]
        URL -->|ALB| KOURIER
    end
    
    subgraph "공유 서비스"
        POD -->|큐 접근| REDIS[Redis Queue]
    end
```


## 컴포넌트 및 인터페이스

### 1. TenantService

**책임:**
- 함수별 Namespace 자동 생성
- ResourceQuota 설정
- NetworkPolicy 적용
- RBAC 설정

**인터페이스:**

```python
class TenantService:
    """함수별 Namespace 관리 서비스"""
    
    def __init__(self):
        """K8s 클라이언트 초기화"""
        config.load_incluster_config()
        self.core_v1 = client.CoreV1Api()
        self.rbac_v1 = client.RbacAuthorizationV1Api()
        self.networking_v1 = client.NetworkingV1Api()
    
    def ensure_namespace(
        self, 
        workspace: str, 
        function_id: str
    ) -> str:
        """
        Namespace 존재 확인 및 생성
        
        Args:
            workspace: Workspace ID
            function_id: Function ID (UUID without hyphens)
            
        Returns:
            namespace_name: {workspace}-{function_id}
        """
        namespace_name = f"{workspace}-{function_id}"
        
        if self._namespace_exists(namespace_name):
            return namespace_name
        
        self._create_namespace(namespace_name, workspace, function_id)
        self._create_resource_quota(namespace_name)
        self._create_network_policy(namespace_name)
        
        return namespace_name
```


**Namespace 생성 로직:**

```python
def _create_namespace(
    self, 
    namespace_name: str, 
    workspace: str, 
    function_id: str
):
    """Namespace 생성"""
    namespace = client.V1Namespace(
        metadata=client.V1ObjectMeta(
            name=namespace_name,
            labels={
                "workspace": workspace,
                "function-id": function_id,
                "managed-by": "runna-platform",
                "pod-security.kubernetes.io/enforce": "restricted"
            }
        )
    )
    self.core_v1.create_namespace(namespace)
```

**ResourceQuota 생성:**

```python
def _create_resource_quota(self, namespace_name: str):
    """k8s/policies/resource-quota-template.yaml 기반 생성"""
    # 템플릿 로드
    with open("k8s/policies/resource-quota-template.yaml") as f:
        quota_template = yaml.safe_load(f)
    
    quota = client.V1ResourceQuota(
        metadata=client.V1ObjectMeta(name="function-quota"),
        spec=client.V1ResourceQuotaSpec(
            hard=quota_template["spec"]["hard"]
        )
    )
    self.core_v1.create_namespaced_resource_quota(
        namespace=namespace_name,
        body=quota
    )
```


**NetworkPolicy 생성:**

```python
def _create_network_policy(self, namespace_name: str):
    """NetworkPolicy 생성 - 함수 간 격리"""
    network_policy = client.V1NetworkPolicy(
        metadata=client.V1ObjectMeta(name="function-isolation"),
        spec=client.V1NetworkPolicySpec(
            pod_selector=client.V1LabelSelector(),
            policy_types=["Ingress", "Egress"],
            ingress=[
                # 같은 Namespace 내 통신
                client.V1NetworkPolicyIngressRule(
                    from_=[client.V1NetworkPolicyPeer(
                        pod_selector=client.V1LabelSelector()
                    )]
                ),
                # Kourier Ingress
                client.V1NetworkPolicyIngressRule(
                    from_=[client.V1NetworkPolicyPeer(
                        namespace_selector=client.V1LabelSelector(
                            match_labels={"serving.knative.dev/release": "devel"}
                        )
                    )]
                )
            ],
            egress=[
                # 같은 Namespace
                client.V1NetworkPolicyEgressRule(
                    to=[client.V1NetworkPolicyPeer(
                        pod_selector=client.V1LabelSelector()
                    )]
                ),
                # DNS
                client.V1NetworkPolicyEgressRule(
                    to=[client.V1NetworkPolicyPeer(
                        namespace_selector=client.V1LabelSelector(
                            match_labels={"kubernetes.io/metadata.name": "kube-system"}
                        )
                    )],
                    ports=[client.V1NetworkPolicyPort(protocol="UDP", port=53)]
                ),
                # Redis Queue (default namespace)
                client.V1NetworkPolicyEgressRule(
                    to=[client.V1NetworkPolicyPeer(
                        namespace_selector=client.V1LabelSelector(
                            match_labels={"kubernetes.io/metadata.name": "default"}
                        )
                    )],
                    ports=[client.V1NetworkPolicyPort(protocol="TCP", port=6379)]
                )
            ]
        )
    )
    self.networking_v1.create_namespaced_network_policy(
        namespace=namespace_name,
        body=network_policy
    )
```


### 2. IngressMapper

**책임:**
- Ingress Rule 자동 생성
- Workspace 기반 URL 매핑
- TLS 인증서 설정

**인터페이스:**

```python
class IngressMapper:
    """Ingress Rule 자동 생성 서비스"""
    
    def __init__(self):
        config.load_incluster_config()
        self.networking_v1 = client.NetworkingV1Api()
        self.base_domain = "runna.haifu.cloud"
    
    def create_function_ingress(
        self,
        workspace: str,
        function_name: str,
        namespace: str
    ) -> str:
        """
        Ingress Rule 생성
        
        Args:
            workspace: Workspace ID
            function_name: 함수 이름
            namespace: Knative Service가 배포된 Namespace
            
        Returns:
            public_url: https://{workspace}.runna.haifu.cloud/{function_name}
        """
        ingress_name = f"{function_name}-ingress"
        host = f"{workspace}.{self.base_domain}"
        path = f"/{function_name}"
        
        # Knative Service 이름 (Knative가 자동으로 K8s Service 생성)
        knative_service_name = function_name
        
        ingress = client.V1Ingress(
            metadata=client.V1ObjectMeta(
                name=ingress_name,
                namespace=namespace,
                labels={
                    "app": function_name,
                    "workspace": workspace,
                    "managed-by": "runna-platform"
                },
                annotations={
                    "kubernetes.io/ingress.class": "kourier.ingress.networking.knative.dev",
                    "cert-manager.io/cluster-issuer": "letsencrypt-prod",
                    "nginx.ingress.kubernetes.io/rewrite-target": "/",
                    "nginx.ingress.kubernetes.io/enable-cors": "true",
                    "nginx.ingress.kubernetes.io/cors-allow-origin": "*"
                }
            ),
            spec=client.V1IngressSpec(
                tls=[client.V1IngressTLS(
                    hosts=[host],
                    secret_name=f"{workspace}-tls"
                )],
                rules=[client.V1IngressRule(
                    host=host,
                    http=client.V1HTTPIngressRuleValue(
                        paths=[client.V1HTTPIngressPath(
                            path=path,
                            path_type="Prefix",
                            backend=client.V1IngressBackend(
                                service=client.V1IngressServiceBackend(
                                    name=knative_service_name,
                                    port=client.V1ServiceBackendPort(number=80)
                                )
                            )
                        )]
                    )
                )]
            )
        )
        
        self.networking_v1.create_namespaced_ingress(
            namespace=namespace,
            body=ingress
        )
        
        return f"https://{host}{path}"
```


### 3. Knative Service 배포

**책임:**
- Knative Service 생성
- Generic Runner 이미지 사용
- PVC 마운트
- 환경변수 설정

**배포 로직:**

```python
def deploy_knative_service(
    function_name: str,
    namespace: str,
    runtime: str,
    pvc_name: str
) -> dict:
    """Knative Service 배포"""
    
    knative_service = {
        "apiVersion": "serving.knative.dev/v1",
        "kind": "Service",
        "metadata": {
            "name": function_name,
            "namespace": namespace,
            "labels": {
                "app": function_name,
                "managed-by": "runna-platform"
            }
        },
        "spec": {
            "template": {
                "metadata": {
                    "annotations": {
                        "autoscaling.knative.dev/minScale": "1",
                        "autoscaling.knative.dev/maxScale": "10"
                    }
                },
                "spec": {
                    # worker-run 노드에 배포
                    "nodeSelector": {
                        "role": "run"
                    },
                    "containers": [{
                        "name": "user-function",
                        "image": f"generic-runner:{runtime}",
                        "ports": [{
                            "containerPort": 8080,
                            "protocol": "TCP"
                        }],
                        "env": [
                            {
                                "name": "FUNCTION_CODE",
                                "value": f"/app/functions/{function_name}/main.py"
                            },
                            {
                                "name": "REDIS_HOST",
                                "value": "queue-redis-master.default.svc.cluster.local"
                            },
                            {
                                "name": "REDIS_PORT",
                                "value": "6379"
                            }
                        ],
                        "volumeMounts": [{
                            "name": "function-storage",
                            "mountPath": "/app/functions",
                            "readOnly": True
                        }],
                        "resources": {
                            "limits": {
                                "cpu": "500m",
                                "memory": "512Mi"
                            },
                            "requests": {
                                "cpu": "250m",
                                "memory": "256Mi"
                            }
                        }
                    }],
                    "volumes": [{
                        "name": "function-storage",
                        "persistentVolumeClaim": {
                            "claimName": pvc_name,
                            "readOnly": True
                        }
                    }]
                }
            }
        }
    }
    
    # K8s API로 생성
    from kubernetes import utils
    utils.create_from_dict(
        api_client, 
        knative_service, 
        namespace=namespace
    )
    
    return knative_service
```


### 4. PVC 관리

**전략 1: 공유 PVC (추천)**

```python
def save_code_to_shared_pvc(
    function_name: str,
    code: str,
    workspace: str
):
    """공유 PVC에 함수 코드 저장"""
    # PVC 마운트 경로: /mnt/functions
    function_dir = f"/mnt/functions/{workspace}/{function_name}"
    os.makedirs(function_dir, exist_ok=True)
    
    with open(f"{function_dir}/main.py", "w") as f:
        f.write(code)
    
    return "runner-pvc"  # 공유 PVC 이름
```

**전략 2: 함수별 PVC**

```python
def create_function_pvc(
    function_name: str,
    namespace: str
) -> str:
    """함수별 PVC 생성"""
    pvc_name = f"{function_name}-pvc"
    
    pvc = client.V1PersistentVolumeClaim(
        metadata=client.V1ObjectMeta(name=pvc_name),
        spec=client.V1PersistentVolumeClaimSpec(
            access_modes=["ReadOnlyMany"],
            resources=client.V1ResourceRequirements(
                requests={"storage": "1Gi"}
            )
        )
    )
    
    core_v1.create_namespaced_persistent_volume_claim(
        namespace=namespace,
        body=pvc
    )
    
    return pvc_name
```


## 데이터 모델

### 1. Workspace

```python
class Workspace(Base):
    __tablename__ = "workspaces"
    
    id = Column(String(63), primary_key=True)  # URL-safe string
    user_id = Column(UUID, ForeignKey("users.id"), nullable=False)
    name = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    functions = relationship("Function", back_populates="workspace", cascade="all, delete-orphan")
    
    __table_args__ = (
        Index("idx_workspaces_user_id", "user_id"),
        CheckConstraint("id ~ '^[a-z0-9-]+$'", name="valid_workspace_id"),
    )
```

### 2. Function

```python
class Function(Base):
    __tablename__ = "functions"
    
    id = Column(UUID, primary_key=True, default=uuid.uuid4)
    workspace_id = Column(String(63), ForeignKey("workspaces.id"), nullable=False)
    name = Column(String(255), nullable=False)
    runtime = Column(String(50), nullable=False)  # python3.9, nodejs18, etc
    code = Column(Text, nullable=False)
    
    # K8s 리소스 정보
    namespace = Column(String(63), nullable=False)  # {workspace}-{function_id}
    knative_service_name = Column(String(63), nullable=False)
    public_url = Column(String(512), nullable=False)
    
    # 상태
    status = Column(String(20), default="pending")  # pending, deploying, ready, failed
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    workspace = relationship("Workspace", back_populates="functions")
    
    __table_args__ = (
        UniqueConstraint("workspace_id", "name", name="uq_workspace_function_name"),
        Index("idx_functions_workspace_id", "workspace_id"),
        Index("idx_functions_status", "status"),
    )
```

### 3. Function ID 생성 규칙

```python
def generate_function_id() -> str:
    """
    UUID v4 기반 Function ID 생성
    
    Returns:
        32자 문자열 (하이픈 제거)
        예: "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
    """
    return str(uuid.uuid4()).replace("-", "")

def generate_namespace_name(workspace: str, function_id: str) -> str:
    """
    Namespace 이름 생성
    
    Args:
        workspace: Workspace ID (URL-safe)
        function_id: Function ID (32자)
        
    Returns:
        {workspace}-{function_id} (최대 63자)
    """
    namespace = f"{workspace}-{function_id}"
    
    # K8s 네이밍 규칙 검증
    if len(namespace) > 63:
        raise ValueError(f"Namespace name too long: {len(namespace)} > 63")
    
    if not re.match(r'^[a-z0-9]([-a-z0-9]*[a-z0-9])?$', namespace):
        raise ValueError(f"Invalid namespace name: {namespace}")
    
    return namespace
```


## 정확성 속성

*속성(Property)은 시스템의 모든 유효한 실행에서 참이어야 하는 특성 또는 동작입니다. 속성은 인간이 읽을 수 있는 명세와 기계가 검증할 수 있는 정확성 보장 사이의 다리 역할을 합니다.*

### 속성 1: Namespace 자동 생성

*모든* 함수 생성 요청에 대해, 시스템은 함수별 고유한 Namespace를 자동으로 생성해야 합니다.

**검증: 요구사항 1.1**

### 속성 2: Namespace 네이밍 규칙

*모든* 생성된 Namespace에 대해, 이름은 "{workspace}-{function_id}" 형식을 따라야 하며 쿠버네티스 네이밍 규칙을 준수해야 합니다.

**검증: 요구사항 1.2, 13.4**

### 속성 3: Namespace 생성 멱등성

*모든* 함수에 대해, 동일한 함수를 여러 번 생성 시도하면 Namespace는 한 번만 생성되고 이후에는 재사용되어야 합니다.

**검증: 요구사항 1.3**

### 속성 4: ResourceQuota 자동 생성

*모든* Namespace 생성에 대해, ResourceQuota가 자동으로 함께 생성되어야 합니다.

**검증: 요구사항 2.1**

### 속성 5: NetworkPolicy 자동 생성

*모든* Namespace 생성에 대해, NetworkPolicy가 자동으로 함께 생성되어야 합니다.

**검증: 요구사항 3.1**

### 속성 6: Knative Service 포트 일관성

*모든* Knative Service에 대해, 컨테이너 포트는 8080으로 설정되어야 합니다.

**검증: 요구사항 4.3**

### 속성 7: PVC 읽기 전용 마운트

*모든* Knative Service에 대해, PVC는 읽기 전용(readOnly=true)으로 마운트되어야 합니다.

**검증: 요구사항 5.5**

### 속성 8: URL 형식 일관성

*모든* 생성된 공개 URL에 대해, "https://{workspace}.runna.haifu.cloud/{function}" 형식을 따라야 합니다.

**검증: 요구사항 6.2**

### 속성 9: 함수 삭제 시 리소스 정리

*모든* 함수에 대해, 함수를 생성한 후 삭제하면 모든 관련 리소스(Namespace, Knative Service, Ingress Rule)가 정리되어야 합니다.

**검증: 요구사항 10.3, 10.4, 10.5**

### 속성 10: Workspace ID 문자 집합

*모든* Workspace ID에 대해, URL 안전한 문자(소문자, 숫자, 하이픈)만 포함해야 합니다.

**검증: 요구사항 12.2**

### 속성 11: Function ID UUID 형식

*모든* Function ID에 대해, 유효한 UUID v4 형식이어야 합니다.

**검증: 요구사항 13.2**

### 속성 12: Function ID 길이 일관성

*모든* Function ID에 대해, 하이픈을 제거한 32자 문자열이어야 합니다.

**검증: 요구사항 13.3**


## 에러 처리

### 1. Namespace 생성 실패

**시나리오:**
- Namespace 이름이 이미 존재
- 쿠버네티스 API 접근 실패
- 권한 부족

**처리 전략:**
```python
try:
    namespace = tenant_service.ensure_namespace(workspace, function_id)
except ApiException as e:
    if e.status == 409:  # Already exists
        logger.info(f"Namespace already exists: {namespace_name}")
        return namespace_name
    elif e.status == 403:  # Forbidden
        logger.error(f"Permission denied creating namespace: {e}")
        raise PermissionError("Backend service lacks namespace creation permission")
    else:
        logger.error(f"Failed to create namespace: {e}")
        raise
```

### 2. Knative Service 배포 실패

**시나리오:**
- 잘못된 이미지 이름
- PVC 마운트 실패
- ResourceQuota 초과

**처리 전략:**
```python
try:
    knative_service = deploy_knative_service(...)
except ApiException as e:
    if "exceeded quota" in str(e):
        raise ResourceQuotaExceededError(
            f"Function exceeds resource limits. "
            f"Please check your workspace quota."
        )
    else:
        logger.error(f"Failed to deploy Knative Service: {e}")
        # 롤백: Namespace 삭제
        cleanup_namespace(namespace)
        raise
```

### 3. Ingress Rule 생성 실패

**시나리오:**
- 도메인 충돌
- TLS 인증서 발급 실패
- Kourier 설정 오류

**처리 전략:**
```python
try:
    public_url = ingress_mapper.create_function_ingress(...)
except ApiException as e:
    logger.error(f"Failed to create Ingress Rule: {e}")
    # Knative Service는 유지 (내부 URL로 접근 가능)
    # 사용자에게 내부 URL 제공
    internal_url = f"http://{function_name}.{namespace}.svc.cluster.local"
    return {
        "public_url": None,
        "internal_url": internal_url,
        "error": "Failed to create public URL. Using internal URL."
    }
```


## 테스트 전략

### 1. 단위 테스트

**도구:** pytest

**테스트 대상:**
- TenantService 메서드
- IngressMapper 메서드
- Function ID 생성 로직
- Namespace 이름 생성 로직

**예시:**
```python
def test_generate_function_id():
    """Function ID가 32자 문자열인지 확인"""
    function_id = generate_function_id()
    assert len(function_id) == 32
    assert function_id.isalnum()

def test_generate_namespace_name():
    """Namespace 이름이 K8s 규칙을 준수하는지 확인"""
    namespace = generate_namespace_name("my-workspace", "a" * 32)
    assert len(namespace) <= 63
    assert re.match(r'^[a-z0-9]([-a-z0-9]*[a-z0-9])?$', namespace)
```

### 2. 속성 기반 테스트

**도구:** Hypothesis

**테스트 설정:**
- 각 속성 테스트는 최소 100회 반복 실행
- 랜덤 입력 생성으로 edge case 발견

**예시:**
```python
from hypothesis import given, strategies as st

# Feature: knative-multitenancy, Property 2: Namespace 네이밍 규칙
@given(
    workspace=st.text(min_size=1, max_size=20, alphabet=st.characters(
        whitelist_categories=('Ll', 'Nd'), whitelist_characters='-'
    )),
    function_id=st.text(min_size=32, max_size=32, alphabet='0123456789abcdef')
)
@settings(max_examples=100)
def test_namespace_naming_rule(workspace, function_id):
    """모든 Namespace 이름이 {workspace}-{function_id} 형식을 따르는지 확인"""
    namespace = generate_namespace_name(workspace, function_id)
    
    # 형식 검증
    assert namespace == f"{workspace}-{function_id}"
    
    # K8s 네이밍 규칙 검증
    assert len(namespace) <= 63
    assert re.match(r'^[a-z0-9]([-a-z0-9]*[a-z0-9])?$', namespace)

# Feature: knative-multitenancy, Property 12: Function ID 길이 일관성
@given(st.integers(min_value=0, max_value=1000))
@settings(max_examples=100)
def test_function_id_length_consistency(seed):
    """모든 Function ID가 32자인지 확인"""
    random.seed(seed)
    function_id = generate_function_id()
    
    assert len(function_id) == 32
    assert function_id.isalnum()
    assert '-' not in function_id
```


### 3. 통합 테스트

**테스트 시나리오:**

```python
def test_function_lifecycle():
    """함수 전체 생명주기 테스트"""
    # 1. Workspace 생성
    workspace = create_workspace("test-workspace")
    
    # 2. 함수 생성
    function = create_function(
        workspace_id=workspace.id,
        name="hello-world",
        runtime="python3.9",
        code="def handler(event): return 'Hello!'"
    )
    
    # 3. Namespace 확인
    namespace = f"{workspace.id}-{function.id.replace('-', '')}"
    assert namespace_exists(namespace)
    
    # 4. ResourceQuota 확인
    quota = get_resource_quota(namespace)
    assert quota is not None
    
    # 5. Knative Service 확인
    ksvc = get_knative_service(function.name, namespace)
    assert ksvc.spec.template.spec.containers[0].ports[0].containerPort == 8080
    
    # 6. Ingress Rule 확인
    ingress = get_ingress(f"{function.name}-ingress", namespace)
    assert ingress is not None
    
    # 7. 공개 URL 확인
    assert function.public_url == f"https://{workspace.id}.runna.haifu.cloud/{function.name}"
    
    # 8. 함수 삭제
    delete_function(function.id)
    
    # 9. 리소스 정리 확인
    assert not namespace_exists(namespace)
    assert not knative_service_exists(function.name, namespace)
    assert not ingress_exists(f"{function.name}-ingress", namespace)
```

### 4. 로컬 테스트

**환경 설정:**
```bash
# kubeconfig 설정
export KUBECONFIG=~/.kube/config

# 테스트 실행
pytest tests/ -v

# 속성 테스트만 실행
pytest tests/ -k "property" -v

# 통합 테스트 실행
pytest tests/integration/ -v
```

**정리 스크립트:**
```bash
# 테스트 리소스 정리
kubectl delete namespace -l managed-by=runna-platform,test=true
```


## 보안 고려사항

### 1. Backend ServiceAccount RBAC

**ClusterRole 정의:**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: backend-service-role
rules:
  # Namespace 관리
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["create", "get", "list", "delete"]
  
  # ResourceQuota 관리
  - apiGroups: [""]
    resources: ["resourcequotas"]
    verbs: ["create", "get", "list", "delete"]
  
  # NetworkPolicy 관리
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies"]
    verbs: ["create", "get", "list", "delete"]
  
  # Knative Service 관리
  - apiGroups: ["serving.knative.dev"]
    resources: ["services"]
    verbs: ["create", "get", "list", "delete", "update"]
  
  # Ingress 관리
  - apiGroups: ["networking.k8s.io"]
    resources: ["ingresses"]
    verbs: ["create", "get", "list", "delete"]
  
  # PVC 관리
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["create", "get", "list", "delete"]
```

### 2. 함수 Pod 보안

**Pod Security Standards:**
- Namespace에 `pod-security.kubernetes.io/enforce: restricted` 레이블 적용
- 함수 Pod는 K8s API 접근 불가
- 읽기 전용 파일시스템 (PVC 제외)
- Non-root 사용자로 실행

### 3. 네트워크 보안

**NetworkPolicy 격리:**
- 함수 간 직접 통신 차단
- Kourier를 통한 트래픽만 허용
- Redis Queue 접근만 허용
- 외부 인터넷 접근 제한 (필요시)


## 운영 가이드

### 1. 함수 배포 플로우

```
POST /api/functions
{
  "workspace_id": "my-workspace",
  "name": "hello-world",
  "runtime": "python3.9",
  "code": "def handler(event): return 'Hello!'"
}

↓

1. Workspace 검증
2. Function ID 생성 (UUID v4, 하이픈 제거)
3. Namespace 생성 ({workspace}-{function_id})
4. ResourceQuota 적용
5. NetworkPolicy 적용
6. PVC에 코드 저장
7. Knative Service 배포
8. Ingress Rule 생성
9. DB에 함수 정보 저장

↓

Response:
{
  "id": "a1b2c3d4e5f6...",
  "name": "hello-world",
  "namespace": "my-workspace-a1b2c3d4e5f6...",
  "public_url": "https://my-workspace.runna.haifu.cloud/hello-world",
  "status": "ready"
}
```

### 2. 리소스 모니터링

```bash
# Namespace 목록 조회
kubectl get namespaces -l managed-by=runna-platform

# 특정 Workspace의 함수 조회
kubectl get namespaces -l workspace=my-workspace

# Knative Service 상태 확인
kubectl get ksvc -A -l managed-by=runna-platform

# ResourceQuota 사용량 확인
kubectl get resourcequota -A
```

### 3. 트러블슈팅

**함수 배포 실패:**
```bash
# Knative Service 이벤트 확인
kubectl describe ksvc <function-name> -n <namespace>

# Pod 로그 확인
kubectl logs -l serving.knative.dev/service=<function-name> -n <namespace>

# PVC 마운트 확인
kubectl describe pod <pod-name> -n <namespace>
```

**네트워크 접근 불가:**
```bash
# NetworkPolicy 확인
kubectl get networkpolicy -n <namespace>

# Ingress 상태 확인
kubectl describe ingress <function-name>-ingress -n <namespace>

# Kourier Gateway 로그
kubectl logs -n knative-serving -l app=3scale-kourier-gateway
```

### 4. 정리 작업

```bash
# 특정 Workspace의 모든 함수 삭제
kubectl delete namespaces -l workspace=<workspace-id>

# 테스트 리소스 정리
kubectl delete namespaces -l managed-by=runna-platform,test=true

# 오래된 함수 정리 (30일 이상)
kubectl get namespaces -l managed-by=runna-platform \
  --sort-by=.metadata.creationTimestamp | \
  head -n -30 | \
  xargs kubectl delete namespace
```

