# Integration Test Script for CI/CD Pipeline
# This script validates the entire pipeline without requiring AWS infrastructure

Write-Host "🧪 CI/CD Pipeline Integration Test" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$ErrorCount = 0
$WarningCount = 0

# Test 1: GitHub Actions Workflow Validation
Write-Host "📋 Test 1: GitHub Actions Workflow Validation" -ForegroundColor Yellow
Write-Host "----------------------------------------------" -ForegroundColor Yellow

if (Test-Path ".github/workflows/ci-cd.yml") {
    Write-Host "✅ Workflow file exists" -ForegroundColor Green
    
    # Validate YAML syntax
    try {
        python -c "import yaml; yaml.safe_load(open('.github/workflows/ci-cd.yml', encoding='utf-8')); print('✅ YAML syntax valid')"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ YAML syntax validation failed" -ForegroundColor Red
            $ErrorCount++
        }
    } catch {
        Write-Host "❌ YAML validation error: $_" -ForegroundColor Red
        $ErrorCount++
    }
} else {
    Write-Host "❌ Workflow file not found" -ForegroundColor Red
    $ErrorCount++
}

Write-Host ""

# Test 2: Dockerfile Validation
Write-Host "📋 Test 2: Dockerfile Validation" -ForegroundColor Yellow
Write-Host "---------------------------------" -ForegroundColor Yellow

$services = @("backend", "frontend", "worker")
foreach ($service in $services) {
    $dockerfilePath = "services/$service/Dockerfile"
    if (Test-Path $dockerfilePath) {
        Write-Host "✅ $service Dockerfile exists" -ForegroundColor Green
        
        # Check for multi-stage build
        $content = Get-Content $dockerfilePath -Raw
        if ($content -match "FROM.*AS") {
            Write-Host "  ✅ Multi-stage build detected" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  No multi-stage build found" -ForegroundColor Yellow
            $WarningCount++
        }
        
        # Check for non-root user
        if ($content -match "USER") {
            Write-Host "  ✅ Non-root user configured" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  No USER directive found" -ForegroundColor Yellow
            $WarningCount++
        }
    } else {
        Write-Host "❌ $service Dockerfile not found" -ForegroundColor Red
        $ErrorCount++
    }
}

Write-Host ""

# Test 3: Helm Chart Validation
Write-Host "📋 Test 3: Helm Chart Validation" -ForegroundColor Yellow
Write-Host "---------------------------------" -ForegroundColor Yellow

if (Test-Path "helm/charts/platform-service") {
    Write-Host "✅ Helm chart directory exists" -ForegroundColor Green
    
    # Check required files
    $requiredFiles = @(
        "helm/charts/platform-service/Chart.yaml",
        "helm/charts/platform-service/values.yaml",
        "helm/charts/platform-service/templates/deployment.yaml",
        "helm/charts/platform-service/templates/service.yaml",
        "helm/charts/platform-service/templates/ingress.yaml",
        "helm/charts/platform-service/templates/rollout.yaml"
    )
    
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-Host "  ✅ $(Split-Path $file -Leaf) exists" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $(Split-Path $file -Leaf) missing" -ForegroundColor Red
            $ErrorCount++
        }
    }
    
    # Validate Helm chart structure
    Write-Host "  Running Helm validation..." -ForegroundColor Cyan
    python scripts/validate-helm-structure.py
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Helm validation failed" -ForegroundColor Red
        $ErrorCount++
    }
} else {
    Write-Host "❌ Helm chart directory not found" -ForegroundColor Red
    $ErrorCount++
}

Write-Host ""

# Test 4: Helm Values Files Validation
Write-Host "📋 Test 4: Helm Values Files Validation" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

$environments = @("dev", "staging", "prod")
foreach ($env in $environments) {
    $valuesFile = "helm/values/values-backend-$env.yaml"
    if (Test-Path $valuesFile) {
        Write-Host "✅ $env values file exists" -ForegroundColor Green
        
        # Validate YAML syntax
        try {
            python -c "import yaml; yaml.safe_load(open('$valuesFile', encoding='utf-8'))"
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✅ YAML syntax valid" -ForegroundColor Green
            } else {
                Write-Host "  ❌ YAML syntax invalid" -ForegroundColor Red
                $ErrorCount++
            }
        } catch {
            Write-Host "  ❌ YAML validation error" -ForegroundColor Red
            $ErrorCount++
        }
    } else {
        Write-Host "❌ $env values file not found" -ForegroundColor Red
        $ErrorCount++
    }
}

Write-Host ""

# Test 5: ArgoCD Application Validation
Write-Host "📋 Test 5: ArgoCD Application Validation" -ForegroundColor Yellow
Write-Host "-----------------------------------------" -ForegroundColor Yellow

$argocdFiles = @(
    "argocd/root-app.yaml",
    "argocd/applications/backend-dev.yaml",
    "argocd/applications/backend-staging.yaml"
)

