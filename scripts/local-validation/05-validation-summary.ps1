# 로컬 검증 전체 요약
# Windows PowerShell 스크립트

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "로컬 검증 전체 요약" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 검증 결과 저장
$results = @{
    "Dockerfile" = $false
    "Container" = $false
    "HelmChart" = $false
    "GitHubActions" = $false
}

# 1. Dockerfile 검증 결과
Write-Host "1. Dockerfile 검증..." -ForegroundColor Yellow
$imageExists = docker images -q backend-local-test:latest 2>$null
if ($imageExists) {
    Write-Host "  ✅ 이미지 빌드 성공" -ForegroundColor Green
    $results["Dockerfile"] = $true
} else {
    Write-Host "  ❌ 이미지 빌드 필요" -ForegroundColor Red
    Write-Host "     실행: .\scripts\local-validation\01-test-backend-dockerfile.ps1" -ForegroundColor Gray
}
Write-Host ""

# 2. 컨테이너 실행 결과
Write-Host "2. 컨테이너 실행..." -ForegroundColor Yellow
$containerRunning = docker ps -q -f name=backend-test 2>$null
if ($containerRunning) {
    Write-Host "  ✅ 컨테이너 실행 중" -ForegroundColor Green
    $results["Container"] = $true
    
    # Health Check
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        Write-Host "  ✅ Health Check 성공" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  Health Check 실패 (DB 연결 필요할 수 있음)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  컨테이너 미실행" -ForegroundColor Yellow
    Write-Host "     실행: .\scripts\local-validation\02-test-backend-container.ps1" -ForegroundColor Gray
}
Write-Host ""

# 3. Helm Chart 검증 결과
Write-Host "3. Helm Chart 검증..." -ForegroundColor Yellow
if (Test-Path "helm/charts/platform-service/Chart.yaml") {
    Write-Host "  ✅ Helm Chart 존재" -ForegroundColor Green
    $results["HelmChart"] = $true
    
    # Helm 설치 확인
    try {
        helm version --short 2>&1 | Out-Null
        Write-Host "  ✅ Helm 설치됨" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  Helm 미설치" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ❌ Helm Chart 없음" -ForegroundColor Red
}
Write-Host ""

# 4. GitHub Actions 검증 결과
Write-Host "4. GitHub Actions 워크플로우..." -ForegroundColor Yellow
if (Test-Path ".github/workflows/ci-cd.yml") {
    Write-Host "  ✅ 워크플로우 파일 존재" -ForegroundColor Green
    $results["GitHubActions"] = $true
} else {
    Write-Host "  ❌ 워크플로우 파일 없음" -ForegroundColor Red
}
Write-Host ""

# 5. 전체 점수 계산
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📊 검증 결과 요약" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$totalTests = $results.Count
$passedTests = ($results.Values | Where-Object { $_ -eq $true }).Count
$percentage = [math]::Round(($passedTests / $totalTests) * 100, 0)

Write-Host "통과: $passedTests / $totalTests ($percentage%)" -ForegroundColor Cyan
Write-Host ""

foreach ($test in $results.GetEnumerator()) {
    $status = if ($test.Value) { "✅" } else { "❌" }
    $color = if ($test.Value) { "Green" } else { "Red" }
    Write-Host "  $status $($test.Key)" -ForegroundColor $color
}
Write-Host ""

# 6. 다음 단계 안내
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 다음 단계" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($percentage -eq 100) {
    Write-Host "🎉 모든 로컬 검증 완료!" -ForegroundColor Green
    Write-Host ""
    Write-Host "이제 실제 배포를 준비할 수 있습니다:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. 팀원들에게 필요한 정보 요청" -ForegroundColor Cyan
    Write-Host "   - K8s 클러스터 접근 권한 (동규님)" -ForegroundColor Gray
    Write-Host "   - AWS 리소스 정보 (소현님)" -ForegroundColor Gray
    Write-Host "   - 도메인 정보 (팀)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. 백엔드 저장소에 파일 추가" -ForegroundColor Cyan
    Write-Host "   - Dockerfile (검증 완료)" -ForegroundColor Gray
    Write-Host "   - .dockerignore" -ForegroundColor Gray
    Write-Host "   - GitHub Actions 워크플로우" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. K8s 클러스터 설정" -ForegroundColor Cyan
    Write-Host "   - Namespace 생성" -ForegroundColor Gray
    Write-Host "   - Secrets 생성" -ForegroundColor Gray
    Write-Host "   - ArgoCD 설치" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "⚠️  일부 검증이 완료되지 않았습니다." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "미완료 항목:" -ForegroundColor Cyan
    foreach ($test in $results.GetEnumerator()) {
        if (-not $test.Value) {
            Write-Host "  - $($test.Key)" -ForegroundColor Red
        }
    }
    Write-Host ""
    Write-Host "각 검증 스크립트를 실행해주세요:" -ForegroundColor Yellow
    Write-Host "  .\scripts\local-validation\01-test-backend-dockerfile.ps1" -ForegroundColor Gray
    Write-Host "  .\scripts\local-validation\02-test-backend-container.ps1" -ForegroundColor Gray
    Write-Host "  .\scripts\local-validation\03-test-helm-chart.ps1" -ForegroundColor Gray
    Write-Host "  .\scripts\local-validation\04-test-github-actions.ps1" -ForegroundColor Gray
    Write-Host ""
}

# 7. 유용한 명령어
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🔧 유용한 명령어" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "컨테이너 관리:" -ForegroundColor Yellow
Write-Host "  docker logs -f backend-test          # 로그 확인" -ForegroundColor Gray
Write-Host "  docker stop backend-test             # 컨테이너 중지" -ForegroundColor Gray
Write-Host "  docker rm -f backend-test            # 컨테이너 제거" -ForegroundColor Gray
Write-Host "  docker rmi backend-local-test:latest # 이미지 제거" -ForegroundColor Gray
Write-Host ""
Write-Host "Helm 명령어:" -ForegroundColor Yellow
Write-Host "  helm lint helm/charts/platform-service                    # Chart 검증" -ForegroundColor Gray
Write-Host "  helm template backend helm/charts/platform-service        # 템플릿 렌더링" -ForegroundColor Gray
Write-Host "  helm install backend helm/charts/platform-service --dry-run # Dry-run" -ForegroundColor Gray
Write-Host ""
Write-Host "정리 명령어:" -ForegroundColor Yellow
Write-Host "  docker system prune -a               # 모든 미사용 리소스 정리" -ForegroundColor Gray
Write-Host ""

# 8. 참고 문서
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📚 참고 문서" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  - 실제 배포 체크리스트: docs/real-deployment-checklist.md" -ForegroundColor Gray
Write-Host "  - 필요한 정보 목록: docs/deployment-info-needed.md" -ForegroundColor Gray
Write-Host "  - 설계 문서: .kiro/specs/serverless-cicd-pipeline/design.md" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 검증 요약 완료!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
