# Test script to verify Helm chart structure without requiring Helm installation
# This performs basic structural validation that can run in any environment

Write-Host "=== Helm Chart Structure Validation ===" -ForegroundColor Cyan
Write-Host ""

$chartPath = "helm/charts/platform-service"
$errors = @()
$warnings = @()

# Check if chart directory exists
if (-not (Test-Path $chartPath)) {
    $errors += "Chart directory not found: $chartPath"
} else {
    Write-Host "✓ Chart directory exists: $chartPath" -ForegroundColor Green
}

# Check Chart.yaml
$chartYaml = Join-Path $chartPath "Chart.yaml"
if (-not (Test-Path $chartYaml)) {
    $errors += "Chart.yaml not found"
} else {
    Write-Host "✓ Chart.yaml exists" -ForegroundColor Green
    
    # Validate Chart.yaml content
    $content = Get-Content $chartYaml -Raw
    if ($content -match "apiVersion:\s*v2") {
        Write-Host "  ✓ API version: v2" -ForegroundColor Green
    } else {
        $warnings += "Chart.yaml should use apiVersion: v2"
    }
    
    if ($content -match "name:\s*\w+") {
        Write-Host "  ✓ Chart name defined" -ForegroundColor Green
    } else {
        $errors += "Chart.yaml missing name field"
    }
    
    if ($content -match "version:\s*[\d\.]+") {
        Write-Host "  ✓ Chart version defined" -ForegroundColor Green
    } else {
        $errors += "Chart.yaml missing version field"
    }
}

# Check values.yaml
$valuesYaml = Join-Path $chartPath "values.yaml"
if (-not (Test-Path $valuesYaml)) {
    $errors += "values.yaml not found"
} else {
    Write-Host "✓ values.yaml exists" -ForegroundColor Green
}

# Check templates directory
$templatesDir = Join-Path $chartPath "templates"
if (-not (Test-Path $templatesDir)) {
    $errors += "templates directory not found"
} else {
    Write-Host "✓ templates directory exists" -ForegroundColor Green
    
    # Check for template files
    $templates = Get-ChildItem $templatesDir -Filter "*.yaml"
    if ($templates.Count -eq 0) {
        $warnings += "No template files found in templates directory"
    } else {
        Write-Host "  ✓ Found $($templates.Count) template file(s)" -ForegroundColor Green
        foreach ($template in $templates) {
            Write-Host "    - $($template.Name)" -ForegroundColor Gray
            
            # Basic YAML syntax check
            $templateContent = Get-Content $template.FullName -Raw
            
            # Check for common template issues
            if ($templateContent -match "{{-?\s*\.Values\.\w+") {
                Write-Host "      ✓ Uses Helm values" -ForegroundColor Green
            }
            
            # Check for proper YAML structure
            if ($templateContent -match "apiVersion:\s*\S+") {
                Write-Host "      ✓ Contains Kubernetes resource" -ForegroundColor Green
            }
        }
    }
}

Write-Host ""
Write-Host "=== Validation Summary ===" -ForegroundColor Cyan

if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✓ All structural checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Note: For complete validation, run:" -ForegroundColor Yellow
    Write-Host "  helm lint $chartPath" -ForegroundColor Yellow
    Write-Host "  helm template test-release $chartPath" -ForegroundColor Yellow
    exit 0
} else {
    if ($errors.Count -gt 0) {
        Write-Host ""
        Write-Host "Errors found:" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  ✗ $error" -ForegroundColor Red
        }
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host ""
        Write-Host "Warnings:" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  ⚠ $warning" -ForegroundColor Yellow
        }
    }
    
    if ($errors.Count -gt 0) {
        exit 1
    }
}
