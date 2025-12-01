#!/usr/bin/env python3
"""
Validate Argo Rollouts configuration in Helm templates
Checks:
1. Rollout resource structure
2. Canary strategy configuration (20% → 50% → 80% → 100%, 2m pauses)
3. Blue-Green strategy configuration (manual approval)
"""

import yaml
import sys
from pathlib import Path

def load_yaml_file(filepath):
    """Load YAML file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def validate_rollout_template():
    """Validate rollout.yaml template structure"""
    template_path = Path('helm/charts/platform-service/templates/rollout.yaml')
    
    if not template_path.exists():
        print(f"❌ Rollout template not found: {template_path}")
        return False
    
    with open(template_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check for required Helm template structures
    required_checks = [
        ('{{- if .Values.rollout.enabled }}', 'Rollout enabled check'),
        ('apiVersion: argoproj.io/v1alpha1', 'Argo Rollouts API version'),
        ('kind: Rollout', 'Rollout kind'),
        ('canary:', 'Canary strategy'),
        ('blueGreen:', 'Blue-Green strategy'),
        ('setWeight: 20', 'Canary 20% step'),
        ('setWeight: 50', 'Canary 50% step'),
        ('setWeight: 80', 'Canary 80% step'),
        ('pause: {duration: 2m}', 'Canary 2m pause'),
        ('autoPromotionEnabled: false', 'Blue-Green manual approval'),
        ('canaryService:', 'Canary service reference'),
        ('stableService:', 'Stable service reference'),
        ('activeService:', 'Blue-Green active service'),
        ('previewService:', 'Blue-Green preview service'),
    ]
    
    all_passed = True
    for check_str, description in required_checks:
        if check_str in content:
            print(f"✅ {description}")
        else:
            print(f"❌ {description} - NOT FOUND")
            all_passed = False
    
    return all_passed

def validate_values_file(filepath, expected_config):
    """Validate values file configuration"""
    print(f"\n📋 Validating {filepath.name}...")
    
    values = load_yaml_file(filepath)
    
    # Check rollout configuration
    if 'rollout' not in values:
        print(f"❌ Missing 'rollout' configuration")
        return False
    
    rollout = values['rollout']
    
    # Check enabled status
    if rollout.get('enabled') != expected_config['enabled']:
        print(f"❌ rollout.enabled should be {expected_config['enabled']}, got {rollout.get('enabled')}")
        return False
    else:
        print(f"✅ rollout.enabled = {expected_config['enabled']}")
    
    # Check strategy
    if rollout.get('strategy') != expected_config['strategy']:
        print(f"❌ rollout.strategy should be {expected_config['strategy']}, got {rollout.get('strategy')}")
        return False
    else:
        print(f"✅ rollout.strategy = {expected_config['strategy']}")
    
    return True

def main():
    print("=" * 60)
    print("Argo Rollouts Configuration Validation")
    print("=" * 60)
    
    # Validate rollout template
    print("\n🔍 Validating Rollout Template...")
    template_valid = validate_rollout_template()
    
    # Validate values files
    values_configs = {
        'helm/values/values-backend-dev.yaml': {
            'enabled': False,
            'strategy': 'canary'
        },
        'helm/values/values-backend-staging.yaml': {
            'enabled': True,
            'strategy': 'canary'
        },
        'helm/values/values-backend-prod.yaml': {
            'enabled': True,
            'strategy': 'blueGreen'
        }
    }
    
    values_valid = True
    for filepath, expected in values_configs.items():
        if not validate_values_file(Path(filepath), expected):
            values_valid = False
    
    # Summary
    print("\n" + "=" * 60)
    print("Validation Summary")
    print("=" * 60)
    
    if template_valid and values_valid:
        print("✅ All Argo Rollouts configurations are valid!")
        print("\n📝 Configuration Details:")
        print("  • Dev: Standard Deployment (rollout disabled)")
        print("  • Staging: Canary deployment (20% → 50% → 80% → 100%, 2m pauses)")
        print("  • Production: Blue-Green deployment (manual approval)")
        return 0
    else:
        print("❌ Some validations failed")
        return 1

if __name__ == '__main__':
    sys.exit(main())
