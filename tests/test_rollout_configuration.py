#!/usr/bin/env python3
"""
Test Argo Rollouts Configuration
Validates requirements 3.1, 3.2, 3.3, 3.5
"""

import yaml
import re
from pathlib import Path

def load_yaml_file(filepath):
    """Load YAML file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)

def test_rollout_template_exists():
    """Test that rollout template exists"""
    template_path = Path('helm/charts/platform-service/templates/rollout.yaml')
    assert template_path.exists(), "Rollout template should exist"
    print("✅ Rollout template exists")

def test_rollout_uses_argo_api():
    """Test requirement 3.1: Uses Argo Rollouts API"""
    template_path = Path('helm/charts/platform-service/templates/rollout.yaml')
    with open(template_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    assert 'apiVersion: argoproj.io/v1alpha1' in content, "Should use Argo Rollouts API"
    assert 'kind: Rollout' in content, "Should be Rollout kind"
    print("✅ Requirement 3.1: Uses Argo Rollouts API")

def test_canary_initial_weight():
    """Test requirement 3.2: Initial 20% traffic routing"""
    template_path = Path('helm/charts/platform-service/templates/rollout.yaml')
    with open(template_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check for canary strategy with 20% initial weight
    assert 'canary:' in content, "Should have canary strategy"
    assert 'setWeight: 20' in content, "Should start with 20% traffic"
    
    # Verify it's the first step
    canary_section = re.search(r'canary:.*?steps:(.*?)(?=\{\{-|$)', content, re.DOTALL)
    assert canary_section, "Should have canary steps"
    
    steps_text = canary_section.group(1)
    first_weight = re.search(r'setWeight:\s*(\d+)', steps_text)
    assert first_weight and first_weight.group(1) == '20', "First step should be 20%"
    
    print("✅ Requirement 3.2: Initial 20% traffic routing")

def test_canary_progressive_weights():
    """Test requirement 3.3: Progressive traffic increase (20% → 50% → 80% → 100%)"""
    template_path = Path('helm/charts/platform-service/templates/rollout.yaml')
    with open(template_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract all setWeight values
    weights = re.findall(r'setWeight:\s*(\d+)', content)
    weights = [int(w) for w in weights]
    
    expected_weights = [20, 50, 80]
    assert weights == expected_weights, f"Should have weights {expected_weights}, got {weights}"
    
    print("✅ Requirement 3.3: Progressive traffic increase (20% → 50% → 80%)")

def test_canary_pause_duration():
    """Test requirement 3.4: 2-minute pauses between steps"""
    template_path = Path('helm/charts/platform-service/templates/rollout.yaml')
    with open(template_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check for 2-minute pauses
    pauses = re.findall(r'pause:\s*\{duration:\s*(\w+)\}', content)
    
    # Should have 3 pauses (after 20%, 50%, 80%)
    assert len(pauses) >= 3, f"Should have at least 3 pauses, found {len(pauses)}"
    
    # All pauses should be 2 minutes
    for pause in pauses[:3]:
        assert pause == '2m', f"Pause should be 2m, got {pause}"
    
    print("✅ Requirement 3.4: 2-minute pauses between steps")

def test_bluegreen_manual_approval():
    """Test requirement 3.5: Blue-Green with manual approval"""
    template_path = Path('helm/charts/platform-service/templates/rollout.yaml')
    with open(template_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check for Blue-Green strategy
    assert 'blueGreen:' in content, "Should have Blue-Green strategy"
    assert 'autoPromotionEnabled: false' in content, "Should require manual approval"
    assert 'activeService:' in content, "Should have active service"
    assert 'previewService:' in content, "Should have preview service"
    
    print("✅ Requirement 3.5: Blue-Green with manual approval")

def test_canary_services_created():
    """Test that Canary strategy creates required services"""
    template_path = Path('helm/charts/platform-service/templates/rollout.yaml')
    with open(template_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check for canary and stable services
    assert 'canaryService:' in content, "Should reference canary service"
    assert 'stableService:' in content, "Should reference stable service"
    
    # Check that services are actually defined
    assert 'name: {{ .Values.service.name }}-canary' in content, "Should create canary service"
    assert 'name: {{ .Values.service.name }}-stable' in content, "Should create stable service"
    
    print("✅ Canary services are created")

def test_bluegreen_services_created():
    """Test that Blue-Green strategy creates required services"""
    template_path = Path('helm/charts/platform-service/templates/rollout.yaml')
    with open(template_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check for preview service
    assert 'name: {{ .Values.service.name }}-preview' in content, "Should create preview service"
    
    print("✅ Blue-Green preview service is created")

def test_dev_environment_config():
    """Test dev environment uses standard deployment"""
    values = load_yaml_file('helm/values/values-backend-dev.yaml')
    
    assert 'rollout' in values, "Should have rollout config"
    assert values['rollout']['enabled'] == False, "Dev should not use Rollout"
    
    print("✅ Dev environment: Standard deployment (rollout disabled)")

def test_staging_environment_config():
    """Test staging environment uses Canary strategy"""
    values = load_yaml_file('helm/values/values-backend-staging.yaml')
    
    assert 'rollout' in values, "Should have rollout config"
    assert values['rollout']['enabled'] == True, "Staging should use Rollout"
    assert values['rollout']['strategy'] == 'canary', "Staging should use Canary"
    
    print("✅ Staging environment: Canary deployment")

def test_production_environment_config():
    """Test production environment uses Blue-Green strategy"""
    values = load_yaml_file('helm/values/values-backend-prod.yaml')
    
    assert 'rollout' in values, "Should have rollout config"
    assert values['rollout']['enabled'] == True, "Production should use Rollout"
    assert values['rollout']['strategy'] == 'blueGreen', "Production should use Blue-Green"
    
    print("✅ Production environment: Blue-Green deployment")

def test_rollout_conditional_rendering():
    """Test that Rollout is conditionally rendered based on enabled flag"""
    template_path = Path('helm/charts/platform-service/templates/rollout.yaml')
    with open(template_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Should start with conditional check
    assert content.strip().startswith('{{- if .Values.rollout.enabled }}'), \
        "Template should be conditionally rendered"
    
    # Should end with endif
    assert '{{- end }}' in content, "Template should have endif"
    
    print("✅ Rollout is conditionally rendered")

def test_rollout_selector_labels():
    """Test that Rollout has proper selector labels"""
    template_path = Path('helm/charts/platform-service/templates/rollout.yaml')
    with open(template_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check for selector
    assert 'selector:' in content, "Should have selector"
    assert 'matchLabels:' in content, "Should have matchLabels"
    assert 'app: {{ .Values.service.name }}' in content, "Should match on app label"
    
    print("✅ Rollout has proper selector labels")

def main():
    print("=" * 70)
    print("Argo Rollouts Configuration Tests")
    print("=" * 70)
    print()
    
    tests = [
        test_rollout_template_exists,
        test_rollout_uses_argo_api,
        test_canary_initial_weight,
        test_canary_progressive_weights,
        test_canary_pause_duration,
        test_bluegreen_manual_approval,
        test_canary_services_created,
        test_bluegreen_services_created,
        test_dev_environment_config,
        test_staging_environment_config,
        test_production_environment_config,
        test_rollout_conditional_rendering,
        test_rollout_selector_labels,
    ]
    
    failed = []
    for test in tests:
        try:
            test()
        except AssertionError as e:
            print(f"❌ {test.__name__}: {e}")
            failed.append(test.__name__)
        except Exception as e:
            print(f"❌ {test.__name__}: Unexpected error: {e}")
            failed.append(test.__name__)
    
    print()
    print("=" * 70)
    print("Test Summary")
    print("=" * 70)
    
    if not failed:
        print("✅ All tests passed!")
        print()
        print("Requirements Validated:")
        print("  ✅ 3.1: Uses Argo Rollouts for Canary deployment")
        print("  ✅ 3.2: Initial 20% traffic routing")
        print("  ✅ 3.3: Progressive traffic increase (20% → 50% → 80% → 100%)")
        print("  ✅ 3.4: Automatic progression with 2-minute pauses")
        print("  ✅ 3.5: Blue-Green deployment with manual approval")
        print("  ✅ 5.2: Dev uses standard deployment")
        print("  ✅ 5.3: Staging uses Canary strategy")
        print("  ✅ 5.4: Production uses Blue-Green strategy")
        return 0
    else:
        print(f"❌ {len(failed)} test(s) failed:")
        for test_name in failed:
            print(f"  - {test_name}")
        return 1

if __name__ == '__main__':
    import sys
    sys.exit(main())
