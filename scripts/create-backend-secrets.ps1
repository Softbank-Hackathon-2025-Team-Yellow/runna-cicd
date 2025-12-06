# Backend Secrets 생성 스크립트 (PowerShell)
# 사용법: .\scripts\create-backend-secrets.ps1

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🔐 Backend Secrets 생성" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 시크릿 값 입력 받기
Write-Host "📝 시크릿 정보를 입력하세요:" -ForegroundColor Yellow
Write-Host ""

# DATABASE_URL
Write-Host "1. DATABASE_URL" -ForegroundColor Green
Write-Host "   예시: postgresql://user:password@host:5432/dbname"
$DATABASE_URL = Read-Host "   입력"

# REDIS_PASSWORD (선택사항)
Write-Host ""
Write-Host "2. REDIS_PASSWORD (선택사항, 없으면 Enter)" -ForegroundColor Green
$REDIS_PASSWORD = Read-Host "   입력" -AsSecureString
$REDIS_PASSWORD_PLAIN = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($REDIS_PASSWORD)
)

# SECRET_KEY
Write-Host ""
Write-Host "3. SECRET_KEY (JWT 토큰 서명용)" -ForegroundColor Green
Write-Host "   예시: your-super-secret-key-here-min-32-chars"
$SECRET_KEY = Read-Host "   입력" -AsSecureString
$SECRET_KEY_PLAIN = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SECRET_KEY)
)

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🚀 Kubernetes Secret 생성 중..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Secret 생성 명령어 구성
if ([string]::IsNullOrEmpty($REDIS_PASSWORD_PLAIN)) {
    # Redis 비밀번호가 없는 경우
    kubectl create secret generic backend-secrets `
        --from-literal=database-url="$DATABASE_URL" `
        --from-literal=secret-key="$SECRET_KEY_PLAIN" `
        --dry-run=client -o yaml | kubectl apply -f -
} else {
    # Redis 비밀번호가 있는 경우
    kubectl create secret generic backend-secrets `
        --from-literal=database-url="$DATABASE_URL" `
        --from-literal=redis-password="$REDIS_PASSWORD_PLAIN" `
        --from-literal=secret-key="$SECRET_KEY_PLAIN" `
        --dry-run=client -o yaml | kubectl apply -f -
}

Write-Host ""
Write-Host "✅ Secret 생성 완료!" -ForegroundColor Green
Write-Host ""

# Secret 확인
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "📋 생성된 Secret 확인" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
kubectl get secret backend-secrets -o yaml

Write-Host ""
Write-Host "✅ 모든 작업 완료!" -ForegroundColor Green
Write-Host ""
Write-Host "다음 명령어로 Secret을 확인할 수 있습니다:"
Write-Host "  kubectl describe secret backend-secrets"
Write-Host ""
