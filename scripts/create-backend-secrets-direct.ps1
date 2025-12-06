# Backend Secrets 직접 생성 스크립트 (PowerShell)
# 받은 .env 정보를 기반으로 Secret 생성

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🔐 Backend Secrets 생성 (Direct)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 받은 정보
$DATABASE_URL = "postgresql://user:password@localhost:5432/runna_db"
$SECRET_KEY = "b7b482449580b9fdf430e28d39b9f3b0bbb570de441a2e3dc69697ffbb307d91"

Write-Host "📝 다음 정보로 Secret을 생성합니다:" -ForegroundColor Yellow
Write-Host "  - DATABASE_URL: postgresql://user:password@localhost:5432/runna_db"
Write-Host "  - SECRET_KEY: b7b48244... (64자)"
Write-Host "  - REDIS_PASSWORD: (없음)"
Write-Host ""

$confirmation = Read-Host "계속하시겠습니까? (y/n)"
if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
    Write-Host "취소되었습니다." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🚀 Kubernetes Secret 생성 중..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Secret 생성 (Redis 비밀번호 없음)
kubectl create secret generic backend-secrets `
    --from-literal=database-url="$DATABASE_URL" `
    --from-literal=secret-key="$SECRET_KEY" `
    --dry-run=client -o yaml | kubectl apply -f -

Write-Host ""
Write-Host "✅ Secret 생성 완료!" -ForegroundColor Green
Write-Host ""

# Secret 확인
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "📋 생성된 Secret 확인" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
kubectl describe secret backend-secrets

Write-Host ""
Write-Host "✅ 모든 작업 완료!" -ForegroundColor Green
Write-Host ""
