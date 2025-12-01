# PowerShell script to run image tag uniqueness property-based tests

Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 59) -ForegroundColor Cyan
Write-Host "Running Image Tag Uniqueness Property-Based Tests" -ForegroundColor Cyan
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("=" * 59) -ForegroundColor Cyan
Write-Host ""

# Check if Python is available
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Python version: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: Python is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if hypothesis is installed
Write-Host "Checking for hypothesis package..." -ForegroundColor Yellow
$hypothesisCheck = python -c "import hypothesis; print(hypothesis.__version__)" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ hypothesis version: $hypothesisCheck" -ForegroundColor Green
} else {
    Write-Host "Warning: hypothesis not installed. Installing..." -ForegroundColor Yellow
    pip install hypothesis pyyaml
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to install hypothesis" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Running tests..." -ForegroundColor Cyan
Write-Host ""

# Run the test
python tests/test_image_tag_uniqueness.py

$exitCode = $LASTEXITCODE

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "✓ All tests passed successfully!" -ForegroundColor Green
} else {
    Write-Host "✗ Tests failed with exit code: $exitCode" -ForegroundColor Red
}

exit $exitCode
