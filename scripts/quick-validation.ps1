# Quick Local Validation Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Quick Local Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check Dockerfile
Write-Host "1. Checking Dockerfile..." -ForegroundColor Yellow
if (Test-Path "backend-repo/Dockerfile") {
    Write-Host "  OK backend-repo/Dockerfile exists" -ForegroundColor Green
} else {
    Write-Host "  ERROR backend-repo/Dockerfile not found" -ForegroundColor Red
}
Write-Host ""

# 2. Check Helm Chart
Write-Host "2. Checking Helm Chart..." -ForegroundColor Yellow
if (Test-Path "helm/charts/platform-service/Chart.yaml") {
    Write-Host "  OK Helm Chart exists" -ForegroundColor Green
} else {
    Write-Host "  ERROR Helm Chart not found" -ForegroundColor Red
}
Write-Host ""

# 3. Check GitHub Actions
Write-Host "3. Checking GitHub Actions workflow..." -ForegroundColor Yellow
if (Test-Path ".github/workflows/ci-cd.yml") {
    Write-Host "  OK GitHub Actions workflow exists" -ForegroundColor Green
} else {
    Write-Host "  ERROR GitHub Actions workflow not found" -ForegroundColor Red
}
Write-Host ""

# 4. Check Docker
Write-Host "4. Checking Docker..." -ForegroundColor Yellow
$dockerRunning = $false
try {
    $null = docker version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK Docker is running" -ForegroundColor Green
        $dockerRunning = $true
    }
} catch {
    Write-Host "  ERROR Docker is not running" -ForegroundColor Red
}
if (-not $dockerRunning) {
    Write-Host "  ERROR Docker is not running" -ForegroundColor Red
}
Write-Host ""

# 5. Check Helm
Write-Host "5. Checking Helm..." -ForegroundColor Yellow
$helmInstalled = $false
try {
    $null = helm version --short 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK Helm is installed" -ForegroundColor Green
        $helmInstalled = $true
    }
} catch {
    Write-Host "  WARNING Helm not installed (optional)" -ForegroundColor Yellow
}
if (-not $helmInstalled) {
    Write-Host "  WARNING Helm not installed (optional)" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Validation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Test Docker image build" -ForegroundColor Gray
Write-Host "     docker build -t backend-test ./backend-repo" -ForegroundColor Cyan
Write-Host ""
Write-Host "  2. Validate Helm Chart" -ForegroundColor Gray
Write-Host "     helm lint helm/charts/platform-service" -ForegroundColor Cyan
Write-Host ""
Write-Host "  3. Run full validation" -ForegroundColor Gray
Write-Host "     .\scripts\local-validation\run-all-tests.ps1" -ForegroundColor Cyan
Write-Host ""
