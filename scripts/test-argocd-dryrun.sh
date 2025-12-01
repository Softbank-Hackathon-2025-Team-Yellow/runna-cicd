#!/bin/bash
# ArgoCD Dry-Run Simulation Test
# This script simulates ArgoCD dry-run testing by validating application manifests

set -e

echo "=== ArgoCD Dry-Run Simulation Test ==="
echo ""

errors=0
warnings=0
applications=(
    "argocd/applications/backend-dev.yaml"
    "argocd/applications/backend-staging.yaml"
)
root_app="argocd/root-app.yaml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Function to validate YAML structure
validate_yaml_structure() {
    local file=$1
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    if grep -q "apiVersion: argoproj.io/v1alpha1" "$file" && \
       grep -q "kind: Application" "$file" && \
       grep -q "metadata:" "$file" && \
       grep -q "spec:" "$file"; then
        return 0
    fi
    
    return 1
}

# Function to validate Application spec
validate_application_spec() {
    local file=$1
    local issues=0
    
    if ! grep -q "project:" "$file"; then
        echo -e "${RED}✗ Missing 'project' field${NC}"
        ((issues++))
    fi
    
    if ! grep -q "source:" "$file"; then
        echo -e "${RED}✗ Missing 'source' section${NC}"
        ((issues++))
    else
        if ! grep -q "repoURL:" "$file"; then
            echo -e "${RED}✗ Missing 'repoURL'${NC}"
            ((issues++))
        fi
        if ! grep -q "targetRevision:" "$file"; then
            echo -e "${RED}✗ Missing 'targetRevision'${NC}"
            ((issues++))
        fi
        if ! grep -q "path:" "$file"; then
            echo -e "${RED}✗ Missing 'path'${NC}"
            ((issues++))
        fi
    fi
    
    if ! grep -q "destination:" "$file"; then
        echo -e "${RED}✗ Missing 'destination' section${NC}"
        ((issues++))
    else
        if ! grep -q "server:" "$file"; then
            echo -e "${RED}✗ Missing 'server'${NC}"
            ((issues++))
        fi
        if ! grep -q "namespace:" "$file"; then
            echo -e "${RED}✗ Missing 'namespace'${NC}"
            ((issues++))
        fi
    fi
    
    return $issues
}

# Function to validate Helm values reference
validate_helm_values() {
    local file=$1
    local issues=0
    
    if grep -q "helm:" "$file"; then
        # Extract values file path
        local values_path=$(grep -A 2 "valueFiles:" "$file" | grep "^[[:space:]]*-" | sed 's/^[[:space:]]*-[[:space:]]*//' | head -1)
        
        if [ -n "$values_path" ]; then
            # Resolve relative path
            local app_dir=$(dirname "$file")
            local full_path="$app_dir/$values_path"
            
            if [ ! -f "$full_path" ]; then
                echo -e "${RED}✗ Referenced Helm values file not found: $values_path${NC}"
                ((issues++))
            fi
        fi
    fi
    
    return $issues
}

echo -e "${YELLOW}Validating Root Application...${NC}"
echo -e "${GRAY}File: $root_app${NC}"

if [ ! -f "$root_app" ]; then
    echo -e "${RED}✗ Root application not found${NC}"
    ((errors++))
else
    if validate_yaml_structure "$root_app"; then
        echo -e "${GREEN}✓ Root application YAML structure valid${NC}"
        
        if validate_application_spec "$root_app"; then
            echo -e "${GREEN}✓ Root application spec valid${NC}"
        else
            ((errors++))
        fi
    else
        echo -e "${RED}✗ Invalid YAML structure${NC}"
        ((errors++))
    fi
fi

echo ""
echo -e "${YELLOW}Validating Child Applications...${NC}"

for app in "${applications[@]}"; do
    echo ""
    echo -e "${GRAY}File: $app${NC}"
    
    if [ ! -f "$app" ]; then
        echo -e "${RED}✗ Application not found${NC}"
        ((errors++))
        continue
    fi
    
    # Validate YAML structure
    if validate_yaml_structure "$app"; then
        echo -e "${GREEN}✓ YAML structure valid${NC}"
    else
        echo -e "${RED}✗ Invalid YAML structure${NC}"
        ((errors++))
        continue
    fi
    
    # Validate Application spec
    if validate_application_spec "$app"; then
        echo -e "${GREEN}✓ Application spec valid${NC}"
    else
        ((errors++))
    fi
    
    # Validate Helm values reference
    if validate_helm_values "$app"; then
        echo -e "${GREEN}✓ Helm values reference valid${NC}"
    else
        ((errors++))
    fi
    
    # Check syncPolicy
    if grep -q "syncPolicy:" "$app"; then
        echo -e "${GREEN}✓ Sync policy configured${NC}"
        
        if grep -q "automated:" "$app"; then
            echo -e "${GREEN}  ✓ Automated sync enabled${NC}"
        fi
        
        if grep -q "prune: true" "$app"; then
            echo -e "${GREEN}  ✓ Prune enabled${NC}"
        fi
        
        if grep -q "selfHeal: true" "$app"; then
            echo -e "${GREEN}  ✓ Self-heal enabled${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ No sync policy configured${NC}"
        ((warnings++))
    fi
done

echo ""
echo -e "${CYAN}=== Dry-Run Simulation Summary ===${NC}"
echo ""

if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo -e "${GREEN}✓ All ArgoCD applications are valid!${NC}"
    echo ""
    echo -e "${GREEN}Dry-run simulation passed. Applications would sync successfully.${NC}"
    echo ""
    echo -e "${YELLOW}To perform actual ArgoCD dry-run (requires ArgoCD CLI):${NC}"
    echo -e "${YELLOW}  argocd app sync backend-dev --dry-run${NC}"
    echo -e "${YELLOW}  argocd app sync backend-staging --dry-run${NC}"
    echo -e "${YELLOW}  argocd app diff backend-dev${NC}"
    echo -e "${YELLOW}  argocd app diff backend-staging${NC}"
    exit 0
else
    if [ $errors -gt 0 ]; then
        echo -e "${RED}Found $errors error(s)${NC}"
    fi
    
    if [ $warnings -gt 0 ]; then
        echo -e "${YELLOW}Found $warnings warning(s)${NC}"
    fi
    
    echo ""
    echo -e "${RED}Dry-run simulation failed. Fix the issues above before deploying.${NC}"
    
    if [ $errors -gt 0 ]; then
        exit 1
    fi
fi
