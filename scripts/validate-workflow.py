#!/usr/bin/env python3
"""Validate GitHub Actions workflow YAML syntax."""

import yaml
import sys

def validate_workflow(filepath):
    """Validate YAML syntax of GitHub Actions workflow."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            workflow = yaml.safe_load(f)
        
        # Basic structure validation
        assert 'name' in workflow, "Missing 'name' field"
        assert ('on' in workflow or True in workflow), "Missing 'on' field"
        assert 'jobs' in workflow, "Missing 'jobs' field"
        
        print(f"✅ Workflow YAML syntax is valid: {filepath}")
        print(f"   Workflow name: {workflow['name']}")
        print(f"   Jobs: {', '.join(workflow['jobs'].keys())}")
        return True
        
    except yaml.YAMLError as e:
        print(f"❌ YAML syntax error: {e}")
        return False
    except AssertionError as e:
        print(f"❌ Validation error: {e}")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == '__main__':
    filepath = '.github/workflows/ci-cd.yml'
    if len(sys.argv) > 1:
        filepath = sys.argv[1]
    
    success = validate_workflow(filepath)
    sys.exit(0 if success else 1)
