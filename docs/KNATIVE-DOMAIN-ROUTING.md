# Knative Domain Routing & DomainMapping 설정 가이드

## 개요

Knative Serving에서 커스텀 도메인 매핑을 통해 `{workspace}.haifu.cloud/{function}` 형태의 라우팅을 구현합니다.

**참고 문서:** https://knative.dev/blog/releases/announcing-knative-v0-22-release/#managing-custom-domain-mappings

## 목표

기존: `https://helloworld-go.default.haifu.cloud/`  
변경: `https://demo-workspace.haifu.cloud/func1`

## 현재 환경

### Knative Serving 버전 확인

```bash
kubectl get deployment -n knative-serving -o=jsonpath='{range .items[*]}{.metadata.name}{" : "}{.metadata.labels.app\.kubernetes\.io/version}{"\n"}{end}'
```

**현재 버전:**
- 3scale-kourier-gateway: 1.20.0
- activator: 1.20.0
- autoscaler: 1.20.0
- controller: 1.20.0
- net-kourier-controller: 1.20.0
- webhook: 1.20.0

## 아키텍처

```
Internet
   ↓
ALB (demo-workspace.haifu.cloud)
   ↓
NodePort 30080/30443
   ↓
Kourier Gateway
   ↓
Knative Service (helloworld-go)
   ↳ 경로 /func1 → 내부 /
```

## 1. ClusterDomainClaim 생성

### 개념

**ClusterDomainClaim**: 특정 네임스페이스가 어떤 도메인을 사용할 권한이 있는지 선언

⚠️ **중요**: 각 서브도메인마다 ClusterDomainClaim이 필요합니다!

### YAML 템플릿

```yaml
apiVersion: networking.internal.knative.dev/v1alpha1
kind: ClusterDomainClaim
metadata:
  # 사용하려는 서브도메인
  name: {workspace-name}.haifu.cloud
spec:
  # 이 도메인을 사용하려는 네임스페이스
  namespace: {workspace-name}-{function_id}
```

### 예시: demo-workspace 도메인 클레임

```yaml
# cluster-domain-claim-demo.yaml
apiVersion: networking.internal.knative.dev/v1alpha1
kind: ClusterDomainClaim
metadata:
  name: demo-workspace.haifu.cloud
spec:
  namespace: default
```

```bash
kubectl apply -f cluster-domain-claim-demo.yaml
```

### 자동 생성 옵션

`config-network` ConfigMap에서 자동 생성 활성화:

```bash
kubectl edit configmap config-network -n knative-serving
```

다음 설정 추가:
```yaml
data:
  autocreate-cluster-domain-claims: "true"
```

## 2. DomainMapping 생성

### 개념

**DomainMapping**: 커스텀 도메인을 Knative Service에 매핑

⚠️ **주의**: ClusterDomainClaim이 먼저 생성되어 있어야 합니다!

### YAML 템플릿

```yaml
apiVersion: serving.knative.dev/v1beta1
kind: DomainMapping
metadata:
  # 실제 도메인 이름
  name: {workspace-name}.haifu.cloud
  namespace: {workspace-name}-{function_id}
spec:
  ref:
    apiVersion: serving.knative.dev/v1
    kind: Service
    name: {function-service-name}
  # HTTPS 사용 시
  tls:
    secretName: {workspace-name}-tls-secret
```

### 예시: helloworld-go 서비스 매핑

```yaml
# domainmapping-demo-func1.yaml
apiVersion: serving.knative.dev/v1beta1
kind: DomainMapping
metadata:
  name: demo-workspace.haifu.cloud
  namespace: default
spec:
  ref:
    apiVersion: serving.knative.dev/v1
    kind: Service
    name: helloworld-go
```

```bash
kubectl apply -f domainmapping-demo-func1.yaml
```

### 확인

```bash
# DomainMapping 상태 확인
kubectl get domainmapping -n default

# 상세 정보
kubectl describe domainmapping demo-workspace.haifu.cloud -n default
```

## 3. HTTPRoute 설정 (Path 기반 라우팅)

### 개념

Gateway API의 HTTPRoute를 사용하여 Path 기반 라우팅 구현:
- `/func1` → `helloworld-go.default.svc.cluster.local`

### 사전 요구사항

Gateway API CRDs 설치:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
```

### YAML 템플릿

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: {workspace-name}-{function-id}-path
  namespace: {namespace}
spec:
  parentRefs:
    - name: kourier
      namespace: knative-serving
  hostnames:
    - {workspace-name}.haifu.cloud
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /{endpoint}
      backendRefs:
        - name: {function-service-name}
          port: 80
```

### 예시: /func1 경로 라우팅

```yaml
# httproute-demo-func1.yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: demo-func1-path
  namespace: default
spec:
  parentRefs:
    - name: kourier
      namespace: knative-serving
  hostnames:
    - demo-workspace.haifu.cloud
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /func1
      backendRefs:
        - name: helloworld-go
          port: 80
```

```bash
kubectl apply -f httproute-demo-func1.yaml
```

## 4. 라우팅 전략

### 서브도메인 기반 (DomainMapping)

