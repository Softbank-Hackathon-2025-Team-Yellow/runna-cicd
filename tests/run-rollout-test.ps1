# Property-based Test Runner for Rollout Strategy Consistency
# Feature: serverless-cicd-pipeline, Property 6
# Validates: Requirements 5.3, 5.4

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Property-based Test: Rollout Strategy Consistency" -ForegroundColor Cyan
Write-Host "Feature: serverless-cicd-pipeline, Property 6" -ForegroundColor Cyan
Write-Host "Validates: Requirements 5.3, 5.4" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"
$testsPassed = 0
$testsFailed = 0

function Test-RolloutStrategy {
    param(
        [string]$Environment,
        [string]$Service,
        [string]$ExpectedStrategy
    )
    
    $valuesFile = "helm/values/values-$Service-$Environment.yaml"
    
    if (-not (Test-Path $valuesFile)) {
        Write-Host "✗ File not found: $valuesFile" -ForegroundColor Red
        return $false
    }
    
    try {
        $content = Get-Content $valuesFile -Raw
        
        # Simple regex-based extraction
        $rolloutEnabled = $false
        $actualStrategy = $null
        
        # Check if rollout is enabled
        if ($content -match 'rollout:\s*\n\s*enabled:\s*(true|false)') {
            $rolloutEnabled = $matches[1] -eq 'true'
        }
        
        # Extract strategy
        if ($content -match 'strategy:\s*(\w+)') {
            $actualStrategy = $matches[1]
        }
        
        if (-not $rolloutEnabled) {
            Write-Host "✗ Rollout not enabled for $Environment environment" -ForegroundColor Red
            return $false
        }
        
        if ($actualStrategy -eq $ExpectedStrategy) {
            Write-Host "✓ $Environment environment uses '$ExpectedStrategy' strategy" -ForegroundColor Green
            return $true
        } else {
            Write-Host "✗ $Environment environment should use '$ExpectedStrategy' but got '$actualStrategy'" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "✗ Error reading $valuesFile : $_" -ForegroundColor Red
        return $false
    }
}

# Test 1: Staging uses Canary strategy
Write-Host "Test 1: Staging environment uses Canary strategy" -ForegroundColor Yellow
if (Test-RolloutStrategy -Environment "staging" -Service "backend" -ExpectedStrategy "canary") {
    $testsPassed++
} else {
    $testsFailed++
}
Write-Host ""

# Test 2: Production uses Blue-Green strategy
Write-Host "Test 2: Production environment uses Blue-Green strategy" -ForegroundColor Yellow
if (Test-RolloutStrategy -Environment "prod" -Service "backend" -ExpectedStrategy "blueGreen") {
    $testsPassed++
} else {
    $testsFailed++
}
Write-Host ""

# Summary
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Test Summary:" -ForegroundColor Cyan
Write-Host "  Passed: $testsPassed" -ForegroundColor Green
Write-Host "  Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host "============================================================" -ForegroundColor Cyan

if ($testsFailed -gt 0) {
    Write-Host ""
    Write-Host "✗ Some tests failed" -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "✓ All tests passed!" -ForegroundColor Green
    exit 0
}
