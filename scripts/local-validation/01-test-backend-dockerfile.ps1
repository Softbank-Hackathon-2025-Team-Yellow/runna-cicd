# 백엔드 Dockerfile 로컬 빌드 테스트
# Windows PowerShell 스크립트

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "백엔드 Dockerfile 빌드 테스트" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 백엔드 디렉토리 확인
Write-Host "1. 백엔드 디렉토리 확인..." -ForegroundColor Yellow
if (-Not (Test-Path "backend-repo")) {
    Write-Host "❌ backend-repo 디렉토리를 찾을 수 없습니다." -ForegroundColor Red
    Write-Host "현재 위치: $(Get-Location)" -ForegroundColor Red
    exit 1
}
Write-Host "✅ backend-repo 디렉토리 확인 완료" -ForegroundColor Green
Write-Host ""

# 2. Dockerfile 존재 확인
Write-Host "2. Dockerfile 존재 확인..." -ForegroundColor Yellow
if (-Not (Test-Path "backend-repo/Dockerfile")) {
    Write-Host "❌ Dockerfile을 찾을 수 없습니다." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dockerfile 확인 완료" -ForegroundColor Green
Write-Host ""

# 3. Docker 실행 확인
Write-Host "3. Docker 실행 상태 확인..." -ForegroundColor Yellow
try {
    docker version | Out-Null
    Write-Host "✅ Docker가 실행 중입니다." -ForegroundColor Green
} catch {
    Write-Host "❌ Docker가 실행되지 않았습니다. Docker Desktop을 시작해주세요." -ForegroundColor Red
    exit 1
}
Write-Host ""

# 4. 이미지 빌드
Write-Host "4. Docker 이미지 빌드 시작..." -ForegroundColor Yellow
Write-Host "   (이 작업은 몇 분 정도 걸릴 수 있습니다)" -ForegroundColor Gray
Write-Host ""

$buildStart = Get-Date
try {
    docker build -t backend-local-test:latest ./backend-repo
    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed"
    }
    $buildEnd = Get-Date
    $buildDuration = ($buildEnd - $buildStart).TotalSeconds
    Write-Host ""
    Write-Host "✅ 이미지 빌드 성공! (소요 시간: $([math]::Round($buildDuration, 2))초)" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "❌ 이미지 빌드 실패" -ForegroundColor Red
    Write-Host "에러: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 5. 빌드된 이미지 확인
Write-Host "5. 빌드된 이미지 확인..." -ForegroundColor Yellow
docker images backend-local-test:latest
Write-Host ""

# 6. 이미지 크기 확인
$imageSize = docker images backend-local-test:latest --format "{{.Size}}"
Write-Host "📦 이미지 크기: $imageSize" -ForegroundColor Cyan
Write-Host ""

# 7. 이미지 레이어 확인
Write-Host "7. 이미지 레이어 정보..." -ForegroundColor Yellow
docker history backend-local-test:latest --no-trunc | Select-Object -First 10
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Dockerfile 검증 완료!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "  - 컨테이너 실행 테스트: .\scripts\local-validation\02-test-backend-container.ps1" -ForegroundColor Gray
Write-Host ""
