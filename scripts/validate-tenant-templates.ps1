# Tenant Templates 검증 스크립트
# 
# 테넌트 템플릿 파일들의 유효성을 검증합니다.

param(
    [string]$UserId = "test001"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Tenant Templates 검증" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$templateDir = "k8s/tenant-templates"
$tempDir = "temp/tenant-validation"

# 임시 디렉토리 생성
if (Test-Path $tempDir) {
    Remove-Item -Recurse -Force $tempDir
}
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

Write-Host "📋 테스트 사용자 ID: $UserId" -ForegroundColor Yellow
Write-Host ""

# 테스트 결과 추적
$results = @{
    Total = 0
    Passed = 0
    Failed = 0
}

function Test-Template {
    param(
        [string]$TemplateName,
        [string]$TemplateFile
    )
    
    $results.Total++
    
    Write-Host "🔍 테스트: $TemplateName" -ForegroundColor Cyan
    
    # 1. 파일 존재 확인
    if (-not (Test-Path $TemplateFile)) {
        Write-Host "  ❌ 파일이 존재하지 않습니다: $TemplateFile" -ForegroundColor Red
        $results.Failed++
        return $false
    }
    Write-Host "  ✅ 파일 존재 확인" -ForegroundColor Green
    
    # 2. {USER_ID} 플레이스홀더 치환
    $content = Get-Content $TemplateFile -Raw
    $content = $content -replace '\{USER_ID\}', $UserId
    
    $outputFile = Join-Path $tempDir (Split-Path $TemplateFile -Leaf)
    $content | Set-Content $outputFile -Encoding UTF8
    
    Write-Host "  ✅ 플레이스홀더 치환 완료" -ForegroundColor Green
    
    # 3. YAML 문법 검증 (kubectl dry-run)
    try {
        $output = kubectl apply -f $outputFile --dry-run=client 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ YAML 문법 검증 통과" -ForegroundColor Green
        } else {
            Write-Host "  ❌ YAML 문법 오류:" -ForegroundColor Red
            Write-Host "  $output" -ForegroundColor Red
            $results.Failed++
            return $false
        }
    } catch {
        Write-Host "  ⚠️  kubectl이 설치되지 않았습니다. YAML 문법 검증 건너뜀" -ForegroundColor Yellow
    }
    
    # 4. 필수 필드 확인
    $yaml = Get-Content $outputFile -Raw
    
    # apiVersion 확인
    if ($yaml -match 'apiVersion:') {
        Write-Host "  ✅ apiVersion 필드 존재" -ForegroundColor Green
    } else {
        Write-Host "  ❌ apiVersion 필드 누락" -ForegroundColor Red
        $results.Failed++
        return $false
    }
    
    # kind 확인
    if ($yaml -match 'kind:') {
        Write-Host "  ✅ kind 필드 존재" -ForegroundColor Green
    } else {
        Write-Host "  ❌ kind 필드 누락" -ForegroundColor Red
        $results.Failed++
        return $false
    }
    
    # metadata 확인
    if ($yaml -match 'metadata:') {
        Write-Host "  ✅ metadata 필드 존재" -ForegroundColor Green
    } else {
        Write-Host "  ❌ metadata 필드 누락" -ForegroundColor Red
        $results.Failed++
        return $false
    }
    
    Write-Host "  ✅ $TemplateName 검증 완료" -ForegroundColor Green
    Write-Host ""
    
    $results.Passed++
    return $true
}

# 각 템플릿 테스트
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  템플릿 파일 검증" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Test-Template "Namespace" "$templateDir/namespace.yaml"
Test-Template "ResourceQuota" "$templateDir/resource-quota.yaml"
Test-Template "NetworkPolicy" "$templateDir/network-policy.yaml"
Test-Template "RBAC" "$templateDir/rbac.yaml"

# 결과 요약
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  검증 결과" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$passRate = if ($results.Total -gt 0) { 
    [math]::Round(($results.Passed / $results.Total) * 100, 1) 
} else { 
    0 
}

Write-Host "총 테스트: $($results.Total)" -ForegroundColor White
Write-Host "통과: $($results.Passed)" -ForegroundColor Green
Write-Host "실패: $($results.Failed)" -ForegroundColor $(if ($results.Failed -gt 0) { "Red" } else { "Green" })
Write-Host "통과율: $passRate%" -ForegroundColor $(if ($passRate -eq 100) { "Green" } else { "Yellow" })
Write-Host ""

# 생성된 파일 확인
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  생성된 파일" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Get-ChildItem $tempDir | ForEach-Object {
    Write-Host "  📄 $($_.Name)" -ForegroundColor Cyan
}
Write-Host ""

# 정리
Write-Host "🧹 임시 파일 정리 중..." -ForegroundColor Yellow
Remove-Item -Recurse -Force $tempDir

if ($results.Failed -eq 0) {
    Write-Host "✅ 모든 템플릿 검증 완료!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ 일부 템플릿 검증 실패" -ForegroundColor Red
    exit 1
}
