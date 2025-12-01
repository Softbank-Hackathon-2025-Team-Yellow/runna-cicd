# Test script for Helm values update logic

Write-Host "Testing Helm values update logic..." -ForegroundColor Cyan
Write-Host ""

# Test parameters
$TEST_TAG = "abc123def456789"
$TEST_FILE = "helm/values/values-backend-prod.yaml"
$BACKUP_FILE = "helm/values/values-backend-prod.yaml.backup"

# Create backup
Write-Host "Creating backup of $TEST_FILE..."
Copy-Item $TEST_FILE $BACKUP_FILE -Force

try {
    # Read the file
    $content = Get-Content $TEST_FILE -Raw
    
    # Get original tag
    if ($content -match 'tag:\s*(.+)') {
        $originalTag = $matches[1].Trim()
        Write-Host "Original tag: $originalTag"
    }
    
    # Update the tag using regex
    $updatedContent = $content -replace '(tag:\s*)(.+)', "`$1$TEST_TAG  # Will be updated by GitHub Actions"
    
    # Write back
    Set-Content -Path $TEST_FILE -Value $updatedContent -NoNewline
    
    # Verify the update
    $verifyContent = Get-Content $TEST_FILE -Raw
    if ($verifyContent -match 'tag:\s*(.+?)(\s|#)') {
        $newTag = $matches[1].Trim()
        Write-Host "Updated tag: $newTag"
        
        if ($newTag -eq $TEST_TAG) {
            Write-Host "✅ Tag update successful!" -ForegroundColor Green
            $success = $true
        } else {
            Write-Host "❌ Tag update failed! Expected: $TEST_TAG, Got: $newTag" -ForegroundColor Red
            $success = $false
        }
    } else {
        Write-Host "❌ Could not verify tag update" -ForegroundColor Red
        $success = $false
    }
    
} finally {
    # Restore backup
    Write-Host ""
    Write-Host "Restoring original file..."
    Move-Item $BACKUP_FILE $TEST_FILE -Force
    Write-Host "✅ Original file restored" -ForegroundColor Green
}

Write-Host ""
if ($success) {
    Write-Host "✅ All Helm values update tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Helm values update tests failed!" -ForegroundColor Red
    exit 1
}
