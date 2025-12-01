# 요구사항 문서

## 소개

본 시스템은 서버리스 플랫폼의 CI/CD 및 GitOps 파이프라인입니다. GitHub Actions를 통한 자동 빌드, ArgoCD를 통한 GitOps 배포, Argo Rollouts를 통한 점진적 배포를 담당합니다.

**내 역할 범위:**
- ✅ GitHub Actions CI 파이프라인
- ✅ Docker 이미지 빌드 및 ECR 푸시
- ✅ Helm 차트 작성 및 관리
- ✅ ArgoCD GitOps 설정
- ✅ Argo Rollouts 배포 전략
- ✅ 환경별 배포 설정 (dev/staging/prod)

**범위 밖 (다른 팀원 담당):**
- ❌ Frontend/Backend/Worker 애플리케이션 로직
- ❌ Prometheus/Grafana 메트릭 정의 및 대시보드 (모니터링 담당)
- ❌ Redis Queue 구조 (Backend 팀)
- ❌ 함수 실행 엔진 (Worker 팀)

## 용어 사전

- **System**: CI/CD 및 GitOps 파이프라인 시스템
- **GitHub Actions**: CI 파이프라인을 실행하는 자동화 도구
- **Docker Image**: 빌드된 컨테이너 이미지
- **ECR**: Amazon Elastic Container Registry, 도커 이미지 저장소
- **Helm Chart**: 쿠버네티스 애플리케이션 패키징 도구
- **ArgoCD**: GitOps 기반 지속적 배포 도구
- **Argo Rollouts**: 점진적 배포(Canary/Blue-Green)를 지원하는 쿠버네티스 컨트롤러
- **Canary Deployment**: 일부 트래픽만 새 버전으로 라우팅하여 점진적으로 배포하는 전략
- **Blue-Green Deployment**: 새 버전을 완전히 준비한 후 트래픽을 전환하는 배포 전략
- **Platform Services**: Frontend, Backend, Worker 서비스
- **User Function**: 사용자가 작성한 함수 (Backend 팀이 관리)

## 요구사항

### 요구사항 1: CI 파이프라인 자동화

**사용자 스토리:** 개발자로서, 코드 변경사항이 자동으로 빌드되기를 원합니다. 그래야 수동 빌드 작업 없이 빠르게 반복 개발할 수 있습니다.

#### 인수 기준

1. WHEN 개발자가 GitHub 저장소의 main 브랜치에 코드를 푸시하면 THEN THE System SHALL GitHub Actions 워크플로우를 자동으로 트리거한다
2. WHEN GitHub Actions 워크플로우가 실행되면 THEN THE System SHALL Frontend, Backend, Worker 서비스 각각에 대해 Docker 이미지를 빌드한다
3. WHEN Docker 이미지 빌드가 완료되면 THEN THE System SHALL 빌드된 이미지를 ECR에 푸시하고 고유한 태그를 부여한다
4. WHEN 이미지가 ECR에 푸시되면 THEN THE System SHALL 해당 서비스의 Helm values 파일에서 이미지 태그를 자동으로 업데이트한다
5. WHEN Helm values 파일이 업데이트되면 THEN THE System SHALL 변경사항을 Git 저장소에 커밋하고 푸시한다

### 요구사항 2: GitOps 배포 자동화

**사용자 스토리:** 운영자로서, GitOps 방식으로 배포가 관리되기를 원합니다. 그래야 배포 상태를 Git을 통해 추적하고 감사할 수 있습니다.

#### 인수 기준

1. WHEN Git 저장소의 Helm values 파일이 변경되면 THEN THE System SHALL ArgoCD가 변경사항을 감지한다
2. WHEN ArgoCD가 변경사항을 감지하면 THEN THE System SHALL 자동으로 쿠버네티스 클러스터에 동기화를 수행한다
3. WHEN 동기화가 수행되면 THEN THE System SHALL 새로운 이미지 태그로 파드를 업데이트한다
4. WHEN Git 저장소의 상태와 클러스터 상태가 불일치하면 THEN THE System SHALL ArgoCD가 자동으로 재동기화를 시도한다
5. WHEN 배포가 완료되면 THEN THE System SHALL ArgoCD에 Synced 상태를 기록한다

### 요구사항 3: 점진적 배포 전략

**사용자 스토리:** 운영자로서, 새 버전 배포 시 점진적 배포 전략을 사용하고 싶습니다. 그래야 프로덕션 환경에서 안전하게 배포할 수 있습니다.

#### 인수 기준

1. WHEN 새 버전의 이미지가 배포되면 THEN THE System SHALL Argo Rollouts를 사용하여 Canary 배포를 시작한다
2. WHEN Canary 배포가 시작되면 THEN THE System SHALL 초기에는 전체 트래픽의 20%만 새 버전으로 라우팅한다
3. WHEN Canary 단계가 진행되면 THEN THE System SHALL 트래픽 비율을 20%, 50%, 80%, 100%로 점진적으로 증가시킨다
4. WHEN 각 Canary 단계에서 일정 시간이 경과하면 THEN THE System SHALL 다음 단계로 자동 진행한다
5. WHERE Blue-Green 배포 옵션이 선택되면 THEN THE System SHALL 새 버전을 완전히 준비한 후 트래픽을 한 번에 전환한다