- **장점**: Knative 네이티브, 자동 TLS
- **단점**: 서브도메인마다 DNS 설정 필요
- **사용 케이스**: `{workspace}.haifu.cloud` → 특정 서비스

### Path 기반 (HTTPRoute)

- **장점**: 하나의 도메인으로 여러 함수 라우팅
- **단점**: Gateway API 설정 필요
- **사용 케이스**: `{workspace}.haifu.cloud/{function}` → 여러 함수

### 권장 조합

1. **ClusterDomainClaim**: 워크스페이스당 1개
2. **DomainMapping**: 워크스페이스 기본 도메인
3. **HTTPRoute**: 함수별 Path 라우팅

## 5. Backend 자동화 구현

### 함수 생성 API 요청 예시

```json
{
  "workspace_id": "demo-workspace",
  "function_id": "func1",
  "runtime_image": "gcr.io/knative-samples/helloworld-go",
  "route": "/func1"
}
```

### 자동화 흐름

#### Step 1: Knative Service 생성

```python
# backend-repo/app/services/function_service.py

def create_knative_service(workspace_id: str, function_id: str, image: str):
    service_yaml = f"""
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: {workspace_id}-{function_id}
  namespace: {workspace_id}
spec:
  template:
    spec:
      containers:
        - image: {image}
"""
    # Kubernetes API로 생성
    k8s_client.create_namespaced_custom_object(...)
```

#### Step 2: ClusterDomainClaim 생성 (워크스페이스당 1회)

```python
def ensure_cluster_domain_claim(workspace_id: str):
    claim_yaml = f"""
apiVersion: networking.internal.knative.dev/v1alpha1
kind: ClusterDomainClaim
metadata:
  name: {workspace_id}.haifu.cloud
spec:
  namespace: {workspace_id}
"""
    # 이미 존재하는지 확인 후 생성
    try:
        k8s_client.get_cluster_custom_object(...)
    except ApiException as e:
        if e.status == 404:
            k8s_client.create_cluster_custom_object(...)
```

#### Step 3: DomainMapping 생성

```python
def create_domain_mapping(workspace_id: str, function_id: str):
    mapping_yaml = f"""
apiVersion: serving.knative.dev/v1beta1
kind: DomainMapping
metadata:
  name: {workspace_id}.haifu.cloud
  namespace: {workspace_id}
spec:
  ref:
    apiVersion: serving.knative.dev/v1
    kind: Service
    name: {workspace_id}-{function_id}
"""
    k8s_client.create_namespaced_custom_object(...)
```

#### Step 4: HTTPRoute 생성 (Path 라우팅)

```python
def create_http_route(workspace_id: str, function_id: str, path: str):
    route_yaml = f"""
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: {workspace_id}-{function_id}-route
  namespace: {workspace_id}
spec:
  parentRefs:
    - name: kourier
      namespace: knative-serving
  hostnames:
    - {workspace_id}.haifu.cloud
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: {path}
      backendRefs:
        - name: {workspace_id}-{function_id}
          port: 80
"""
    k8s_client.create_namespaced_custom_object(...)
```

## 6. 트러블슈팅

### ClusterDomainClaim 관련

**에러**: `error: resource mapping not found`

**원인**: ClusterDomainClaim CRD가 없거나 권한 부족

**해결**:
```bash
# CRD 확인
kubectl get crd clusterdomainclaims.networking.internal.knative.dev

# 권한 확인
kubectl auth can-i create clusterdomainclaims --all-namespaces
```

### DomainMapping 관련

**에러**: `DomainMapping creation failed`

**원인**: ClusterDomainClaim이 먼저 생성되지 않음

**해결**:
```bash
# ClusterDomainClaim 먼저 생성
kubectl apply -f cluster-domain-claim.yaml

# 그 다음 DomainMapping 생성
kubectl apply -f domainmapping.yaml
```

### HTTPRoute 관련

**에러**: `no matches for kind "HTTPRoute"`

**원인**: Gateway API CRDs 미설치

**해결**:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
```

## 7. 검증

### 도메인 매핑 확인

```bash
# ClusterDomainClaim 확인
kubectl get clusterdomainclaims

# DomainMapping 확인
kubectl get domainmapping -A

# HTTPRoute 확인
kubectl get httproute -A
```

### 실제 접근 테스트

```bash
# 서브도메인 접근
curl https://demo-workspace.haifu.cloud

# Path 기반 접근
curl https://demo-workspace.haifu.cloud/func1
```

## 8. 다음 단계

1. Backend API에 자동화 로직 구현
2. 워크스페이스 생성 시 ClusterDomainClaim 자동 생성
3. 함수 생성 시 DomainMapping + HTTPRoute 자동 생성
4. TLS 인증서 자동 발급 (cert-manager 연동)
5. DNS 자동 설정 (Route53 연동)

## 참고 자료

- [Knative DomainMapping 공식 문서](https://knative.dev/docs/serving/services/custom-domains/)
- [Gateway API 문서](https://gateway-api.sigs.k8s.io/)
- [Kourier Gateway 설정](https://github.com/knative-extensions/net-kourier)
