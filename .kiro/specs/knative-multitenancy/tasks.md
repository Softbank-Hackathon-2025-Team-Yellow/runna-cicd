# 구현 계획

## 개요

이 문서는 Knative 멀티테넌시 구현을 위한 작업 목록입니다. 함수별 Namespace 격리, Knative Service 배포, Ingress 기반 라우팅을 구현합니다.

## 작업 목록

- [x] 1. 프로젝트 구조 및 정책 템플릿 설정





  - k8s/policies/ 디렉토리 생성
  - resource-quota-template.yaml 작성
  - network-policy-template.yaml 작성
  - _요구사항: 2.2, 2.3, 2.4, 3.1_

- [x] 2. 데이터 모델 구현





  - Workspace 모델 작성 (id, user_id, name)
  - Function 모델 작성 (id, workspace_id, name, runtime, code, namespace, public_url, status)
  - 데이터베이스 마이그레이션 생성
  - _요구사항: 12.3, 10.1_

- [x] 2.1 Function ID 생성 로직 구현


  - generate_function_id() 함수 작성 (UUID v4, 하이픈 제거)
  - generate_namespace_name() 함수 작성 ({workspace}-{function_id})
  - K8s 네이밍 규칙 검증 로직 추가
  - _요구사항: 13.1, 13.2, 13.3, 13.4_

- [x] 2.2 속성 테스트: Function ID 길이 일관성
















  - **속성 12: Function ID 길이 일관성**
  - **검증: 요구사항 13.3**
  - 모든 Function ID가 32자인지 테스트
  - _요구사항: 13.3_

- [x] 2.3 속성 테스트: Namespace 네이밍 규칙







  - **속성 2: Namespace 네이밍 규칙**
  - **검증: 요구사항 1.2, 13.4**
  - 모든 Namespace 이름이 {workspace}-{function_id} 형식인지 테스트
  - _요구사항: 1.2, 13.4_

- [x] 3. TenantService 구현






  - TenantService 클래스 작성
  - ensure_namespace() 메서드 구현
  - _create_namespace() 메서드 구현
  - _create_resource_quota() 메서드 구현 (템플릿 기반)
  - _create_network_policy() 메서드 구현
  - _요구사항: 1.1, 1.2, 2.1, 3.1_

- [x] 3.1 속성 테스트: Namespace 자동 생성







  - **속성 1: Namespace 자동 생성**
  - **검증: 요구사항 1.1**
  - 모든 함수 생성 시 Namespace가 자동 생성되는지 테스트
  - _요구사항: 1.1_

- [ ] 3.2 속성 테스트: Namespace 생성 멱등성











  - **속성 3: Namespace 생성 멱등성**
  - **검증: 요구사항 1.3**
  - 동일 함수 여러 번 생성 시 Namespace는 한 번만 생성되는지 테스트
  - _요구사항: 1.3_

- [ ]* 3.3 속성 테스트: ResourceQuota 자동 생성
  - **속성 4: ResourceQuota 자동 생성**
  - **검증: 요구사항 2.1**
  - 모든 Namespace 생성 시 ResourceQuota가 함께 생성되는지 테스트
  - _요구사항: 2.1_

- [ ]* 3.4 속성 테스트: NetworkPolicy 자동 생성
  - **속성 5: NetworkPolicy 자동 생성**
  - **검증: 요구사항 3.1**
  - 모든 Namespace 생성 시 NetworkPolicy가 함께 생성되는지 테스트
  - _요구사항: 3.1_


- [x] 4. PVC 관리 구현








  - 공유 PVC 전략 구현 (save_code_to_shared_pvc)
  - 함수별 PVC 전략 구현 (create_function_pvc)
  - PVC 마운트 로직 구현
  - _요구사항: 5.1, 5.2, 5.3, 5.4_

- [ ]* 4.1 속성 테스트: PVC 읽기 전용 마운트
  - **속성 7: PVC 읽기 전용 마운트**
  - **검증: 요구사항 5.5**
  - 모든 Knative Service의 PVC가 readOnly=true인지 테스트
  - _요구사항: 5.5_

- [x] 5. Knative Service 배포 구현

  - deploy_knative_service() 함수 작성
  - Generic Runner 이미지 설정
  - 컨테이너 포트 8080 설정
  - PVC 마운트 설정
  - Redis 환경변수 설정
  - nodeSelector (role: run) 설정
  - _요구사항: 4.1, 4.2, 4.3, 4.4, 4.5, 9.1, 9.2_

- [ ]* 5.1 속성 테스트: Knative Service 포트 일관성
  - **속성 6: Knative Service 포트 일관성**
  - **검증: 요구사항 4.3**
  - 모든 Knative Service의 포트가 8080인지 테스트
  - _요구사항: 4.3_

- [x] 6. IngressMapper 구현






  - IngressMapper 클래스 작성
  - create_function_ingress() 메서드 구현
  - Ingress Rule 생성 로직 (Kourier 기반)
  - TLS 인증서 설정 (cert-manager)
  - delete_function_ingress() 메서드 구현
  - _요구사항: 6.1, 6.2, 6.3_

- [x] 6.1 속성 테스트: URL 형식 일관성







  - **속성 8: URL 형식 일관성**
  - **검증: 요구사항 6.2**
  - 모든 공개 URL이 https://{workspace}.runna.haifu.cloud/{function} 형식인지 테스트
  - _요구사항: 6.2_


