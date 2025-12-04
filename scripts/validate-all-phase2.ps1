# Phase 2 Validation Script

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Phase 2 Validation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$totalTests = 0
$passedTests = 0
$failedTests = 0

# 1. K8s Secret Template
Write-Host "1. K8s Secret Template" -ForegroundColor Cyan
$totalTests++
if (Test-Path "k8s/secrets/backend-secrets-template.yaml") {
    Write-Host "  [PASS] backend-secrets-template.yaml exists" -ForegroundColor Green
    $passedTests++
} else {
    Write-Host "  [FAIL] backend-secrets-template.yaml not found" -ForegroundColor Red
    $failedTests++
}

# 2. ArgoCD Applications
Write-Host ""
Write-Host "2. ArgoCD Applications" -ForegroundColor Cyan

$argocdApps = @(
    "argocd/applications/backend-dev.yaml",
    "argocd/applications/backend-staging.yaml",
    "argocd/applications/backend-prod.yaml"
)

foreach ($app in $argocdApps) {
    $totalTests++
    if (Test-Path $app) {
        Write-Host "  [PASS] $(Split-Path $app -Leaf) exists" -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  [FAIL] $(Split-Path $app -Leaf) not found" -ForegroundColor Red
        $failedTests++
    }
}

# 3. Tenant Templates
Write-Host ""
Write-Host "3. Tenant Templates" -ForegroundColor Cyan

$tenantTemplates = @(
    "k8s/tenant-templates/namespace.yaml",
    "k8s/tenant-templates/resource-quota.yaml",
    "k8s/tenant-templates/network-policy.yaml",
    "k8s/tenant-templates/rbac.yaml"
)

foreach ($template in $tenantTemplates) {
    $totalTests++
    if (Test-Path $template) {
        Write-Host "  [PASS] $(Split-Path $template -Leaf) exists" -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  [FAIL] $(Split-Path $template -Leaf) not found" -ForegroundColor Red
        $failedTests++
    }
}

# 4. Documentation
Write-Host ""
Write-Host "4. Documentation" -ForegroundColor Cyan

$docs = @(
    "docs/PHASE1-COMPLETE.md",
    "docs/PHASE2-READY.md",
    "docs/PHASE3-MULTITENANCY-DESIGN.md"
)

foreach ($doc in $docs) {
    $totalTests++
    if (Test-Path $doc) {
        Write-Host "  [PASS] $(Split-Path $doc -Leaf) exists" -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "  [FAIL] $(Split-Path $doc -Leaf) not found" -ForegroundColor Red
        $failedTests++
    }
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$passRate = if ($totalTests -gt 0) { 
    [math]::Round(($passedTests / $totalTests) * 100, 1) 
} else { 
    0 
}

Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -eq 100) { "Green" } else { "Yellow" })
Write-Host ""

if ($failedTests -eq 0) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Phase 2 Ready!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Wait for infrastructure provisioning" -ForegroundColor White
    Write-Host "  2. Get K8s cluster access" -ForegroundColor White
    Write-Host "  3. Update Secrets with real values" -ForegroundColor White
    Write-Host "  4. Deploy ArgoCD Applications" -ForegroundColor White
    Write-Host "  5. Test first deployment" -ForegroundColor White
    Write-Host ""
    Write-Host "Documentation:" -ForegroundColor Cyan
    Write-Host "  - docs/PHASE1-COMPLETE.md" -ForegroundColor White
    Write-Host "  - docs/PHASE2-READY.md" -ForegroundColor White
    Write-Host "  - docs/PHASE3-MULTITENANCY-DESIGN.md" -ForegroundColor White
    Write-Host ""
    exit 0
} else {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  Some Tests Failed" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check the failed items above." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
