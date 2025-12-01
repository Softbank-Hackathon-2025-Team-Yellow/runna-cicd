# ArgoCD Dry-Run Simulation Test
# This script simulates ArgoCD dry-run testing by validating application manifests
# and checking if they would be successfully applied

Write-Host "=== ArgoCD Dry-Run Simulation Test ===" -ForegroundColor Cyan
Write-Host ""

$errorList = @()
$warningList = @()
$applications = @(
    "argocd/applications/backend-dev.yaml",
    "argocd/applications/backend-staging.yaml"
)
$rootApp = "argocd/root-app.yaml"

# Function to validate YAML structure
function Test-YamlStructure {
    param($filePath)
    
    if (-not (Test-Path $filePath)) {
        return $false
    }
    
    $content = Get-Content $filePath -Raw
    
    # Basic YAML validation
    if ($content -match "apiVersion:\s*argoproj\.io/v1alpha1" -and
        $content -match "kind:\s*Application" -and
        $content -match "metadata:" -and
        $content -match "spec:") {
        return $true
    }
    
    return $false
}

# Function to validate ArgoCD Application spec
function Test-ApplicationSpec {
    param($filePath)
    
    $content = Get-Content $filePath -Raw
    $issues = @()
    
    # Check required fields
    if (-not ($content -match "project:\s*\w+")) {
        $issues += "Missing 'project' field"
    }
    
    if (-not ($content -match "source:")) {
        $issues += "Missing 'source' section"
    } else {
        if (-not ($content -match "repoURL:\s*https?://")) {
            $issues += "Missing or invalid 'repoURL'"
        }
        if (-not ($content -match "targetRevision:\s*\w+")) {
            $issues += "Missing 'targetRevision'"
        }
        if (-not ($content -match "path:\s*[\w/\-]+")) {
            $issues += "Missing 'path'"
        }
    }
    
    if (-not ($content -match "destination:")) {
        $issues += "Missing 'destination' section"
    } else {
        if (-not ($content -match "server:\s*https?://")) {
            $issues += "Missing or invalid 'server'"
        }
        if (-not ($content -match "namespace:\s*\w+")) {
            $issues += "Missing 'namespace'"
        }
    }
    
    return $issues
}

# Function to validate Helm values file reference
function Test-HelmValuesReference {
    param($appFilePath)
    
    $content = Get-Content $appFilePath -Raw
    $issues = @()
    
    if ($content -match "helm:") {
        if ($content -match "valueFiles:\s*\n\s*-\s*(.+)") {
            $valuesPath = $matches[1].Trim()
            
            # The path in the ArgoCD app is relative to the chart path
            # We need to resolve it from the repository root
            # Extract chart path from the application
            if ($content -match "path:\s*([\w/\-]+)") {
                $chartPath = $matches[1].Trim()
                
                # Resolve the values file path relative to chart path
                # valuesPath is like "../../values/values-backend-dev.yaml"
                # chartPath is like "helm/charts/platform-service"
                
                # Build the full path from repository root
                $resolvedPath = Join-Path $chartPath $valuesPath
                $resolvedPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $resolvedPath))
                
                # Check if values file exists
                if (-not (Test-Path $resolvedPath)) {
                    $issues += "Referenced Helm values file not found: $valuesPath (resolved to: $resolvedPath)"
                }
            }
        }
    }
    
    return $issues
}

Write-Host "Validating Root Application..." -ForegroundColor Yellow
Write-Host "File: $rootApp" -ForegroundColor Gray

