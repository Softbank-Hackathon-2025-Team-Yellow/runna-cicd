# 구현 계획

## 개요

이 문서는 서버리스 플랫폼의 CI/CD 및 GitOps 파이프라인 구현을 위한 작업 목록입니다. 해커톤 일정을 고려하여 핵심 기능에 집중합니다.

## 작업 목록

- [x] 1. 프로젝트 구조 및 기본 설정





  - 디렉토리 구조 생성 (helm/, .github/workflows/, argocd/)
  - .gitignore 파일 작성
  - README.md 작성 (프로젝트 개요 및 사용법)
  - _요구사항: 모든 요구사항의 기반_

- [x] 2. Dockerfile 작성





  - services/backend/Dockerfile 작성 (Python 멀티 스테이지 빌드)
  - services/frontend/Dockerfile 작성 (Node.js + Nginx 멀티 스테이지 빌드)
  - services/worker/Dockerfile 작성
  - 각 Dockerfile에 non-root 사용자 설정 포함
  - _요구사항: 1.2_

- [x] 2.1 Dockerfile 빌드 테스트






  - 각 Dockerfile을 로컬에서 빌드하여 문법 오류 확인
  - _요구사항: 7.1_

- [x] 3. Helm 차트 작성 - 플랫폼 서비스





  - helm/charts/platform-service/Chart.yaml 작성
  - helm/charts/platform-service/values.yaml 작성 (기본 values)
  - helm/charts/platform-service/templates/deployment.yaml 작성
  - helm/charts/platform-service/templates/service.yaml 작성
  - helm/charts/platform-service/templates/ingress.yaml 작성
  - helm/charts/platform-service/templates/rollout.yaml 작성 (Canary/Blue-Green 지원)
  - _요구사항: 4.1, 4.2_

- [x] 3.1 Helm 차트 검증







  - helm lint로 문법 오류 확인
  - helm template로 렌더링 테스트
  - _요구사항: 7.2, 7.3_

- [x] 4. 환경별 Helm values 파일 작성 (핵심 환경만)





  - helm/values/values-backend-dev.yaml 작성 (일반 Deployment)
  - helm/values/values-backend-staging.yaml 작성 (Canary 전략)
  - helm/values/values-backend-prod.yaml 작성 (Blue-Green 전략, 시연용)
  - _요구사항: 5.1, 5.2, 5.3, 5.4_

- [x] 4.1 속성 테스트: Rollout 전략 일관성







  - **속성 6: Rollout 전략 일관성**
  - **검증: 요구사항 5.3, 5.4**
  - staging은 Canary, production은 Blue-Green 전략을 사용하는지 테스트
  - _요구사항: 5.3, 5.4_

- [x] 5. GitHub Actions 워크플로우 작성





  - .github/workflows/ci-cd.yml 작성
  - matrix strategy로 backend 서비스 빌드 설정 (frontend/worker는 나중에 확장)
  - AWS OIDC 인증 설정
  - ECR 로그인 및 푸시 단계 작성
  - Helm values 자동 업데이트 로직 작성 (yq 사용)
  - Git 커밋 및 푸시 단계 작성
  - _요구사항: 1.1, 1.2, 1.3, 1.4, 1.5_

- [x] 5.1 이미지 태그 생성 로직 구현


  - GitHub Actions에서 Git 커밋 해시로 태그 생성
  - 태그 형식: ${GITHUB_SHA:0:15}
  - _요구사항: 8.1, 8.2, 8.3_

- [x] 5.2 속성 테스트: 이미지 태그 고유성






  - **속성 1: 이미지 태그 고유성**
  - **검증: 요구사항 1.3, 8.1**
  - 모든 Git 커밋에 대해 고유한 태그가 생성되는지 테스트
  - _요구사항: 1.3, 8.1_

- [x] 5.3 Helm values 업데이트 로직 구현



  - yq를 사용한 YAML 업데이트
  - image.tag 필드만 업데이트
  - _요구사항: 1.4_

- [x] 5.4 속성 테스트: Helm values 업데이트 일관성







  - **속성 2: Helm values 업데이트 일관성**
  - **검증: 요구사항 1.4**
  - values 업데이트 후 파싱하면 새 태그가 정확히 반영되는지 테스트
  - _요구사항: 1.4_

- [x] 6. 체크포인트 1 - CI 파이프라인 완료





  - 모든 테스트가 통과하는지 확인
  - 사용자에게 질문이 있으면 문의
  - _작업 1-5 완료 후_

