#!/usr/bin/env python3
"""
Validate policy template YAML files
"""
import yaml
import sys
from pathlib import Path

def validate_yaml_file(filepath):
    """Validate a YAML file and print its structure"""
    print(f"\n{'='*60}")
    print(f"Validating: {filepath}")
    print(f"{'='*60}")
    
    try:
        with open(filepath, 'r') as f:
            docs = list(yaml.safe_load_all(f))
        
        print(f"✓ Valid YAML with {len(docs)} document(s)")
        
        for i, doc in enumerate(docs, 1):
            if doc:
                kind = doc.get('kind', 'Unknown')
                name = doc.get('metadata', {}).get('name', 'Unknown')
                print(f"  Document {i}: {kind} - {name}")
                
                # Validate required fields
                if 'apiVersion' not in doc:
                    print(f"    ⚠ Warning: Missing apiVersion")
                if 'metadata' not in doc:
                    print(f"    ⚠ Warning: Missing metadata")
                if 'spec' not in doc:
                    print(f"    ⚠ Warning: Missing spec")
        
        return True
    except yaml.YAMLError as e:
        print(f"✗ YAML Error: {e}")
        return False
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def main():
    """Main validation function"""
    policies_dir = Path(__file__).parent
    
    files_to_validate = [
        policies_dir / "resource-quota-template.yaml",
        policies_dir / "network-policy-template.yaml"
    ]
    
    all_valid = True
    for filepath in files_to_validate:
        if filepath.exists():
            if not validate_yaml_file(filepath):
                all_valid = False
        else:
            print(f"\n✗ File not found: {filepath}")
            all_valid = False
    
    print(f"\n{'='*60}")
    if all_valid:
        print("✓ All templates are valid!")
        return 0
    else:
        print("✗ Some templates have errors")
        return 1

if __name__ == "__main__":
    sys.exit(main())