- [x] 7. Backend API 통합




  - POST /api/functions 엔드포인트 수정
  - TenantService.ensure_namespace() 호출
  - PVC에 코드 저장
  - deploy_knative_service() 호출
  - IngressMapper.create_function_ingress() 호출
  - DB에 함수 정보 저장
  - _요구사항: 10.1_



- [ ] 8. 함수 삭제 로직 구현
  - DELETE /api/functions/{id} 엔드포인트 수정
  - Knative Service 삭제
  - PVC 정리 (전략에 따라)
  - Ingress Rule 삭제
  - Namespace 삭제
  - DB에서 함수 삭제
  - _요구사항: 10.3, 10.4, 10.5_

- [ ]* 8.1 속성 테스트: 함수 삭제 시 리소스 정리
  - **속성 9: 함수 삭제 시 리소스 정리**
  - **검증: 요구사항 10.3, 10.4, 10.5**
  - 함수 생성 후 삭제 시 모든 리소스가 정리되는지 테스트
  - _요구사항: 10.3, 10.4, 10.5_

- [ ] 9. 체크포인트 1 - 핵심 기능 완료
  - 모든 테스트가 통과하는지 확인
  - 사용자에게 질문이 있으면 문의
  - _작업 1-8 완료 후_


- [ ] 10. Workspace 관리 API 구현
  - POST /api/workspaces 엔드포인트 작성
  - GET /api/workspaces 엔드포인트 작성
  - DELETE /api/workspaces/{id} 엔드포인트 작성
  - Workspace ID 생성 로직 (URL-safe 문자)
  - _요구사항: 12.1, 12.2, 12.3, 12.4, 12.5_

- [ ]* 10.1 속성 테스트: Workspace ID 문자 집합
  - **속성 10: Workspace ID 문자 집합**
  - **검증: 요구사항 12.2**
  - 모든 Workspace ID가 URL-safe 문자만 포함하는지 테스트
  - _요구사항: 12.2_

- [ ] 11. 에러 처리 구현
  - Namespace 생성 실패 처리
  - Knative Service 배포 실패 처리 (롤백 포함)
  - Ingress Rule 생성 실패 처리
  - 구조화된 에러 로그 작성
  - 사용자 친화적 에러 메시지 반환
  - _요구사항: 11.1, 11.2, 11.3, 11.4, 11.5_


- [ ] 12. Backend ServiceAccount RBAC 설정
  - ClusterRole 작성 (Namespace, ResourceQuota, NetworkPolicy, Knative Service, Ingress 권한)
  - ClusterRoleBinding 작성
  - ServiceAccount 생성
  - _요구사항: 8.1, 8.2, 8.3, 8.5_

- [ ] 13. 통합 테스트
  - 함수 전체 생명주기 테스트 (생성 → 배포 → 삭제)
  - Workspace 생성 및 함수 그룹화 테스트
  - 리소스 제한 초과 테스트
  - 네트워크 격리 테스트
  - _요구사항: 모든 요구사항_

- [ ] 14. 체크포인트 2 - 전체 기능 완료
  - 모든 테스트가 통과하는지 확인
  - 사용자에게 질문이 있으면 문의
  - _작업 10-13 완료 후_


## 선택적 작업 (시간 있으면)

- [ ]* 15. 함수 실행 로그 수집
  - 로그 수집 API 구현 (GET /api/functions/{id}/logs)
  - K8s API를 통한 Pod 로그 조회
  - 타임스탬프 및 로그 레벨 포함
  - _요구사항: 14.1, 14.2, 14.3, 14.4_

- [ ]* 16. 리소스 사용량 모니터링
  - 메트릭 수집 API 구현 (GET /api/functions/{id}/metrics)
  - CPU, 메모리, 네트워크 사용량 조회
  - 시간대별 리소스 사용량 반환
  - _요구사항: 15.1, 15.2, 15.3, 15.4_

- [ ]* 17. DomainMapping 기반 라우팅 (참고용)
  - DomainMapping 생성 로직 구현
  - Knative Service 참조 설정
  - 커스텀 도메인 설정
  - _요구사항: 17.1, 17.2, 17.3, 17.4_

- [ ]* 18. 문서 작성
  - API 문서 작성 (OpenAPI/Swagger)
  - 운영 가이드 작성
  - 트러블슈팅 가이드 작성

## 우선순위

**🔥 1순위 (필수 - 반드시 구현):**
- 작업 1-14: 핵심 멀티테넌시 기능
- Namespace 자동 생성, Knative Service 배포, Ingress 라우팅

**✨ 2순위 (시간 남으면):**
- 작업 15-16: 로그 수집, 리소스 모니터링
- 운영 편의성 향상

**⭐ 3순위 (선택):**
- 작업 17: DomainMapping (참고용)
- 작업 18: 문서 작성

## 참고사항

- 속성 테스트(*)는 선택 사항입니다. 시간이 있으면 구현하되, 핵심 기능 완성이 우선입니다.
- 각 체크포인트에서 모든 테스트가 통과해야 다음 단계로 진행합니다.
- 실제 K3s 클러스터 환경에서 테스트합니다.
- Kourier 기반 Ingress를 사용합니다.

