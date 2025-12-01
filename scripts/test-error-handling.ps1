# Test script for error handling validation
# This script validates the GitHub Actions workflow error handling implementation

Write-Host "🧪 Testing Error Handling Implementation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Run the validation script
Write-Host "Running validation script..." -ForegroundColor Yellow
python scripts/validate-error-handling.py

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Error handling validation PASSED" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary of implemented features:" -ForegroundColor Cyan
    Write-Host "  ✅ Structured error logging with timestamps" -ForegroundColor Green
    Write-Host "  ✅ Docker build error handling with detailed logs" -ForegroundColor Green
    Write-Host "  ✅ ECR push retry logic (max 3 attempts)" -ForegroundColor Green
    Write-Host "  ✅ Helm values update error handling" -ForegroundColor Green
    Write-Host "  ✅ Git push retry logic (max 3 attempts)" -ForegroundColor Green
    Write-Host "  ✅ Success and failure summary steps" -ForegroundColor Green
    Write-Host "  ✅ GitHub Actions annotations (::error::, ::warning::, ::notice::)" -ForegroundColor Green
    Write-Host "  ✅ Grouped log output for better readability" -ForegroundColor Green
    Write-Host ""
    Write-Host "Requirements validated:" -ForegroundColor Cyan
    Write-Host "  ✅ 6.1: GitHub Actions에 에러 로깅 추가" -ForegroundColor Green
    Write-Host "  ✅ 6.2: 빌드 실패 시 상세 에러 메시지 출력" -ForegroundColor Green
    Write-Host "  ✅ 6.3: ECR 푸시 실패 시 재시도 로직 추가 (최대 3회)" -ForegroundColor Green
    Write-Host "  ✅ 6.4: Git 푸시 실패 시 재시도 로직 추가" -ForegroundColor Green
    Write-Host ""
    exit 0
} else {
    Write-Host ""
    Write-Host "❌ Error handling validation FAILED" -ForegroundColor Red
    Write-Host "Please check the output above for details" -ForegroundColor Red
    Write-Host ""
    exit 1
}
