# Test script for AnalysisTemplate validation

Write-Host "Testing AnalysisTemplate..." -ForegroundColor Cyan

# Run validation
python scripts/validate-analysis-template.py

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ AnalysisTemplate validation passed" -ForegroundColor Green
} else {
    Write-Host "`n✗ AnalysisTemplate validation failed" -ForegroundColor Red
    exit 1
}

Write-Host "`nAnalysisTemplate Details:" -ForegroundColor Cyan
Write-Host "- File: argocd/analysis-templates/success-rate.yaml"
Write-Host "- Metrics:"
Write-Host "  1. success-rate: >= 95% (error rate <= 5%)"
Write-Host "  2. latency: <= 500ms"
Write-Host "- Failure limit: 3 consecutive failures trigger rollback"
Write-Host "- Interval: 1 minute checks"
Write-Host "`nNote: Prometheus queries are placeholders for monitoring team" -ForegroundColor Yellow
