#!/usr/bin/env pwsh
# Test Argo Rollouts Configuration
# Validates requirements 3.1, 3.2, 3.3, 3.4, 3.5

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Argo Rollouts Configuration Test" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""

# Run validation script
Write-Host "Running validation script..." -ForegroundColor Yellow
python scripts/validate-rollout-config.py
$validationExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "Running comprehensive tests..." -ForegroundColor Yellow
python tests/test_rollout_configuration.py
$testExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "Final Summary" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

if ($validationExitCode -eq 0 -and $testExitCode -eq 0) {
    Write-Host "✅ All Argo Rollouts configurations are valid!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Configuration verified:" -ForegroundColor Green
    Write-Host "  • Rollout template structure: ✅" -ForegroundColor Green
    Write-Host "  • Canary strategy (20% → 50% → 80% → 100%, 2m pauses): ✅" -ForegroundColor Green
    Write-Host "  • Blue-Green strategy (manual approval): ✅" -ForegroundColor Green
    Write-Host "  • Environment-specific configurations: ✅" -ForegroundColor Green
    Write-Host ""
    Write-Host "Requirements validated:" -ForegroundColor Green
    Write-Host "  • 3.1: Argo Rollouts for Canary deployment ✅" -ForegroundColor Green
    Write-Host "  • 3.2: Initial 20% traffic routing ✅" -ForegroundColor Green
    Write-Host "  • 3.3: Progressive traffic increase ✅" -ForegroundColor Green
    Write-Host "  • 3.4: Automatic progression with pauses ✅" -ForegroundColor Green
    Write-Host "  • 3.5: Blue-Green with manual approval ✅" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Some tests failed" -ForegroundColor Red
    exit 1
}
