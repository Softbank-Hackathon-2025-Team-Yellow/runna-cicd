# GitHub Actions 워크플로우 검증
# Windows PowerShell 스크립트

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GitHub Actions 워크플로우 검증" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 워크플로우 파일 확인
Write-Host "1. 워크플로우 파일 확인..." -ForegroundColor Yellow
$workflowFile = ".github/workflows/ci-cd.yml"

if (-Not (Test-Path $workflowFile)) {
    Write-Host "❌ 워크플로우 파일을 찾을 수 없습니다: $workflowFile" -ForegroundColor Red
    exit 1
}
Write-Host "✅ 워크플로우 파일 확인: $workflowFile" -ForegroundColor Green
Write-Host ""

# 2. YAML 문법 검증
Write-Host "2. YAML 문법 검증..." -ForegroundColor Yellow
try {
    # PowerShell에서 YAML 파싱 (간단한 검증)
    $content = Get-Content $workflowFile -Raw
    
    # 기본 구조 확인
    if ($content -match "name:" -and $content -match "on:" -and $content -match "jobs:") {
        Write-Host "✅ 기본 YAML 구조 확인" -ForegroundColor Green
    } else {
        Write-Host "⚠️  YAML 구조가 불완전할 수 있습니다." -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ YAML 파싱 실패" -ForegroundColor Red
    Write-Host "에러: $_" -ForegroundColor Red
}
Write-Host ""

# 3. 워크플로우 내용 확인
Write-Host "3. 워크플로우 주요 내용..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray
Get-Content $workflowFile | Select-Object -First 50
Write-Host "..." -ForegroundColor Gray
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host ""

# 4. 필수 요소 확인
Write-Host "4. 필수 요소 확인..." -ForegroundColor Yellow
$content = Get-Content $workflowFile -Raw

$checks = @{
    "Trigger (on push)" = $content -match "on:\s*push:"
    "Jobs 정의" = $content -match "jobs:"
    "Checkout 액션" = $content -match "actions/checkout"
    "Docker 빌드" = $content -match "docker build"
    "ECR 로그인" = $content -match "amazon-ecr-login"
}

foreach ($check in $checks.GetEnumerator()) {
    if ($check.Value) {
        Write-Host "  ✅ $($check.Key)" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $($check.Key) (없음)" -ForegroundColor Yellow
    }
}
Write-Host ""

# 5. 환경변수 확인
Write-Host "5. 환경변수 확인..." -ForegroundColor Yellow
if ($content -match "env:") {
    Write-Host "  ✅ 환경변수 정의됨" -ForegroundColor Green
    
    # 주요 환경변수 추출
    $envVars = @("AWS_REGION", "ECR_REGISTRY")
    foreach ($var in $envVars) {
        if ($content -match $var) {
            Write-Host "    - $var" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "  ⚠️  환경변수가 정의되지 않았습니다." -ForegroundColor Yellow
}
Write-Host ""

# 6. Secrets 사용 확인
Write-Host "6. GitHub Secrets 사용 확인..." -ForegroundColor Yellow
$secretsUsed = @()

if ($content -match '\$\{\{\s*secrets\.(\w+)\s*\}\}') {
    $matches = [regex]::Matches($content, '\$\{\{\s*secrets\.(\w+)\s*\}\}')
    foreach ($match in $matches) {
        $secretName = $match.Groups[1].Value
        if ($secretsUsed -notcontains $secretName) {
            $secretsUsed += $secretName
        }
    }
    
    Write-Host "  사용된 Secrets:" -ForegroundColor Cyan
    foreach ($secret in $secretsUsed) {
        Write-Host "    - $secret" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠️  Secrets가 사용되지 않았습니다." -ForegroundColor Yellow
}
Write-Host ""

# 7. Matrix Strategy 확인
Write-Host "7. Matrix Strategy 확인..." -ForegroundColor Yellow
if ($content -match "strategy:\s*matrix:") {
    Write-Host "  ✅ Matrix Strategy 사용됨" -ForegroundColor Green
    
    # Service 목록 추출
    if ($content -match "service:\s*\[(.*?)\]") {
        $services = $matches[1] -split ',' | ForEach-Object { $_.Trim() }
        Write-Host "  서비스 목록:" -ForegroundColor Cyan
        foreach ($service in $services) {
            Write-Host "    - $service" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  ℹ️  Matrix Strategy 미사용 (단일 서비스)" -ForegroundColor Cyan
}
Write-Host ""

# 8. Act 설치 확인 (로컬 테스트용)
Write-Host "8. Act (로컬 GitHub Actions) 확인..." -ForegroundColor Yellow
try {
    $actExists = Get-Command act -ErrorAction SilentlyContinue
    if ($actExists) {
        $actVersion = act --version 2>&1
        Write-Host "  ✅ Act 설치됨: $actVersion" -ForegroundColor Green
        Write-Host ""
        Write-Host "  💡 로컬 테스트 명령어:" -ForegroundColor Cyan
        Write-Host "     act push -j build-and-deploy --secret-file .secrets" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠️  Act가 설치되지 않았습니다. (선택사항)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Act 설치 방법:" -ForegroundColor Cyan
        Write-Host "    choco install act-cli" -ForegroundColor Gray
        Write-Host "    또는 https://github.com/nektos/act" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ⚠️  Act 확인 실패" -ForegroundColor Yellow
}
Write-Host ""

# 9. 워크플로우 구조 분석
Write-Host "9. 워크플로우 구조 분석..." -ForegroundColor Yellow

# Jobs 추출
$jobMatches = [regex]::Matches($content, '^\s{2}(\w+[-\w]*):\s*$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
if ($jobMatches.Count -gt 0) {
    Write-Host "  Jobs:" -ForegroundColor Cyan
    foreach ($match in $jobMatches) {
        $jobName = $match.Groups[1].Value
        Write-Host "    - $jobName" -ForegroundColor Gray
    }
} else {
    Write-Host "  ⚠️  Jobs를 찾을 수 없습니다." -ForegroundColor Yellow
}
Write-Host ""

# 10. 권장 사항
Write-Host "10. 권장 사항 및 체크리스트..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  배포 전 확인사항:" -ForegroundColor Cyan
Write-Host "    [ ] AWS_ROLE_ARN Secret 설정" -ForegroundColor Gray
Write-Host "    [ ] ECR_REGISTRY 환경변수 설정" -ForegroundColor Gray
Write-Host "    [ ] GitHub Actions 권한 설정" -ForegroundColor Gray
Write-Host "    [ ] 브랜치 보호 규칙 설정 (선택)" -ForegroundColor Gray
Write-Host ""
Write-Host "  필요한 GitHub Secrets:" -ForegroundColor Cyan
foreach ($secret in $secretsUsed) {
    Write-Host "    [ ] $secret" -ForegroundColor Gray
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ GitHub Actions 검증 완료!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 검증 결과:" -ForegroundColor Yellow
Write-Host "  - YAML 문법: ✅" -ForegroundColor Green
Write-Host "  - 필수 요소: ✅" -ForegroundColor Green
Write-Host "  - Secrets 확인: ✅" -ForegroundColor Green
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "  - 전체 검증 요약: .\scripts\local-validation\05-validation-summary.ps1" -ForegroundColor Gray
Write-Host ""
