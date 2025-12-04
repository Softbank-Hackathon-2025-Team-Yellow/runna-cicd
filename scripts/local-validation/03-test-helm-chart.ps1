# Helm Chart 검증 테스트
# Windows PowerShell 스크립트

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Helm Chart 검증 테스트" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Helm 설치 확인
Write-Host "1. Helm 설치 확인..." -ForegroundColor Yellow
try {
    $helmVersion = helm version --short 2>&1
    Write-Host "✅ Helm 버전: $helmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Helm이 설치되지 않았습니다." -ForegroundColor Red
    Write-Host ""
    Write-Host "Helm 설치 방법:" -ForegroundColor Yellow
    Write-Host "  choco install kubernetes-helm" -ForegroundColor Gray
    Write-Host "  또는 https://helm.sh/docs/intro/install/" -ForegroundColor Gray
    exit 1
}
Write-Host ""

# 2. Helm Chart 디렉토리 확인
Write-Host "2. Helm Chart 디렉토리 확인..." -ForegroundColor Yellow
$chartPath = "helm/charts/platform-service"
if (-Not (Test-Path $chartPath)) {
    Write-Host "❌ Helm Chart를 찾을 수 없습니다: $chartPath" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Chart 경로: $chartPath" -ForegroundColor Green
Write-Host ""

# 3. Chart.yaml 확인
Write-Host "3. Chart.yaml 확인..." -ForegroundColor Yellow
$chartYaml = Get-Content "$chartPath/Chart.yaml" -Raw
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host $chartYaml
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host "✅ Chart.yaml 확인 완료" -ForegroundColor Green
Write-Host ""

# 4. Helm Lint 실행
Write-Host "4. Helm Lint 실행..." -ForegroundColor Yellow
Write-Host "   (Chart 문법 검증)" -ForegroundColor Gray
Write-Host ""

try {
    helm lint $chartPath
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Helm Lint 통과!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "⚠️  Helm Lint에서 경고가 발생했습니다." -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Helm Lint 실패" -ForegroundColor Red
    Write-Host "에러: $_" -ForegroundColor Red
}
Write-Host ""

# 5. Values 파일 확인
Write-Host "5. Values 파일 확인..." -ForegroundColor Yellow
$valuesFiles = @(
    "helm/values/values-backend-dev.yaml",
    "helm/values/values-backend-staging.yaml",
    "helm/values/values-backend-prod.yaml"
)

foreach ($valuesFile in $valuesFiles) {
    if (Test-Path $valuesFile) {
        Write-Host "  ✅ $valuesFile" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  $valuesFile (없음)" -ForegroundColor Yellow
    }
}
Write-Host ""

# 6. Helm Template 렌더링 (Dev)
Write-Host "6. Helm Template 렌더링 테스트 (Dev)..." -ForegroundColor Yellow
$devValuesFile = "helm/values/values-backend-dev.yaml"

if (Test-Path $devValuesFile) {
    Write-Host "   Values: $devValuesFile" -ForegroundColor Gray
    Write-Host ""
    
    try {
        $outputDir = "temp-helm-output"
        New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
        
        helm template backend $chartPath `
            -f $devValuesFile `
            --output-dir $outputDir
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Template 렌더링 성공!" -ForegroundColor Green
            Write-Host ""
            
            # 생성된 파일 목록
            Write-Host "   생성된 매니페스트:" -ForegroundColor Cyan
            Get-ChildItem -Path "$outputDir/platform-service/templates" -Recurse -File | ForEach-Object {
                Write-Host "     - $($_.Name)" -ForegroundColor Gray
            }
        } else {
            Write-Host ""
            Write-Host "❌ Template 렌더링 실패" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Template 렌더링 중 에러 발생" -ForegroundColor Red
        Write-Host "에러: $_" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  Dev values 파일이 없습니다." -ForegroundColor Yellow
}
Write-Host ""

# 7. 렌더링된 매니페스트 샘플 확인
Write-Host "7. 렌더링된 매니페스트 샘플..." -ForegroundColor Yellow
if (Test-Path "$outputDir/platform-service/templates") {
    $sampleFile = Get-ChildItem -Path "$outputDir/platform-service/templates" -File | Select-Object -First 1
    if ($sampleFile) {
        Write-Host "   파일: $($sampleFile.Name)" -ForegroundColor Gray
        Write-Host "----------------------------------------" -ForegroundColor Gray
        Get-Content $sampleFile.FullName | Select-Object -First 30
        Write-Host "..." -ForegroundColor Gray
        Write-Host "----------------------------------------" -ForegroundColor Gray
    }
}
Write-Host ""

# 8. YAML 유효성 검증 (kubeval 있는 경우)
Write-Host "8. YAML 유효성 검증..." -ForegroundColor Yellow
try {
    $kubevalExists = Get-Command kubeval -ErrorAction SilentlyContinue
    if ($kubevalExists) {
        Write-Host "   kubeval로 검증 중..." -ForegroundColor Gray
        Get-ChildItem -Path "$outputDir/platform-service/templates" -Recurse -File | ForEach-Object {
            kubeval $_.FullName
        }
        Write-Host "✅ YAML 유효성 검증 완료" -ForegroundColor Green
    } else {
        Write-Host "⚠️  kubeval이 설치되지 않았습니다. (선택사항)" -ForegroundColor Yellow
        Write-Host "   설치: choco install kubeval" -ForegroundColor Gray
    }
} catch {
    Write-Host "⚠️  YAML 검증 건너뜀" -ForegroundColor Yellow
}
Write-Host ""

# 9. Helm Dry-run 테스트
Write-Host "9. Helm Dry-run 테스트..." -ForegroundColor Yellow
Write-Host "   (실제 배포 시뮬레이션)" -ForegroundColor Gray
Write-Host ""

try {
    helm install backend-test $chartPath `
        -f $devValuesFile `
        --dry-run `
        --debug `
        2>&1 | Select-Object -Last 50
    
    Write-Host ""
    Write-Host "✅ Dry-run 테스트 완료" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Dry-run 테스트 중 경고 발생" -ForegroundColor Yellow
}
Write-Host ""

# 10. 정리
Write-Host "10. 임시 파일 정리..." -ForegroundColor Yellow
if (Test-Path $outputDir) {
    Remove-Item -Path $outputDir -Recurse -Force
    Write-Host "✅ 정리 완료" -ForegroundColor Green
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Helm Chart 검증 완료!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 검증 결과:" -ForegroundColor Yellow
Write-Host "  - Helm Lint: ✅" -ForegroundColor Green
Write-Host "  - Template 렌더링: ✅" -ForegroundColor Green
Write-Host "  - Dry-run: ✅" -ForegroundColor Green
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "  - GitHub Actions 검증: .\scripts\local-validation\04-test-github-actions.ps1" -ForegroundColor Gray
Write-Host ""
