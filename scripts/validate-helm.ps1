# Helm Chart Validation Script
# This script validates Helm charts using helm lint and helm template
# Requirements: 7.2, 7.3

param(
    [Parameter(Mandatory=$false)]
    [string]$ChartPath = "helm/charts/platform-service",
    
    [Parameter(Mandatory=$false)]
    [string]$ValuesPath = ""
)

Write-Host "=== Helm Chart Validation ===" -ForegroundColor Cyan
Write-Host ""

# Check if helm is installed
try {
    $helmVersion = helm version --short 2>$null
    Write-Host "✓ Helm installed: $helmVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Helm is not installed. Please install Helm first." -ForegroundColor Red
    Write-Host "  Download from: https://helm.sh/docs/intro/install/" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "--- Step 1: Helm Lint (Syntax Validation) ---" -ForegroundColor Yellow
Write-Host "Checking chart: $ChartPath"
Write-Host ""

# Run helm lint
if ($ValuesPath -ne "") {
    helm lint $ChartPath -f $ValuesPath
} else {
    helm lint $ChartPath
}

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "✗ Helm lint failed with errors" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✓ Helm lint passed - no syntax errors found" -ForegroundColor Green
Write-Host ""

Write-Host "--- Step 2: Helm Template (Rendering Test) ---" -ForegroundColor Yellow
Write-Host "Rendering templates to verify output..."
Write-Host ""

# Run helm template
$templateOutput = ""
if ($ValuesPath -ne "") {
    $templateOutput = helm template test-release $ChartPath -f $ValuesPath 2>&1
} else {
    $templateOutput = helm template test-release $ChartPath 2>&1
}

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "✗ Helm template rendering failed" -ForegroundColor Red
    Write-Host $templateOutput
    exit 1
}

Write-Host "✓ Helm template rendering successful" -ForegroundColor Green
Write-Host ""
Write-Host "--- Rendered Manifests Preview ---" -ForegroundColor Cyan
Write-Host $templateOutput
Write-Host ""

Write-Host "=== Validation Complete ===" -ForegroundColor Green
Write-Host "✓ Chart syntax is valid (helm lint)" -ForegroundColor Green
Write-Host "✓ Templates render correctly (helm template)" -ForegroundColor Green
Write-Host ""
Write-Host "Requirements validated: 7.2, 7.3" -ForegroundColor Cyan
