# 요구사항 문서

## 소개

본 시스템은 K3s + Knative + Kourier 기반의 멀티테넌트 서버리스 플랫폼입니다. 함수별로 격리된 Namespace를 자동 생성하고, Knative Service를 통해 함수를 배포하며, 사용자 친화적인 URL로 라우팅합니다.

**핵심 기능:**
- ✅ 함수별 Namespace 자동 생성 및 격리 (1 function = 1 namespace)
- ✅ Knative Service 기반 함수 배포
- ✅ Workspace 기반 URL 라우팅 (https://{workspace}.runna.haifu.cloud/{function})
- ✅ PVC 기반 함수 코드 저장 (공유 PVC 또는 함수별 PVC)
- ✅ ResourceQuota를 통한 리소스 제한
- ✅ NetworkPolicy를 통한 네트워크 격리

**인프라 환경:**
- 클러스터: K3s
- Ingress: Kourier (Knative 기본)
- Redis Queue: queue-redis-master.default.svc.cluster.local
- 함수 포트: 8080 (Knative 표준)
- 노드: worker-run (2 vCPU, 4GB RAM)

## 용어 사전

- **System**: 멀티테넌트 서버리스 플랫폼 시스템
- **Workspace**: 사용자의 작업 공간 (1 workspace = N functions)
- **Function**: 사용자가 작성한 서버리스 함수
- **Function ID**: 함수의 고유 식별자
- **Namespace**: 쿠버네티스 리소스 격리 단위 (1 function = 1 namespace, 형식: {workspace}-{function_id})
- **Knative Service**: 서버리스 함수를 실행하는 쿠버네티스 리소스
- **Kourier**: Knative 기본 Ingress Controller
- **ResourceQuota**: Namespace별 리소스 사용량 제한
- **NetworkPolicy**: Pod 간 네트워크 트래픽 제어 정책
- **PVC**: Persistent Volume Claim, 함수 코드 저장용 스토리지
- **Generic Runner**: 사용자 함수를 실행하는 범용 컨테이너
- **Worker-run Node**: 함수 실행 전용 쿠버네티스 노드

## 요구사항

### 요구사항 1: Namespace 자동 생성

**사용자 스토리:** 사용자로서, 함수를 생성할 때 자동으로 전용 실행 환경이 준비되기를 원합니다. 그래야 다른 함수와 격리된 안전한 환경에서 함수를 실행할 수 있습니다.

#### 인수 기준

1. WHEN 사용자가 함수를 생성하면 THEN THE System SHALL 함수별 고유한 Namespace를 자동으로 생성한다
2. WHEN Namespace가 생성되면 THEN THE System SHALL Namespace 이름을 "{workspace}-{function_id}" 형식으로 지정한다
3. WHEN Namespace가 이미 존재하면 THEN THE System SHALL 기존 Namespace를 재사용하고 새로 생성하지 않는다
4. WHEN Namespace를 생성하면 THEN THE System SHALL workspace 및 function 식별을 위한 레이블을 추가한다
5. WHEN Namespace 생성이 실패하면 THEN THE System SHALL 상세한 에러 메시지를 로그에 기록하고 사용자에게 알린다

### 요구사항 2: 리소스 제한 설정

**사용자 스토리:** 운영자로서, 각 함수의 리소스 사용량을 제한하고 싶습니다. 그래야 한 함수가 전체 시스템 리소스를 독점하는 것을 방지할 수 있습니다.

#### 인수 기준

1. WHEN Namespace가 생성되면 THEN THE System SHALL ResourceQuota를 자동으로 생성한다
2. WHEN ResourceQuota를 설정하면 THEN THE System SHALL k8s/policies/resource-quota-template.yaml에 정의된 CPU 제한을 적용한다
3. WHEN ResourceQuota를 설정하면 THEN THE System SHALL k8s/policies/resource-quota-template.yaml에 정의된 메모리 제한을 적용한다
4. WHEN ResourceQuota를 설정하면 THEN THE System SHALL k8s/policies/resource-quota-template.yaml에 정의된 Pod 개수 제한을 적용한다
5. WHEN 함수가 리소스 제한을 초과하면 THEN THE System SHALL 새로운 리소스 생성을 거부하고 명확한 에러 메시지를 반환한다

### 요구사항 3: 네트워크 격리

**사용자 스토리:** 보안 담당자로서, 함수 간 네트워크 트래픽이 격리되기를 원합니다. 그래야 한 함수가 다른 함수에 무단으로 접근하는 것을 방지할 수 있습니다.

#### 인수 기준

1. WHEN Namespace가 생성되면 THEN THE System SHALL NetworkPolicy를 자동으로 생성한다
2. WHEN NetworkPolicy가 적용되면 THEN THE System SHALL 같은 Namespace 내의 Pod 간 통신을 허용한다
3. WHEN NetworkPolicy가 적용되면 THEN THE System SHALL Knative Ingress Class(kourier.ingress.networking.knative.dev) 기반 트래픽을 허용한다
4. WHEN NetworkPolicy가 적용되면 THEN THE System SHALL 필수 시스템 서비스 접근을 허용한다
5. WHEN NetworkPolicy가 적용되면 THEN THE System SHALL 다른 Namespace로의 직접 접근을 차단한다

### 요구사항 4: Knative Service 배포

**사용자 스토리:** 사용자로서, 작성한 함수가 자동으로 Knative Service로 배포되기를 원합니다. 그래야 서버리스 환경에서 함수를 실행할 수 있습니다.

#### 인수 기준

1. WHEN 사용자가 함수를 생성하면 THEN THE System SHALL 함수 전용 Namespace에 Knative Service를 생성한다
2. WHEN Knative Service를 생성하면 THEN THE System SHALL Generic Runner 이미지를 사용한다
3. WHEN Knative Service를 생성하면 THEN THE System SHALL 컨테이너 포트를 8080으로 설정한다
4. WHEN Knative Service를 생성하면 THEN THE System SHALL PVC를 마운트하여 함수 코드에 접근한다
5. WHEN Knative Service를 생성하면 THEN THE System SHALL worker-run 노드에 배포되도록 nodeSelector를 설정한다

### 요구사항 5: 함수 코드 저장

**사용자 스토리:** 사용자로서, 작성한 함수 코드가 안전하게 저장되기를 원합니다. 그래야 함수 실행 시 코드를 불러올 수 있습니다.

#### 인수 기준

1. WHEN 함수를 생성하면 THEN THE System SHALL PVC를 통해 함수 코드를 저장한다
2. WHERE 함수별 PVC 전략이 선택되면 THEN THE System SHALL 함수별 PVC를 생성한다
3. WHERE 공유 PVC 전략이 선택되면 THEN THE System SHALL 공유 PVC의 함수별 경로에 코드를 저장한다
4. WHEN 함수 코드를 저장하면 THEN THE System SHALL PVC에 코드 파일을 기록한다
5. WHEN Knative Service가 시작되면 THEN THE System SHALL PVC를 읽기 전용으로 마운트한다

### 요구사항 6: Ingress 기반 URL 라우팅

**사용자 스토리:** 사용자로서, 함수에 접근할 수 있는 친화적인 URL을 받고 싶습니다. 그래야 쉽게 함수를 호출할 수 있습니다.

#### 인수 기준

1. WHEN 함수가 배포되면 THEN THE System SHALL 사용자에게 공개 URL을 제공한다
2. WHEN URL을 생성하면 THEN THE System SHALL "https://{workspace}.runna.haifu.cloud/{function}" 형식을 사용한다
3. WHEN 라우팅 리소스를 생성하면 THEN THE System SHALL Ingress Rule을 생성하여 Knative Service와 연결한다
4. WHEN 함수가 삭제되면 THEN THE System SHALL 해당 Ingress Rule도 함께 삭제한다
5. WHEN 라우팅 설정이 실패하면 THEN THE System SHALL 에러를 로그에 기록하고 사용자에게 알린다

### 요구사항 7: 자동 스케일링

**사용자 스토리:** 운영자로서, 함수가 트래픽에 따라 자동으로 스케일링되기를 원합니다. 그래야 리소스를 효율적으로 사용할 수 있습니다.

#### 인수 기준

1. WHEN Knative Service를 생성하면 THEN THE System SHALL 자동 스케일링 설정을 적용한다
2. WHEN 트래픽이 증가하면 THEN THE System SHALL Pod를 자동으로 증가시킨다
3. WHEN 트래픽이 감소하면 THEN THE System SHALL Pod를 자동으로 감소시킨다
4. WHEN Knative Service를 생성하면 THEN THE System SHALL 정책 템플릿에 정의된 스케일링 범위를 적용한다
5. WHEN 스케일링이 발생하면 THEN THE System SHALL 스케일링 이벤트를 로그에 기록한다

### 요구사항 8: 내부 서비스 권한 관리

**사용자 스토리:** 보안 담당자로서, 플랫폼 내부 서비스가 필요한 권한만 가지기를 원합니다. 그래야 권한 분리를 통해 보안을 강화할 수 있습니다.

#### 인수 기준

1. WHEN Backend 서비스가 Namespace를 생성하면 THEN THE System SHALL Backend ServiceAccount가 Namespace 생성 권한을 가진다
2. WHEN Backend 서비스가 Knative Service를 배포하면 THEN THE System SHALL Backend ServiceAccount가 Knative Service 생성 권한을 가진다
3. WHEN Backend 서비스가 리소스를 조회하면 THEN THE System SHALL Backend ServiceAccount가 읽기 권한을 가진다
4. WHEN 함수 Pod가 실행되면 THEN THE System SHALL 함수 Pod는 K8s API 접근 권한을 가지지 않는다
5. WHEN RBAC를 설정하면 THEN THE System SHALL 최소 권한 원칙을 적용한다

### 요구사항 9: Redis Queue 연동

**사용자 스토리:** 개발자로서, 함수가 Redis Queue에 접근할 수 있기를 원합니다. 그래야 비동기 작업을 처리할 수 있습니다.

#### 인수 기준

1. WHEN Knative Service를 생성하면 THEN THE System SHALL REDIS_HOST 환경변수를 "queue-redis-master.default.svc.cluster.local"로 설정한다
2. WHEN Knative Service를 생성하면 THEN THE System SHALL REDIS_PORT 환경변수를 "6379"로 설정한다
3. WHEN 함수가 실행되면 THEN THE System SHALL Redis Queue에 접근할 수 있다
4. WHEN NetworkPolicy를 설정하면 THEN THE System SHALL default Namespace의 Redis 접근을 허용한다
5. WHEN Redis 연결이 실패하면 THEN THE System SHALL 에러를 로그에 기록하고 사용자에게 알린다

### 요구사항 10: 함수 생명주기 관리

**사용자 스토리:** 사용자로서, 함수를 생성, 조회, 삭제할 수 있기를 원합니다. 그래야 함수를 효과적으로 관리할 수 있습니다.

#### 인수 기준

1. WHEN 함수를 생성하면 THEN THE System SHALL 함수 정보를 데이터베이스에 저장한다
2. WHEN 함수를 조회하면 THEN THE System SHALL 사용자 본인의 함수만 반환한다
3. WHEN 함수를 삭제하면 THEN THE System SHALL Knative Service를 삭제한다
4. WHEN 함수를 삭제하면 THEN THE System SHALL 함수 코드 저장소(함수별 PVC 또는 공유 PVC 내 함수 디렉터리)를 정리한다
5. WHEN 함수를 삭제하면 THEN THE System SHALL 해당 라우팅 리소스(Ingress Rule 및 선택적으로 존재하는 DomainMapping)를 함께 삭제한다

### 요구사항 11: 에러 처리 및 로깅

**사용자 스토리:** 개발자로서, 시스템 오류 발생 시 명확한 에러 메시지를 받고 싶습니다. 그래야 문제를 빠르게 해결할 수 있습니다.

#### 인수 기준

1. WHEN Namespace 생성이 실패하면 THEN THE System SHALL 구조화된 에러 로그를 기록한다
2. WHEN Knative Service 배포가 실패하면 THEN THE System SHALL 실패 원인을 사용자에게 반환한다
3. WHEN PVC 생성이 실패하면 THEN THE System SHALL 스토리지 관련 에러 정보를 로그에 기록한다
4. WHEN Ingress Rule 생성이 실패하면 THEN THE System SHALL 라우팅 관련 에러를 로그에 기록한다
5. WHEN 모든 작업이 성공하면 THEN THE System SHALL 성공 로그와 함께 생성된 리소스 정보를 기록한다

### 요구사항 12: Workspace 관리

**사용자 스토리:** 사용자로서, Workspace를 생성하고 관리하고 싶습니다. 그래야 함수들을 논리적으로 그룹화할 수 있습니다.

#### 인수 기준

1. WHEN 사용자가 Workspace를 생성하면 THEN THE System SHALL 고유한 Workspace ID를 생성한다
2. WHEN Workspace ID를 생성하면 THEN THE System SHALL URL 안전한 문자열(소문자, 숫자, 하이픈)만 사용한다
3. WHEN Workspace를 생성하면 THEN THE System SHALL Workspace 정보를 데이터베이스에 저장한다
4. WHEN Workspace를 조회하면 THEN THE System SHALL 사용자 본인의 Workspace만 반환한다
5. WHEN Workspace를 삭제하면 THEN THE System SHALL 해당 Workspace의 모든 함수도 함께 삭제한다

### 요구사항 13: Function ID 생성 규칙

**사용자 스토리:** 개발자로서, 함수 ID가 일관된 규칙으로 생성되기를 원합니다. 그래야 시스템 전체에서 함수를 고유하게 식별할 수 있습니다.

#### 인수 기준

1. WHEN 함수를 생성하면 THEN THE System SHALL 고유한 Function ID를 자동으로 생성한다
2. WHEN Function ID를 생성하면 THEN THE System SHALL UUID v4 형식을 사용한다
3. WHEN Function ID를 생성하면 THEN THE System SHALL 하이픈을 제거한 32자 문자열로 변환한다
4. WHEN Function ID를 Namespace 이름에 사용하면 THEN THE System SHALL 쿠버네티스 네이밍 규칙을 준수한다
5. WHEN 동일한 함수 이름이 존재하면 THEN THE System SHALL Function ID로 고유성을 보장한다

### 요구사항 14: 함수 실행 로그 수집

**사용자 스토리:** 사용자로서, 함수 실행 로그를 조회하고 싶습니다. 그래야 함수 동작을 디버깅하고 모니터링할 수 있습니다.

#### 인수 기준

1. WHEN 함수가 실행되면 THEN THE System SHALL 표준 출력(stdout)을 로그로 수집한다
2. WHEN 함수가 에러를 발생시키면 THEN THE System SHALL 표준 에러(stderr)를 로그로 수집한다
3. WHEN 사용자가 로그를 조회하면 THEN THE System SHALL 최근 로그부터 시간 역순으로 반환한다
4. WHEN 로그를 조회하면 THEN THE System SHALL 타임스탬프와 로그 레벨을 포함한다
5. WHEN 로그 저장 공간이 부족하면 THEN THE System SHALL 오래된 로그부터 자동으로 삭제한다

### 요구사항 15: 리소스 사용량 모니터링

**사용자 스토리:** 운영자로서, 각 함수의 리소스 사용량을 모니터링하고 싶습니다. 그래야 리소스 최적화 및 비용 관리를 할 수 있습니다.

#### 인수 기준

1. WHEN 함수가 실행되면 THEN THE System SHALL CPU 사용량을 수집한다
2. WHEN 함수가 실행되면 THEN THE System SHALL 메모리 사용량을 수집한다
3. WHEN 함수가 실행되면 THEN THE System SHALL 네트워크 트래픽을 수집한다
4. WHEN 사용자가 메트릭을 조회하면 THEN THE System SHALL 시간대별 리소스 사용량을 반환한다
5. WHEN 함수가 리소스 제한에 근접하면 THEN THE System SHALL 사용자에게 경고를 발송한다

### 요구사항 16: 로컬 테스트 지원

**사용자 스토리:** 개발자로서, 로컬 환경에서 멀티테넌시 기능을 테스트하고 싶습니다. 그래야 프로덕션 배포 전에 검증할 수 있습니다.

#### 인수 기준

1. WHEN 로컬에서 테스트하면 THEN THE System SHALL kubeconfig를 통해 K8s 클러스터에 접근한다
2. WHEN 로컬에서 Namespace를 생성하면 THEN THE System SHALL 프로덕션과 동일한 리소스를 생성한다
3. WHEN 로컬에서 Knative Service를 배포하면 THEN THE System SHALL 실제 클러스터에 배포한다
4. WHEN 로컬 테스트가 완료되면 THEN THE System SHALL 생성된 리소스를 정리한다
5. WHEN 로컬 테스트가 성공하면 THEN THE System SHALL 프로덕션 환경과 동일한 결과를 보장한다

---

## 선택적 요구사항

### 요구사항 17: DomainMapping 기반 라우팅 (선택)

**사용자 스토리:** 운영자로서, Knative DomainMapping을 사용하여 라우팅을 관리하고 싶습니다. 그래야 Knative 네이티브 방식으로 도메인을 관리할 수 있습니다.

**참고:** 이 요구사항은 선택적이며, 팀 결정에 따라 Ingress Rule 기반 라우팅으로 대체될 수 있습니다.

#### 인수 기준

1. WHERE DomainMapping 전략이 선택되면 THEN THE System SHALL Knative DomainMapping 리소스를 생성한다
2. WHEN DomainMapping을 생성하면 THEN THE System SHALL Knative Service를 참조하도록 설정한다
3. WHEN DomainMapping을 생성하면 THEN THE System SHALL 커스텀 도메인을 설정한다
4. WHEN DomainMapping이 준비되면 THEN THE System SHALL 사용자에게 URL을 반환한다
5. WHEN 함수가 삭제되면 THEN THE System SHALL DomainMapping도 함께 삭제한다
6. WHEN DomainMapping 생성이 실패하면 THEN THE System SHALL DNS 또는 Kourier 관련 에러를 로그에 기록한다
