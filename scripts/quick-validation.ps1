# 빠른 로컬 검증
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "빠른 로컬 검증" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Dockerfile 확인
Write-Host "1. Dockerfile 확인..." -ForegroundColor Yellow
if (Test-Path "backend-repo/Dockerfile") {
    Write-Host "  ✅ backend-repo/Dockerfile 존재" -ForegroundColor Green
} else {
    Write-Host "  ❌ backend-repo/Dockerfile 없음" -ForegroundColor Red
}
Write-Host ""

# 2. Helm Chart 확인
Write-Host "2. Helm Chart 확인..." -ForegroundColor Yellow
if (Test-Path "helm/charts/platform-service/Chart.yaml") {
    Write-Host "  ✅ Helm Chart 존재" -ForegroundColor Green
} else {
    Write-Host "  ❌ Helm Chart 없음" -ForegroundColor Red
}
Write-Host ""

# 3. GitHub Actions 확인
Write-Host "3. GitHub Actions 워크플로우 확인..." -ForegroundColor Yellow
if (Test-Path ".github/workflows/ci-cd.yml") {
    Write-Host "  ✅ GitHub Actions 워크플로우 존재" -ForegroundColor Green
} else {
    Write-Host "  ❌ GitHub Actions 워크플로우 없음" -ForegroundColor Red
}
Write-Host ""

# 4. Docker 실행 확인
Write-Host "4. Docker 실행 확인..." -ForegroundColor Yellow
$dockerRunning = $false
try {
    $null = docker version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Docker 실행 중" -ForegroundColor Green
        $dockerRunning = $true
    }
}
catch {
    Write-Host "  ❌ Docker 미실행" -ForegroundColor Red
}
if (-not $dockerRunning) {
    Write-Host "  ❌ Docker 미실행" -ForegroundColor Red
}
Write-Host ""

# 5. Helm 설치 확인
Write-Host "5. Helm 설치 확인..." -ForegroundColor Yellow
$helmInstalled = $false
try {
    $null = helm version --short 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Helm 설치됨" -ForegroundColor Green
        $helmInstalled = $true
    }
}
catch {
    Write-Host "  ⚠️  Helm 미설치 (선택사항)" -ForegroundColor Yellow
}
if (-not $helmInstalled) {
    Write-Host "  ⚠️  Helm 미설치 (선택사항)" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 빠른 검증 완료!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "  1. Docker 이미지 빌드 테스트" -ForegroundColor Gray
Write-Host "     docker build -t backend-test ./backend-repo" -ForegroundColor Cyan
Write-Host ""
Write-Host "  2. Helm Chart 검증" -ForegroundColor Gray
Write-Host "     helm lint helm/charts/platform-service" -ForegroundColor Cyan
Write-Host ""
Write-Host "  3. 전체 검증 실행" -ForegroundColor Gray
Write-Host "     .\scripts\local-validation\run-all-tests.ps1" -ForegroundColor Cyan
Write-Host ""
