# Dockerfile syntax validator for PowerShell
# Validates basic Dockerfile syntax without requiring Docker

param(
    [Parameter(Mandatory=$true)]
    [string[]]$DockerfilePaths
)

$validInstructions = @(
    'FROM', 'RUN', 'CMD', 'LABEL', 'EXPOSE', 'ENV', 'ADD', 'COPY',
    'ENTRYPOINT', 'VOLUME', 'USER', 'WORKDIR', 'ARG', 'ONBUILD',
    'STOPSIGNAL', 'HEALTHCHECK', 'SHELL', 'AS'
)

function Test-Dockerfile {
    param([string]$Path)
    
    $errors = @()
    $warnings = @()
    $hasFrom = $false
    
    if (-not (Test-Path $Path)) {
        Write-Host "❌ File not found: $Path" -ForegroundColor Red
        return $false
    }
    
    $lines = Get-Content $Path
    $lineNum = 0
    
    foreach ($line in $lines) {
        $lineNum++
        $trimmed = $line.Trim()
        
        # Skip empty lines and comments
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#')) {
            continue
        }
        
        # Skip line continuations
        if ($trimmed.EndsWith('\')) {
            continue
        }
        
        # Extract instruction (first word)
        $parts = $trimmed -split '\s+', 2
        if ($parts.Count -eq 0) {
            continue
        }
        
        $instruction = $parts[0].ToUpper()
        
        # Check if instruction is valid
        if ($instruction -notin $validInstructions) {
            $errors += "Line $lineNum : Unknown instruction '$instruction'"
            continue
        }
        
        # Check for FROM instruction
        if ($instruction -eq 'FROM') {
            $hasFrom = $true
            if ($parts.Count -lt 2) {
                $errors += "Line $lineNum : FROM requires an image name"
            }
        }
        
        # Validate EXPOSE
        elseif ($instruction -eq 'EXPOSE') {
            if ($parts.Count -lt 2) {
                $errors += "Line $lineNum : EXPOSE requires a port number"
            }
        }
        
        # Validate COPY/ADD
        elseif ($instruction -in @('COPY', 'ADD')) {
            if ($parts.Count -lt 2) {
                $errors += "Line $lineNum : $instruction requires source and destination"
            }
        }
        
        # Validate USER
        elseif ($instruction -eq 'USER') {
            if ($parts.Count -lt 2) {
                $errors += "Line $lineNum : USER requires a username or UID"
            }
        }
        
        # Validate WORKDIR
        elseif ($instruction -eq 'WORKDIR') {
            if ($parts.Count -lt 2) {
                $errors += "Line $lineNum : WORKDIR requires a path"
            }
        }
    }
    
    # Check if Dockerfile has at least one FROM instruction
    if (-not $hasFrom) {
        $errors += "Dockerfile must contain at least one FROM instruction"
    }
    
    # Print results
    Write-Host ""
    if ($errors.Count -gt 0) {
        Write-Host "❌ Validation FAILED for $Path" -ForegroundColor Red
        Write-Host "`nErrors:" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
        return $false
    }
    else {
        Write-Host "✅ Validation PASSED for $Path" -ForegroundColor Green
        return $true
    }
}

# Main execution
$allValid = $true

foreach ($dockerfilePath in $DockerfilePaths) {
    $isValid = Test-Dockerfile -Path $dockerfilePath
    if (-not $isValid) {
        $allValid = $false
    }
}

Write-Host ""
Write-Host ("=" * 60)
if ($allValid) {
    Write-Host "✅ All Dockerfiles are valid!" -ForegroundColor Green
    Write-Host ("=" * 60)
    exit 0
}
else {
    Write-Host "❌ Some Dockerfiles have errors" -ForegroundColor Red
    Write-Host ("=" * 60)
    exit 1
}
