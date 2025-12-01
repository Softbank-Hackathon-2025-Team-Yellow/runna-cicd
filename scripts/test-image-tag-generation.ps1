# Test script for image tag generation logic

Write-Host "Testing image tag generation logic..." -ForegroundColor Cyan
Write-Host ""

# Simulate GitHub SHA
$TEST_SHA = "abc123def456789012345678901234567890"

# Generate tag using the same logic as GitHub Actions
$IMAGE_TAG = $TEST_SHA.Substring(0, 15)

Write-Host "Test SHA: $TEST_SHA"
Write-Host "Generated Tag: $IMAGE_TAG"
Write-Host ""

# Verify tag length
$TAG_LENGTH = $IMAGE_TAG.Length
if ($TAG_LENGTH -eq 15) {
    Write-Host "✅ Tag length is correct (15 characters)" -ForegroundColor Green
} else {
    Write-Host "❌ Tag length is incorrect (expected 15, got $TAG_LENGTH)" -ForegroundColor Red
    exit 1
}

# Verify tag format (should be alphanumeric/hexadecimal)
if ($IMAGE_TAG -match '^[a-f0-9]+$') {
    Write-Host "✅ Tag format is valid (hexadecimal)" -ForegroundColor Green
} else {
    Write-Host "❌ Tag format is invalid" -ForegroundColor Red
    exit 1
}

# Test determinism - same input should produce same output
$IMAGE_TAG2 = $TEST_SHA.Substring(0, 15)
if ($IMAGE_TAG -eq $IMAGE_TAG2) {
    Write-Host "✅ Tag generation is deterministic" -ForegroundColor Green
} else {
    Write-Host "❌ Tag generation is not deterministic" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ All image tag generation tests passed!" -ForegroundColor Green