- [x] 7. ArgoCD Application 작성 (핵심 환경만)





  - argocd/root-app.yaml 작성 (App-of-Apps 패턴)
  - argocd/applications/backend-dev.yaml 작성
  - argocd/applications/backend-staging.yaml 작성
  - 각 Application에 syncPolicy 설정 (automated, prune, selfHeal)
  - _요구사항: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 7.1 ArgoCD dry-run 테스트






  - argocd CLI를 사용하여 동기화 시뮬레이션
  - _요구사항: 7.4_

- [x] 8. Argo Rollouts 설정





  - Rollout 리소스가 Helm 템플릿에서 올바르게 생성되는지 확인
  - Canary 전략 설정 (20% → 50% → 80% → 100%, 각 2분 대기)
  - Blue-Green 전략 설정 (수동 승인)
  - _요구사항: 3.1, 3.2, 3.3, 3.5_

- [x] 8.1 Argo Rollouts AnalysisTemplate 작성






  - argocd/analysis-templates/success-rate.yaml 작성
  - Prometheus 메트릭 쿼리 placeholder 작성 (모니터링 담당자와 협업)
  - 임계값 설정 (에러율 5%, 지연 시간 500ms)
  - _요구사항: 3.4_

- [x] 9. 체크포인트 2 - GitOps 설정 완료





  - 모든 테스트가 통과하는지 확인
  - 사용자에게 질문이 있으면 문의
  - _작업 7-8 완료 후_

- [x] 10. 에러 처리 및 로깅





  - GitHub Actions에 에러 로깅 추가
  - 빌드 실패 시 상세 에러 메시지 출력
  - ECR 푸시 실패 시 재시도 로직 추가 (최대 3회)
  - _요구사항: 6.1, 6.2, 6.3, 6.4_

- [x] 11. 통합 테스트


  - 전체 파이프라인 엔드투엔드 테스트
  - 코드 푸시 → 빌드 → ECR 푸시 → Helm values 업데이트 → ArgoCD 동기화 확인
  - Canary 배포 시나리오 테스트 (staging)
  - _요구사항: 모든 요구사항_

- [x] 12. 최종 체크포인트



  - 모든 테스트가 통과하는지 확인
  - 사용자에게 질문이 있으면 문의
  - _작업 10-11 완료 후_

## 확장 작업 (시간 있으면)

- [ ]* 13. Frontend/Worker 서비스 추가
  - GitHub Actions matrix에 frontend, worker 추가
  - 각 서비스별 values 파일 작성
  - ArgoCD Application 추가

- [ ]* 14. Production 환경 완성
  - values-backend-prod.yaml 완성
  - argocd/applications/backend-prod.yaml 작성
  - Blue-Green 배포 테스트

- [ ]* 15. 사용자 함수 Helm 차트
  - helm/charts/user-function/ 작성
  - Backend 팀과 협업하여 함수 배포 테스트

- [ ]* 16. AWS 설정 문서
  - docs/aws-setup.md 작성
  - IAM Role 정책 JSON 작성

- [ ]* 17. 운영 가이드
  - docs/operations.md 작성
  - 트러블슈팅 가이드

## 우선순위

**🔥 1순위 (해커톤 필수 - 반드시 구현):**
- 작업 1-11: 기본 CI/CD + GitOps 파이프라인
- Backend 서비스 1개로 전체 흐름 완성

**✨ 2순위 (시간 남으면):**
- 작업 13-14: 다른 서비스 추가, Production 환경
- 작업 8.1: AnalysisTemplate (메트릭 기반 롤백)

**⭐ 3순위 (선택):**
- 작업 15-17: 사용자 함수, 문서화
- 모든 속성 테스트 (*)

## 현실적 목표

**해커톤 D-Day 기준:**
- **최소 목표**: 작업 1-11 완료 (Backend 1개 서비스로 전체 파이프라인 시연)
- **이상적 목표**: 작업 1-14 완료 (3개 서비스 + Production 환경)
- **완벽한 목표**: 작업 1-17 완료 (모든 기능 + 문서)

## 참고사항

- 속성 테스트(*)는 선택 사항입니다. 시간이 있으면 구현하되, 핵심 기능 완성이 우선입니다.
- 각 체크포인트에서 모든 테스트가 통과해야 다음 단계로 진행합니다.
- Backend 팀의 더미 애플리케이션이 준비되면 즉시 통합 테스트를 시작합니다.
- Frontend/Worker는 Backend 파이프라인이 완성된 후 동일한 패턴으로 빠르게 추가할 수 있습니다.
