# Docker Hub Secret 생성 스크립트 (PowerShell)
# K8s에 Docker Hub 인증 정보를 저장합니다.

param(
    [Parameter(Mandatory=$false)]
    [string]$Username = $env:DOCKERHUB_USERNAME,
    
    [Parameter(Mandatory=$false)]
    [string]$Token = $env:DOCKERHUB_TOKEN,
    
    [Parameter(Mandatory=$false)]
    [string]$Email = $env:DOCKERHUB_EMAIL,
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "default"
)

Write-Host "🐳 Docker Hub Secret 설정 스크립트" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# 환경 변수 확인
if ([string]::IsNullOrEmpty($Username)) {
    Write-Host "❌ DOCKERHUB_USERNAME이 설정되지 않았습니다." -ForegroundColor Red
    Write-Host "사용법: " -ForegroundColor Yellow
    Write-Host "  `$env:DOCKERHUB_USERNAME='your-username'" -ForegroundColor White
    Write-Host "  `$env:DOCKERHUB_TOKEN='your-token'" -ForegroundColor White
    Write-Host "  .\setup-dockerhub-secret.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "또는:" -ForegroundColor Yellow
    Write-Host "  .\setup-dockerhub-secret.ps1 -Username 'your-username' -Token 'your-token'" -ForegroundColor White
    exit 1
}

if ([string]::IsNullOrEmpty($Token)) {
    Write-Host "❌ DOCKERHUB_TOKEN이 설정되지 않았습니다." -ForegroundColor Red
    Write-Host "사용법: " -ForegroundColor Yellow
    Write-Host "  `$env:DOCKERHUB_USERNAME='your-username'" -ForegroundColor White
    Write-Host "  `$env:DOCKERHUB_TOKEN='your-token'" -ForegroundColor White
    Write-Host "  .\setup-dockerhub-secret.ps1" -ForegroundColor White
    exit 1
}

if ([string]::IsNullOrEmpty($Email)) {
    Write-Host "⚠️  DOCKERHUB_EMAIL이 설정되지 않았습니다. 기본값을 사용합니다." -ForegroundColor Yellow
    $Email = "${Username}@example.com"
}

Write-Host "📋 설정 정보:" -ForegroundColor Green
Write-Host "   Username: $Username" -ForegroundColor White
Write-Host "   Email: $Email" -ForegroundColor White
Write-Host "   Token: $($Token.Substring(0, [Math]::Min(10, $Token.Length)))..." -ForegroundColor White
Write-Host "   Namespace: $Namespace" -ForegroundColor White
Write-Host ""

# kubectl 설치 확인
try {
    $null = kubectl version --client 2>&1
    Write-Host "✅ kubectl 설치 확인 완료" -ForegroundColor Green
} catch {
    Write-Host "❌ kubectl이 설치되지 않았습니다." -ForegroundColor Red
    Write-Host "kubectl을 설치한 후 다시 실행해주세요." -ForegroundColor Yellow
    Write-Host "설치: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/" -ForegroundColor Cyan
    exit 1
}

# K8s 클러스터 연결 확인
try {
    $null = kubectl cluster-info 2>&1
    Write-Host "✅ Kubernetes 클러스터 연결 확인 완료" -ForegroundColor Green
} catch {
    Write-Host "❌ Kubernetes 클러스터에 연결할 수 없습니다." -ForegroundColor Red
    Write-Host "kubeconfig가 올바르게 설정되었는지 확인해주세요." -ForegroundColor Yellow
    exit 1
}

# 기존 Secret 확인
Write-Host ""
Write-Host "🔍 기존 dockerhub-secret 확인 중..." -ForegroundColor Cyan
$secretExists = kubectl get secret dockerhub-secret -n $Namespace 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "⚠️  기존 dockerhub-secret이 존재합니다. 삭제 후 재생성합니다." -ForegroundColor Yellow
    kubectl delete secret dockerhub-secret -n $Namespace
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 기존 Secret 삭제 완료" -ForegroundColor Green
    } else {
        Write-Host "❌ Secret 삭제 실패" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "ℹ️  기존 Secret이 없습니다. 새로 생성합니다." -ForegroundColor Cyan
}

# Docker Hub Secret 생성
Write-Host ""
Write-Host "🔐 Docker Hub Secret 생성 중..." -ForegroundColor Cyan
kubectl create secret docker-registry dockerhub-secret `
    --docker-server=docker.io `
    --docker-username="$Username" `
    --docker-password="$Token" `
    --docker-email="$Email" `
    --namespace="$Namespace"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ dockerhub-secret 생성 완료!" -ForegroundColor Green
} else {
    Write-Host "❌ Secret 생성 실패" -ForegroundColor Red
    exit 1
}

# Secret 확인
Write-Host ""
Write-Host "🔍 생성된 Secret 확인:" -ForegroundColor Cyan
kubectl get secret dockerhub-secret -n $Namespace -o yaml | Select-String "name:|type:|data:"

Write-Host ""
Write-Host "🎉 Docker Hub Secret 설정 완료!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 다음 단계:" -ForegroundColor Yellow
Write-Host "1. Helm Values 파일에서 YOUR_DOCKERHUB_USERNAME을 실제 username으로 변경" -ForegroundColor White
Write-Host "   - helm/values/values-backend-dev.yaml" -ForegroundColor Gray
Write-Host "   - helm/values/values-backend-staging.yaml" -ForegroundColor Gray
Write-Host "   - helm/values/values-backend-prod.yaml" -ForegroundColor Gray
Write-Host ""
Write-Host "2. GitHub Actions에서 DOCKERHUB_USERNAME, DOCKERHUB_TOKEN Secrets 설정 확인" -ForegroundColor White
Write-Host "   - GitHub Repository → Settings → Secrets and variables → Actions" -ForegroundColor Gray
Write-Host ""
Write-Host "3. 코드 푸시하여 CI/CD 파이프라인 테스트" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'feat: migrate from ECR to Docker Hub'" -ForegroundColor Gray
Write-Host "   git push origin main" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 참고:" -ForegroundColor Cyan
Write-Host "   - Secret 이름: dockerhub-secret" -ForegroundColor White
Write-Host "   - Namespace: $Namespace" -ForegroundColor White
Write-Host "   - 다른 Namespace에서 사용하려면 -Namespace 옵션 사용" -ForegroundColor White
Write-Host ""
