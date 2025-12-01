#!/usr/bin/env python3
"""
Validate Helm values files for syntax and required fields
"""

import yaml
import sys
from pathlib import Path

def validate_values_file(filepath):
    """Validate a single values file"""
    print(f"Validating {filepath}...")
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            values = yaml.safe_load(f)
        
        # Check required fields
        required_fields = ['service', 'image', 'replicaCount', 'resources', 'rollout']
        for field in required_fields:
            if field not in values:
                print(f"  ✗ Missing required field: {field}")
                return False
        
        # Check service fields
        if 'name' not in values['service'] or 'port' not in values['service']:
            print(f"  ✗ Service missing name or port")
            return False
        
        # Check image fields
        if 'repository' not in values['image'] or 'tag' not in values['image']:
            print(f"  ✗ Image missing repository or tag")
            return False
        
        # Check rollout configuration
        if 'enabled' not in values['rollout'] or 'strategy' not in values['rollout']:
            print(f"  ✗ Rollout missing enabled or strategy")
            return False
        
        print(f"  ✓ Valid YAML with all required fields")
        return True
        
    except yaml.YAMLError as e:
        print(f"  ✗ YAML syntax error: {e}")
        return False
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False

def main():
    values_dir = Path("helm/values")
    
    if not values_dir.exists():
        print(f"Error: {values_dir} does not exist")
        sys.exit(1)
    
    files_to_validate = [
        values_dir / "values-backend-dev.yaml",
        values_dir / "values-backend-staging.yaml",
        values_dir / "values-backend-prod.yaml"
    ]
    
    all_valid = True
    for filepath in files_to_validate:
        if not filepath.exists():
            print(f"✗ File not found: {filepath}")
            all_valid = False
        else:
            if not validate_values_file(filepath):
                all_valid = False
    
    if all_valid:
        print("\n✓ All values files are valid!")
        sys.exit(0)
    else:
        print("\n✗ Some values files have errors")
        sys.exit(1)

if __name__ == "__main__":
    main()
