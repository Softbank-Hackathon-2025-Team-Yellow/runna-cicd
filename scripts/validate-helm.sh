#!/bin/bash
# Helm Chart Validation Script
# This script validates Helm charts using helm lint and helm template
# Requirements: 7.2, 7.3

set -e

CHART_PATH="${1:-helm/charts/platform-service}"
VALUES_PATH="${2:-}"

echo "=== Helm Chart Validation ==="
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "✗ Helm is not installed. Please install Helm first."
    echo "  Download from: https://helm.sh/docs/intro/install/"
    exit 1
fi

HELM_VERSION=$(helm version --short)
echo "✓ Helm installed: $HELM_VERSION"
echo ""

echo "--- Step 1: Helm Lint (Syntax Validation) ---"
echo "Checking chart: $CHART_PATH"
echo ""

# Run helm lint
if [ -n "$VALUES_PATH" ]; then
    helm lint "$CHART_PATH" -f "$VALUES_PATH"
else
    helm lint "$CHART_PATH"
fi

echo ""
echo "✓ Helm lint passed - no syntax errors found"
echo ""

echo "--- Step 2: Helm Template (Rendering Test) ---"
echo "Rendering templates to verify output..."
echo ""

# Run helm template
if [ -n "$VALUES_PATH" ]; then
    helm template test-release "$CHART_PATH" -f "$VALUES_PATH"
else
    helm template test-release "$CHART_PATH"
fi

echo ""
echo "=== Validation Complete ==="
echo "✓ Chart syntax is valid (helm lint)"
echo "✓ Templates render correctly (helm template)"
echo ""
echo "Requirements validated: 7.2, 7.3"
