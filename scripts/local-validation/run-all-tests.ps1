# 전체 로컬 검증 실행
# Windows PowerShell 스크립트

param(
    [switch]$SkipDocker,
    [switch]$SkipContainer,
    [switch]$SkipHelm,
    [switch]$SkipGitHub
)

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   로컬 검증 전체 실행                  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date

# 1. Dockerfile 빌드 테스트
if (-not $SkipDocker) {
    Write-Host "▶ Step 1/4: Dockerfile 빌드 테스트" -ForegroundColor Magenta
    Write-Host ""
    & "$PSScriptRoot\01-test-backend-dockerfile.ps1"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "❌ Dockerfile 빌드 실패. 중단합니다." -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""
} else {
    Write-Host "⏭️  Step 1/4: Dockerfile 테스트 건너뜀" -ForegroundColor Yellow
    Write-Host ""
}

# 2. 컨테이너 실행 테스트
if (-not $SkipContainer) {
    Write-Host "▶ Step 2/4: 컨테이너 실행 테스트" -ForegroundColor Magenta
    Write-Host ""
    & "$PSScriptRoot\02-test-backend-container.ps1"
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""
} else {
    Write-Host "⏭️  Step 2/4: 컨테이너 테스트 건너뜀" -ForegroundColor Yellow
    Write-Host ""
}

# 3. Helm Chart 검증
if (-not $SkipHelm) {
    Write-Host "▶ Step 3/4: Helm Chart 검증" -ForegroundColor Magenta
    Write-Host ""
    & "$PSScriptRoot\03-test-helm-chart.ps1"
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""
} else {
    Write-Host "⏭️  Step 3/4: Helm Chart 검증 건너뜀" -ForegroundColor Yellow
    Write-Host ""
}

# 4. GitHub Actions 검증
if (-not $SkipGitHub) {
    Write-Host "▶ Step 4/4: GitHub Actions 검증" -ForegroundColor Magenta
    Write-Host ""
    & "$PSScriptRoot\04-test-github-actions.ps1"
    
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Host ""
} else {
    Write-Host "⏭️  Step 4/4: GitHub Actions 검증 건너뜀" -ForegroundColor Yellow
    Write-Host ""
}

# 5. 전체 요약
Write-Host "▶ 전체 요약" -ForegroundColor Magenta
Write-Host ""
& "$PSScriptRoot\05-validation-summary.ps1"

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host ""
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   전체 검증 완료!                      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "⏱️  총 소요 시간: $([math]::Round($duration, 2))초" -ForegroundColor Cyan
Write-Host ""
