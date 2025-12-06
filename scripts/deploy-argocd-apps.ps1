# ArgoCD Applications 배포 스크립트
# Usage: .\scripts\deploy-argocd-apps.ps1

Write-Host "=== ArgoCD Applications 배포 시작 ===" -ForegroundColor Green
Write-Host ""

# 1. Root App 배포
Write-Host "1. Root Application 배포 중..." -ForegroundColor Cyan
kubectl apply -f argocd/root-app.yaml

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Root Application 배포 완료" -ForegroundColor Green
} else {
    Write-Host "❌ Root Application 배포 실패" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "2. Applications 생성 대기 중 (10초)..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# 2. Applications 확인
Write-Host ""
Write-Host "3. 생성된 Applications 확인:" -ForegroundColor Cyan
kubectl get applications -n argocd

Write-Host ""
Write-Host "4. Applications 상세 상태:" -ForegroundColor Cyan
kubectl get applications -n argocd -o wide

Write-Host ""
Write-Host "=== 배포 완료 ===" -ForegroundColor Green
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "1. ArgoCD UI 확인: https://argocd.haifu.cloud/applications"
Write-Host "2. Applications 동기화 상태 확인"
Write-Host "3. 필요시 수동 Sync 실행"
Write-Host ""
