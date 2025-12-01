# Test runner for ArgoCD dry-run simulation
# This script runs the ArgoCD dry-run validation tests

Write-Host "=== Running ArgoCD Dry-Run Tests ===" -ForegroundColor Cyan
Write-Host ""

# Run the dry-run simulation test
$testScript = "scripts/test-argocd-dryrun.ps1"

if (-not (Test-Path $testScript)) {
    Write-Host "Error: Test script not found: $testScript" -ForegroundColor Red
    exit 1
}

Write-Host "Executing: $testScript" -ForegroundColor Gray
Write-Host ""

# Execute the test script
& powershell -ExecutionPolicy Bypass -File $testScript

$exitCode = $LASTEXITCODE

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "=== ArgoCD Dry-Run Tests PASSED ===" -ForegroundColor Green
} else {
    Write-Host "=== ArgoCD Dry-Run Tests FAILED ===" -ForegroundColor Red
}

exit $exitCode