foreach ($file in $argocdFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $(Split-Path $file -Leaf) exists" -ForegroundColor Green
        
        # Validate YAML syntax
        try {
            python -c "import yaml; yaml.safe_load(open('$file', encoding='utf-8'))"
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✅ YAML syntax valid" -ForegroundColor Green
            } else {
                Write-Host "  ❌ YAML syntax invalid" -ForegroundColor Red
                $ErrorCount++
            }
        } catch {
            Write-Host "  ❌ YAML validation error" -ForegroundColor Red
            $ErrorCount++
        }
    } else {
        Write-Host "❌ $(Split-Path $file -Leaf) not found" -ForegroundColor Red
        $ErrorCount++
    }
}

Write-Host ""

# Test 6: Argo Rollouts Configuration
Write-Host "📋 Test 6: Argo Rollouts Configuration" -ForegroundColor Yellow
Write-Host "---------------------------------------" -ForegroundColor Yellow

if (Test-Path "argocd/analysis-templates/success-rate.yaml") {
    Write-Host "✅ AnalysisTemplate exists" -ForegroundColor Green
} else {
    Write-Host "❌ AnalysisTemplate not found" -ForegroundColor Red
    $ErrorCount++
}

# Run rollout configuration test
Write-Host "  Running Rollout configuration test..." -ForegroundColor Cyan
python tests/test_rollout_configuration.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ Rollout configuration test failed" -ForegroundColor Red
    $ErrorCount++
}

Write-Host ""

# Test 7: Property-Based Tests
Write-Host "📋 Test 7: Property-Based Tests" -ForegroundColor Yellow
Write-Host "--------------------------------" -ForegroundColor Yellow

Write-Host "  Running image tag uniqueness test..." -ForegroundColor Cyan
python tests/test_image_tag_uniqueness.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ Image tag test failed" -ForegroundColor Red
    $ErrorCount++
} else {
    Write-Host "  ✅ Image tag test passed" -ForegroundColor Green
}

Write-Host "  Running Helm values update test..." -ForegroundColor Cyan
python tests/test_helm_values_update.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ Helm values test failed" -ForegroundColor Red
    $ErrorCount++
} else {
    Write-Host "  ✅ Helm values test passed" -ForegroundColor Green
}

Write-Host "  Running rollout strategy test..." -ForegroundColor Cyan
python tests/test_rollout_strategy.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ Rollout strategy test failed" -ForegroundColor Red
    $ErrorCount++
} else {
    Write-Host "  ✅ Rollout strategy test passed" -ForegroundColor Green
}

Write-Host ""

# Test 8: Error Handling Validation
Write-Host "📋 Test 8: Error Handling Validation" -ForegroundColor Yellow
Write-Host "-------------------------------------" -ForegroundColor Yellow

Write-Host "  Running error handling validation..." -ForegroundColor Cyan
python scripts/validate-error-handling.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ Error handling validation failed" -ForegroundColor Red
    $ErrorCount++
} else {
    Write-Host "  ✅ Error handling validation passed" -ForegroundColor Green
}

Write-Host ""

# Test 9: Documentation Check
Write-Host "📋 Test 9: Documentation Check" -ForegroundColor Yellow
Write-Host "-------------------------------" -ForegroundColor Yellow

$docFiles = @(
    "README.md",
    ".gitignore",
    "docs/helm-validation.md",
    "docs/argo-rollouts-config.md",
    "docs/argocd-dryrun-testing.md"
)

foreach ($file in $docFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $(Split-Path $file -Leaf) exists" -ForegroundColor Green
    } else {
        Write-Host "⚠️  $(Split-Path $file -Leaf) missing" -ForegroundColor Yellow
        $WarningCount++
    }
}

Write-Host ""

# Final Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📊 Integration Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($ErrorCount -eq 0 -and $WarningCount -eq 0) {
    Write-Host "✅ All tests passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎉 CI/CD Pipeline is ready for deployment!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Commit your changes: git add . && git commit -m 'Complete CI/CD pipeline implementation'" -ForegroundColor White
    Write-Host "  2. Coordinate with team members to merge code" -ForegroundColor White
    Write-Host "  3. Set up AWS infrastructure (EKS, ECR, IAM)" -ForegroundColor White
    Write-Host "  4. Install ArgoCD and Argo Rollouts on cluster" -ForegroundColor White
    Write-Host "  5. Configure GitHub Secrets (AWS_ROLE_ARN)" -ForegroundColor White
    Write-Host "  6. Push to GitHub to trigger the pipeline" -ForegroundColor White
    exit 0
} elseif ($ErrorCount -eq 0) {
    Write-Host "⚠️  Tests passed with $WarningCount warning(s)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "The pipeline is functional but has some warnings." -ForegroundColor Yellow
    Write-Host "Review the warnings above before proceeding." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "❌ Tests failed with $ErrorCount error(s) and $WarningCount warning(s)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please fix the errors above before proceeding." -ForegroundColor Red
    exit 1
}
