# 백엔드 컨테이너 실행 테스트
# Windows PowerShell 스크립트

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "백엔드 컨테이너 실행 테스트" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 이미지 존재 확인
Write-Host "1. 이미지 존재 확인..." -ForegroundColor Yellow
$imageExists = docker images -q backend-local-test:latest
if (-Not $imageExists) {
    Write-Host "❌ backend-local-test:latest 이미지를 찾을 수 없습니다." -ForegroundColor Red
    Write-Host "먼저 01-test-backend-dockerfile.ps1을 실행해주세요." -ForegroundColor Red
    exit 1
}
Write-Host "✅ 이미지 확인 완료" -ForegroundColor Green
Write-Host ""

# 2. 기존 컨테이너 정리
Write-Host "2. 기존 컨테이너 정리..." -ForegroundColor Yellow
$existingContainer = docker ps -a -q -f name=backend-test
if ($existingContainer) {
    Write-Host "   기존 컨테이너 제거 중..." -ForegroundColor Gray
    docker rm -f backend-test | Out-Null
}
Write-Host "✅ 정리 완료" -ForegroundColor Green
Write-Host ""

# 3. 환경변수 파일 생성 (테스트용)
Write-Host "3. 테스트용 환경변수 설정..." -ForegroundColor Yellow
$envContent = @"
DATABASE_URL=postgresql://test:test@localhost:5432/test_db
REDIS_HOST=localhost
REDIS_PORT=6379
SECRET_KEY=test-secret-key-for-local-testing-only
ENVIRONMENT=development
DEBUG=true
KNATIVE_URL=http://localhost:8080
"@

$envFile = "backend-repo/.env.test"
$envContent | Out-File -FilePath $envFile -Encoding UTF8
Write-Host "✅ 환경변수 파일 생성 완료" -ForegroundColor Green
Write-Host ""

# 4. 컨테이너 실행 (detached mode)
Write-Host "4. 컨테이너 실행..." -ForegroundColor Yellow
Write-Host "   포트: 8000" -ForegroundColor Gray
Write-Host "   이름: backend-test" -ForegroundColor Gray
Write-Host ""

try {
    docker run -d `
        --name backend-test `
        -p 8000:8000 `
        --env-file $envFile `
        backend-local-test:latest
    
    if ($LASTEXITCODE -ne 0) {
        throw "Container start failed"
    }
    Write-Host "✅ 컨테이너 시작 완료" -ForegroundColor Green
} catch {
    Write-Host "❌ 컨테이너 시작 실패" -ForegroundColor Red
    Write-Host "에러: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 5. 컨테이너 시작 대기
Write-Host "5. 컨테이너 시작 대기 (10초)..." -ForegroundColor Yellow
for ($i = 10; $i -gt 0; $i--) {
    Write-Host "   $i..." -NoNewline -ForegroundColor Gray
    Start-Sleep -Seconds 1
}
Write-Host ""
Write-Host "✅ 대기 완료" -ForegroundColor Green
Write-Host ""

# 6. 컨테이너 상태 확인
Write-Host "6. 컨테이너 상태 확인..." -ForegroundColor Yellow
$containerStatus = docker ps -f name=backend-test --format "{{.Status}}"
Write-Host "   상태: $containerStatus" -ForegroundColor Cyan
Write-Host ""

# 7. 컨테이너 로그 확인
Write-Host "7. 컨테이너 로그 (최근 20줄)..." -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray
docker logs --tail 20 backend-test
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host ""

# 8. Health Check 테스트
Write-Host "8. Health Check 테스트..." -ForegroundColor Yellow
Write-Host "   URL: http://localhost:8000/health" -ForegroundColor Gray

Start-Sleep -Seconds 2

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/health" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Health Check 성공!" -ForegroundColor Green
        Write-Host "   응답: $($response.Content)" -ForegroundColor Cyan
    } else {
        Write-Host "⚠️  Health Check 응답 코드: $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Health Check 실패" -ForegroundColor Red
    Write-Host "   에러: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 참고: 데이터베이스 연결이 필요한 경우 실패할 수 있습니다." -ForegroundColor Yellow
}
Write-Host ""

# 9. API 문서 접근 테스트
Write-Host "9. API 문서 접근 테스트..." -ForegroundColor Yellow
Write-Host "   URL: http://localhost:8000/docs" -ForegroundColor Gray

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/docs" -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ API 문서 접근 성공!" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  API 문서 접근 실패: $($_.Exception.Message)" -ForegroundColor Yellow
}
Write-Host ""

# 10. 컨테이너 리소스 사용량
Write-Host "10. 컨테이너 리소스 사용량..." -ForegroundColor Yellow
docker stats backend-test --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 컨테이너 테스트 완료!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 테스트 결과:" -ForegroundColor Yellow
Write-Host "  - 컨테이너 실행: ✅" -ForegroundColor Green
Write-Host "  - 포트 바인딩: 8000" -ForegroundColor Cyan
Write-Host "  - API 문서: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔧 유용한 명령어:" -ForegroundColor Yellow
Write-Host "  - 로그 확인: docker logs -f backend-test" -ForegroundColor Gray
Write-Host "  - 컨테이너 중지: docker stop backend-test" -ForegroundColor Gray
Write-Host "  - 컨테이너 제거: docker rm -f backend-test" -ForegroundColor Gray
Write-Host "  - 이미지 제거: docker rmi backend-local-test:latest" -ForegroundColor Gray
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "  - Helm Chart 검증: .\scripts\local-validation\03-test-helm-chart.ps1" -ForegroundColor Gray
Write-Host ""

# 환경변수 파일 정리
Remove-Item -Path $envFile -ErrorAction SilentlyContinue
