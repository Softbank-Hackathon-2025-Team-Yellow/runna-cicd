# Docker Hub 전환 - 실행 명령어 모음
# 이 파일을 참고해서 하나씩 실행하세요!

Write-Host "🚀 Docker Hub 전환 명령어 가이드" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📝 Step 1: Docker Hub Username 변경" -ForegroundColor Yellow
Write-Host "-----------------------------------" -ForegroundColor Yellow
Write-Host "다음 명령어를 실행하세요 (YOUR_USERNAME을 실제 username으로 변경):" -ForegroundColor White
Write-Host ""
Write-Host 'Get-ChildItem helm/values -Filter "*.yaml" | ForEach-Object {' -ForegroundColor Green
Write-Host '    (Get-Content $_.FullName) -replace ''YOUR_DOCKERHUB_USERNAME'', ''YOUR_USERNAME'' | Set-Content $_.FullName' -ForegroundColor Green
Write-Host '}' -ForegroundColor Green
Write-Host ""
Write-Host "예시 (username이 seoyoung123인 경우):" -ForegroundColor Gray
Write-Host 'Get-ChildItem helm/values -Filter "*.yaml" | ForEach-Object {' -ForegroundColor Cyan
Write-Host '    (Get-Content $_.FullName) -replace ''YOUR_DOCKERHUB_USERNAME'', ''seoyoung123'' | Set-Content $_.FullName' -ForegroundColor Cyan
Write-Host '}' -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""

Write-Host "📝 Step 2: Docker Hub Access Token 생성" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Yellow
Write-Host "1. https://hub.docker.com 로그인" -ForegroundColor White
Write-Host "2. Account Settings → Security → New Access Token" -ForegroundColor White
Write-Host "3. Token 이름 입력 (예: k8s-deployment)" -ForegroundColor White
Write-Host "4. 생성된 Token 복사 (한 번만 보여줌!)" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""

Write-Host "📝 Step 3: K8s Secret 생성" -ForegroundColor Yellow
Write-Host "--------------------------" -ForegroundColor Yellow
Write-Host "먼저 소현님께 kubeconfig 파일을 받으세요!" -ForegroundColor Red
Write-Host ""
Write-Host "kubeconfig 받은 후 다음 명령어 실행:" -ForegroundColor White
Write-Host ""
Write-Host '# 환경 변수 설정' -ForegroundColor Green
Write-Host '$env:DOCKERHUB_USERNAME = "your-username"' -ForegroundColor Green
Write-Host '$env:DOCKERHUB_TOKEN = "dckr_pat_xxxxxxxxxxxxx"' -ForegroundColor Green
Write-Host '$env:DOCKERHUB_EMAIL = "your-email@example.com"  # 선택사항' -ForegroundColor Green
Write-Host ""
Write-Host '# Secret 생성 스크립트 실행' -ForegroundColor Green
Write-Host '.\scripts\setup-dockerhub-secret.ps1' -ForegroundColor Green
Write-Host ""
Write-Host "또는 파라미터로 직접 전달:" -ForegroundColor Gray
Write-Host '.\scripts\setup-dockerhub-secret.ps1 -Username "your-username" -Token "dckr_pat_xxxxx"' -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""

Write-Host "📝 Step 4: GitHub Secrets 설정" -ForegroundColor Yellow
Write-Host "------------------------------" -ForegroundColor Yellow
Write-Host "GitHub Repository에서:" -ForegroundColor White
Write-Host "1. Settings → Secrets and variables → Actions" -ForegroundColor White
Write-Host "2. New repository secret 클릭" -ForegroundColor White
Write-Host "3. 다음 2개 추가:" -ForegroundColor White
Write-Host "   - Name: DOCKERHUB_USERNAME" -ForegroundColor Cyan
Write-Host "     Value: your-username" -ForegroundColor Cyan
Write-Host "   - Name: DOCKERHUB_TOKEN" -ForegroundColor Cyan
Write-Host "     Value: dckr_pat_xxxxxxxxxxxxx" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""

Write-Host "📝 Step 5: 변경사항 커밋 및 푸시" -ForegroundColor Yellow
Write-Host "--------------------------------" -ForegroundColor Yellow
Write-Host "다음 명령어를 실행하세요:" -ForegroundColor White
Write-Host ""
Write-Host 'git add .' -ForegroundColor Green
Write-Host 'git commit -m "feat: migrate from ECR to Docker Hub"' -ForegroundColor Green
Write-Host 'git push origin main' -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host ""

Write-Host "📝 Step 6: 확인" -ForegroundColor Yellow
Write-Host "---------------" -ForegroundColor Yellow
Write-Host "1. GitHub Actions 확인:" -ForegroundColor White
Write-Host "   - GitHub → Actions 탭" -ForegroundColor Gray
Write-Host "   - 최신 워크플로우 실행 확인" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Docker Hub 확인:" -ForegroundColor White
Write-Host "   - https://hub.docker.com" -ForegroundColor Gray
Write-Host "   - Repositories → backend" -ForegroundColor Gray
Write-Host ""
Write-Host "3. K8s Pod 확인:" -ForegroundColor White
Write-Host "   kubectl get pods" -ForegroundColor Cyan
Write-Host "   kubectl describe pod <pod-name>" -ForegroundColor Cyan
Write-Host ""

Write-Host "✅ 모든 단계 완료!" -ForegroundColor Green
Write-Host ""
Write-Host "🆘 문제 발생 시:" -ForegroundColor Red
Write-Host "   - docs/DOCKER-HUB-SETUP.md 참고" -ForegroundColor White
Write-Host "   - DOCKER-HUB-QUICK-START.md 참고" -ForegroundColor White
Write-Host ""
