# AnalysisTemplate 구현 요약

## 완료된 작업

Task 8.1: Argo Rollouts AnalysisTemplate 작성이 완료되었습니다.

## 생성된 파일

### 1. argocd/analysis-templates/success-rate.yaml

Argo Rollouts에서 사용할 분석 템플릿을 생성했습니다.

**주요 기능:**
- **성공률 메트릭**: 95% 이상 성공률 유지 (에러율 5% 이하)
- **지연 시간 메트릭**: 500ms 이하 응답 시간 유지
- **자동 롤백**: 3회 연속 실패 시 자동으로 이전 버전으로 롤백
- **모니터링 간격**: 1분마다 메트릭 확인

**Prometheus 쿼리:**
- 성공률: `sum(rate(http_requests_total{status=~"2.."}[5m])) / sum(rate(http_requests_total[5m]))`
- 지연 시간: `histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) * 1000`

**협업 노트:**
- Prometheus 주소는 모니터링 담당자가 실제 환경에 맞게 변경 필요
- 메트릭 이름은 실제 애플리케이션의 메트릭 구조에 맞게 조정 필요
- TODO 주석으로 변경이 필요한 부분을 명시

### 2. scripts/validate-analysis-template.py

AnalysisTemplate YAML 파일의 유효성을 검증하는 스크립트입니다.

**검증 항목:**
- YAML 문법 검증
- 필수 필드 존재 여부 (apiVersion, kind, metadata, spec)
- 메트릭 정의 완전성 (name, provider, query, successCondition)

### 3. scripts/test-analysis-template.ps1

Windows 환경에서 AnalysisTemplate을 테스트하는 PowerShell 스크립트입니다.

## 검증 결과

```
✓ Valid AnalysisTemplate: argocd/analysis-templates/success-rate.yaml
  - API Version: argoproj.io/v1alpha1
  - Name: success-rate
  - Metrics: 2
    - success-rate: result >= 0.95
    - latency: result <= 500
```

## 요구사항 충족

**요구사항 3.4**: "WHEN 각 Canary 단계에서 일정 시간이 경과하면 THEN THE System SHALL 다음 단계로 자동 진행한다"

이 AnalysisTemplate은 Canary 배포 중 자동으로 메트릭을 모니터링하여:
- 성공률이 95% 이상이고 지연 시간이 500ms 이하이면 다음 단계로 진행
- 3회 연속 실패하면 자동으로 롤백

## 사용 방법

### Rollout에서 AnalysisTemplate 참조

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: backend
spec:
  strategy:
    canary:
      steps:
        - setWeight: 20
        - pause: {duration: 2m}
        - analysis:
            templates:
              - templateName: success-rate
        - setWeight: 50
        # ... 계속
```

### 로컬 테스트

```powershell
# PowerShell에서 실행
.\scripts\test-analysis-template.ps1
```

## 다음 단계

1. 모니터링 담당자와 협업하여 실제 Prometheus 주소 및 메트릭 이름 확인
2. Rollout 템플릿에 AnalysisTemplate 참조 추가 (선택사항)
3. Staging 환경에서 Canary 배포 테스트

## 참고 자료

- [Argo Rollouts Analysis](https://argoproj.github.io/argo-rollouts/features/analysis/)
- [AnalysisTemplate Specification](https://argoproj.github.io/argo-rollouts/features/analysis/#analysistemplate)
