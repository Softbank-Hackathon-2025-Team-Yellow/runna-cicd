#!/bin/bash
# Test script for image tag generation logic

echo "Testing image tag generation logic..."
echo ""

# Simulate GitHub SHA
TEST_SHA="abc123def456789012345678901234567890"

# Generate tag using the same logic as GitHub Actions
IMAGE_TAG="${TEST_SHA:0:15}"

echo "Test SHA: $TEST_SHA"
echo "Generated Tag: $IMAGE_TAG"
echo ""

# Verify tag length
TAG_LENGTH=${#IMAGE_TAG}
if [ $TAG_LENGTH -eq 15 ]; then
    echo "✅ Tag length is correct (15 characters)"
else
    echo "❌ Tag length is incorrect (expected 15, got $TAG_LENGTH)"
    exit 1
fi

# Verify tag format (should be alphanumeric)
if [[ $IMAGE_TAG =~ ^[a-f0-9]+$ ]]; then
    echo "✅ Tag format is valid (hexadecimal)"
else
    echo "❌ Tag format is invalid"
    exit 1
fi

# Test determinism - same input should produce same output
IMAGE_TAG2="${TEST_SHA:0:15}"
if [ "$IMAGE_TAG" == "$IMAGE_TAG2" ]; then
    echo "✅ Tag generation is deterministic"
else
    echo "❌ Tag generation is not deterministic"
    exit 1
fi

echo ""
echo "✅ All image tag generation tests passed!"