if (-not (Test-Path $rootApp)) {
    $errorList += "Root application not found: $rootApp"
    Write-Host "✗ Root application not found" -ForegroundColor Red
} else {
    if (Test-YamlStructure $rootApp) {
        Write-Host "✓ Root application YAML structure valid" -ForegroundColor Green
        
        $specIssues = Test-ApplicationSpec $rootApp
        if ($specIssues.Count -eq 0) {
            Write-Host "✓ Root application spec valid" -ForegroundColor Green
        } else {
            foreach ($issue in $specIssues) {
                $errorList += "Root app: $issue"
                Write-Host "✗ $issue" -ForegroundColor Red
            }
        }
    } else {
        $errorList += "Root application has invalid YAML structure"
        Write-Host "✗ Invalid YAML structure" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Validating Child Applications..." -ForegroundColor Yellow

foreach ($app in $applications) {
    Write-Host ""
    Write-Host "File: $app" -ForegroundColor Gray
    
    if (-not (Test-Path $app)) {
        $errorList += "Application not found: $app"
        Write-Host "✗ Application not found" -ForegroundColor Red
        continue
    }
    
    # Validate YAML structure
    if (Test-YamlStructure $app) {
        Write-Host "✓ YAML structure valid" -ForegroundColor Green
    } else {
        $errorList += "$app has invalid YAML structure"
        Write-Host "✗ Invalid YAML structure" -ForegroundColor Red
        continue
    }
    
    # Validate Application spec
    $specIssues = Test-ApplicationSpec $app
    if ($specIssues.Count -eq 0) {
        Write-Host "✓ Application spec valid" -ForegroundColor Green
    } else {
        foreach ($issue in $specIssues) {
            $errorList += "$app : $issue"
            Write-Host "✗ $issue" -ForegroundColor Red
        }
    }
    
    # Validate Helm values reference
    $valuesIssues = Test-HelmValuesReference $app
    if ($valuesIssues.Count -eq 0) {
        Write-Host "✓ Helm values reference valid" -ForegroundColor Green
    } else {
        foreach ($issue in $valuesIssues) {
            $errorList += "$app : $issue"
            Write-Host "✗ $issue" -ForegroundColor Red
        }
    }
    
    # Check syncPolicy
    $content = Get-Content $app -Raw
    if ($content -match "syncPolicy:") {
        Write-Host "✓ Sync policy configured" -ForegroundColor Green
        
        if ($content -match "automated:") {
            Write-Host "  ✓ Automated sync enabled" -ForegroundColor Green
        }
        
        if ($content -match "prune:\s*true") {
            Write-Host "  ✓ Prune enabled" -ForegroundColor Green
        }
        
        if ($content -match "selfHeal:\s*true") {
            Write-Host "  ✓ Self-heal enabled" -ForegroundColor Green
        }
    } else {
        $warningList += "$app : No sync policy configured"
        Write-Host "⚠ No sync policy configured" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Dry-Run Simulation Summary ===" -ForegroundColor Cyan
Write-Host ""

if ($errorList.Count -eq 0 -and $warningList.Count -eq 0) {
    Write-Host "✓ All ArgoCD applications are valid!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Dry-run simulation passed. Applications would sync successfully." -ForegroundColor Green
    Write-Host ""
    Write-Host "To perform actual ArgoCD dry-run (requires ArgoCD CLI):" -ForegroundColor Yellow
    Write-Host "  argocd app sync backend-dev --dry-run" -ForegroundColor Yellow
    Write-Host "  argocd app sync backend-staging --dry-run" -ForegroundColor Yellow
    Write-Host "  argocd app diff backend-dev" -ForegroundColor Yellow
    Write-Host "  argocd app diff backend-staging" -ForegroundColor Yellow
    exit 0
} else {
    if ($errorList.Count -gt 0) {
        Write-Host "Errors found:" -ForegroundColor Red
        foreach ($err in $errorList) {
            Write-Host "  ✗ $err" -ForegroundColor Red
        }
    }
    
    if ($warningList.Count -gt 0) {
        Write-Host ""
        Write-Host "Warnings:" -ForegroundColor Yellow
        foreach ($warn in $warningList) {
            Write-Host "  ⚠ $warn" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "Dry-run simulation failed. Fix the issues above before deploying." -ForegroundColor Red
    
    if ($errorList.Count -gt 0) {
        exit 1
    }
}