### 요구사항 4: Helm 차트 관리

**사용자 스토리:** 개발자로서, 표준화된 Helm 차트가 제공되기를 원합니다. 그래야 모든 서비스를 일관된 방식으로 배포할 수 있습니다.

#### 인수 기준

1. WHEN 플랫폼 서비스(Frontend/Backend/Worker)를 배포하면 THEN THE System SHALL 공통 Helm 차트 템플릿을 사용한다
2. WHEN Helm 차트가 적용되면 THEN THE System SHALL 쿠버네티스 Deployment, Service, Ingress 리소스를 자동으로 생성한다
3. WHEN 사용자 함수를 배포하면 THEN THE System SHALL 함수 전용 Helm 차트 템플릿을 사용한다
4. WHEN Helm values가 변경되면 THEN THE System SHALL 변경된 리소스만 업데이트한다
5. WHEN Helm 차트를 삭제하면 THEN THE System SHALL 관련된 모든 쿠버네티스 리소스를 정리한다

### 요구사항 5: 환경별 배포 설정

**사용자 스토리:** 개발자로서, 여러 환경(dev, staging, production)에 대해 독립적으로 배포하고 싶습니다. 그래야 환경별로 다른 설정을 적용할 수 있습니다.

#### 인수 기준

1. WHERE 환경이 dev, staging, production 중 하나로 지정되면 THEN THE System SHALL 해당 환경의 Helm values 파일을 사용한다
2. WHEN dev 환경에 배포하면 THEN THE System SHALL ArgoCD 자동 동기화를 즉시 수행한다
3. WHEN staging 환경에 배포하면 THEN THE System SHALL Canary 배포 전략을 적용한다
4. WHEN production 환경에 배포하면 THEN THE System SHALL Blue-Green 배포 전략을 적용한다
5. WHEN 환경별 설정이 변경되면 THEN THE System SHALL 해당 환경에만 변경사항을 적용한다

### 요구사항 6: CI 빌드 피드백

**사용자 스토리:** 개발자로서, CI 파이프라인에서 빌드 실패 시 명확한 피드백을 받고 싶습니다. 그래야 문제를 빠르게 수정할 수 있습니다.

#### 인수 기준

1. WHEN Docker 이미지 빌드가 실패하면 THEN THE System SHALL GitHub Actions 로그에 상세한 에러 메시지를 출력한다
2. WHEN 빌드가 실패하면 THEN THE System SHALL GitHub PR 또는 커밋에 실패 상태를 표시한다
3. WHEN ECR 푸시가 실패하면 THEN THE System SHALL 인증 또는 네트워크 에러 정보를 로그에 기록한다
4. WHEN Helm values 업데이트가 실패하면 THEN THE System SHALL Git 커밋 에러를 로그에 기록한다
5. WHEN 빌드가 성공하면 THEN THE System SHALL 빌드된 이미지 태그와 ECR URL을 로그에 출력한다

### 요구사항 7: 로컬 테스트 지원

**사용자 스토리:** 개발자로서, 로컬 환경에서 CI/CD 파이프라인을 테스트하고 싶습니다. 그래야 프로덕션에 배포하기 전에 검증할 수 있습니다.

#### 인수 기준

1. WHEN 개발자가 로컬에서 Docker 빌드를 실행하면 THEN THE System SHALL GitHub Actions와 동일한 Dockerfile을 사용한다
2. WHEN 로컬에서 Helm 차트를 검증하면 THEN THE System SHALL helm lint 명령으로 문법 오류를 확인한다
3. WHEN 로컬에서 Helm 차트를 렌더링하면 THEN THE System SHALL 생성될 쿠버네티스 매니페스트를 출력한다
4. WHEN 로컬에서 ArgoCD 동기화를 시뮬레이션하면 THEN THE System SHALL dry-run 모드로 변경사항을 미리 확인한다
5. WHEN 로컬 테스트가 성공하면 THEN THE System SHALL 프로덕션 파이프라인과 동일한 결과를 보장한다

### 요구사항 8: 이미지 태그 관리

**사용자 스토리:** 운영자로서, 이미지 태그가 명확하게 관리되기를 원합니다. 그래야 어떤 버전이 배포되었는지 추적할 수 있습니다.

#### 인수 기준

1. WHEN 이미지를 빌드하면 THEN THE System SHALL Git 커밋 해시를 포함한 고유한 태그를 생성한다
2. WHEN 동일한 커밋에 대해 재빌드하면 THEN THE System SHALL 동일한 태그를 생성한다
3. WHEN 이미지 태그가 생성되면 THEN THE System SHALL 태그 형식이 일관되게 유지된다
4. WHEN 여러 서비스를 동시에 빌드하면 THEN THE System SHALL 각 서비스별로 독립적인 태그를 생성한다
5. WHEN 이미지 태그를 조회하면 THEN THE System SHALL 빌드 시간과 커밋 정보를 포함한다
