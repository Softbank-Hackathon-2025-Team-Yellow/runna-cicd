# Knative Multitenancy Policy Templates

이 디렉토리는 함수별 Namespace 격리를 위한 정책 템플릿을 포함합니다.

## 개요

**격리 모델:** 1 function = 1 namespace

각 함수는 고유한 Namespace에서 실행되며, ResourceQuota와 NetworkPolicy를 통해 격리됩니다.

## 템플릿 파일

### 1. resource-quota-template.yaml

함수별 리소스 사용량 제한을 정의합니다.

**제한 사항:**
- CPU: 최대 1 코어
- 메모리: 최대 512Mi
- Pod: 최대 10개 (Knative 자동 스케일링)
- PVC: 1개
- Storage: 최대 1Gi

**적용 방법:**
```python
from kubernetes import client
import yaml

# 템플릿 로드
with open("k8s/policies/resource-quota-template.yaml") as f:
    quota_template = yaml.safe_load_all(f)
    
# Namespace에 적용
for resource in quota_template:
    if resource['kind'] == 'ResourceQuota':
        resource['metadata']['namespace'] = f"{workspace}-{function_id}"
        core_v1.create_namespaced_resource_quota(
            namespace=resource['metadata']['namespace'],
            body=resource
        )
    elif resource['kind'] == 'LimitRange':
        resource['metadata']['namespace'] = f"{workspace}-{function_id}"
        core_v1.create_namespaced_limit_range(
            namespace=resource['metadata']['namespace'],
            body=resource
        )
```

### 2. network-policy-template.yaml

함수 간 네트워크 격리를 정의합니다.

**허용되는 트래픽:**

**Ingress (들어오는 트래픽):**
- 같은 Namespace 내 Pod 간 통신
- Knative Kourier Ingress (포트 8080)
- Knative Serving 시스템 컴포넌트

**Egress (나가는 트래픽):**
- 같은 Namespace 내 Pod 간 통신
- DNS 조회 (kube-system)
- Redis Queue (default namespace, 포트 6379)
- Knative Serving 시스템
- 외부 인터넷 (HTTPS/HTTP)

**차단되는 트래픽:**
- 다른 함수 Namespace로의 직접 접근

**적용 방법:**
```python
from kubernetes import client
import yaml

# 템플릿 로드
with open("k8s/policies/network-policy-template.yaml") as f:
    policy_template = yaml.safe_load_all(f)
    
# Namespace에 적용
networking_v1 = client.NetworkingV1Api()
for policy in policy_template:
    policy['metadata']['namespace'] = f"{workspace}-{function_id}"
    networking_v1.create_namespaced_network_policy(
        namespace=policy['metadata']['namespace'],
        body=policy
    )
```

## Namespace 네이밍 규칙

**형식:** `{workspace}-{function_id}`

**예시:**
- Workspace: `my-workspace`
- Function ID: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6` (UUID v4, 하이픈 제거)
- Namespace: `my-workspace-a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

**제약 사항:**
- 최대 길이: 63자 (Kubernetes 제한)
- 허용 문자: 소문자, 숫자, 하이픈
- 시작/끝: 영숫자

## 요구사항 매핑

이 템플릿들은 다음 요구사항을 충족합니다:

- **요구사항 2.2:** ResourceQuota CPU 제한 적용
- **요구사항 2.3:** ResourceQuota 메모리 제한 적용
- **요구사항 2.4:** ResourceQuota Pod 개수 제한 적용
- **요구사항 3.1:** NetworkPolicy 자동 생성

## 참고

- 템플릿은 `TenantService` 클래스에서 자동으로 로드되어 적용됩니다.
- 각 함수 생성 시 자동으로 해당 Namespace에 정책이 적용됩니다.
- 정책 수정 시 기존 함수에는 영향을 주지 않으며, 새로 생성되는 함수부터 적용됩니다.
