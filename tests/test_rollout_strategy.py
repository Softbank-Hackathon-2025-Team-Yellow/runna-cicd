#!/usr/bin/env python3
"""
Property-based tests for Rollout strategy consistency.

Feature: serverless-cicd-pipeline, Property 6: Rollout 전략 일관성
Validates: Requirements 5.3, 5.4
"""

import yaml
import sys
from pathlib import Path

try:
    from hypothesis import given, settings, strategies as st
    HYPOTHESIS_AVAILABLE = True
except ImportError:
    HYPOTHESIS_AVAILABLE = False
    print("Warning: hypothesis not installed. Running basic tests only.")


def load_helm_values(values_file: str) -> dict:
    """Load and parse a Helm values YAML file."""
    values_path = Path(__file__).parent.parent / "helm" / "values" / values_file
    with open(values_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)


def get_rollout_strategy(environment: str, service: str = "backend") -> str:
    """Get the rollout strategy for a given environment and service."""
    values_file = f"values-{service}-{environment}.yaml"
    values = load_helm_values(values_file)
    
    if not values.get('rollout', {}).get('enabled', False):
        return None
    
    return values.get('rollout', {}).get('strategy')


def test_staging_canary_basic():
    """Basic test: staging uses canary strategy"""
    strategy = get_rollout_strategy('staging', 'backend')
    assert strategy == 'canary', \
        f"Staging environment should use 'canary' strategy, but got '{strategy}'"
    print("✓ Staging uses canary strategy")


def test_production_bluegreen_basic():
    """Basic test: production uses blueGreen strategy"""
    strategy = get_rollout_strategy('prod', 'backend')
    assert strategy == 'blueGreen', \
        f"Production environment should use 'blueGreen' strategy, but got '{strategy}'"
    print("✓ Production uses blueGreen strategy")


if HYPOTHESIS_AVAILABLE:
    # Feature: serverless-cicd-pipeline, Property 6: Rollout 전략 일관성
    @given(service=st.sampled_from(['backend']))
    @settings(max_examples=100)
    def test_staging_uses_canary_strategy(service):
        """
        모든 서비스에 대해, staging 환경은 Canary 배포 전략을 사용해야 함.
        
        Validates: Requirements 5.3
        """
        strategy = get_rollout_strategy('staging', service)
        assert strategy == 'canary', \
            f"Staging environment for {service} should use 'canary' strategy, but got '{strategy}'"


    # Feature: serverless-cicd-pipeline, Property 6: Rollout 전략 일관성
    @given(service=st.sampled_from(['backend']))
    @settings(max_examples=100)
    def test_production_uses_bluegreen_strategy(service):
        """
        모든 서비스에 대해, production 환경은 Blue-Green 배포 전략을 사용해야 함.
        
        Validates: Requirements 5.4
        """
        strategy = get_rollout_strategy('prod', service)
        assert strategy == 'blueGreen', \
            f"Production environment for {service} should use 'blueGreen' strategy, but got '{strategy}'"


    # Feature: serverless-cicd-pipeline, Property 6: Rollout 전략 일관성
    @given(
        environment=st.sampled_from(['staging', 'prod']),
        service=st.sampled_from(['backend'])
    )
    @settings(max_examples=100)
    def test_rollout_strategy_consistency(environment, service):
        """
        모든 환경과 서비스에 대해, 환경별 배포 전략이 일관되게 적용되어야 함.
        - staging: canary
        - production: blueGreen
        
        Validates: Requirements 5.3, 5.4
        """
        strategy = get_rollout_strategy(environment, service)
        
        if environment == 'staging':
            expected = 'canary'
        elif environment == 'prod':
            expected = 'blueGreen'
        else:
            raise ValueError(f"Unexpected environment: {environment}")
        
        assert strategy == expected, \
            f"{environment} environment for {service} should use '{expected}' strategy, but got '{strategy}'"


def main():
    """Run tests"""
    print("=" * 60)
    print("Property-based Test: Rollout Strategy Consistency")
    print("Feature: serverless-cicd-pipeline, Property 6")
    print("Validates: Requirements 5.3, 5.4")
    print("=" * 60)
    print()
    
    try:
        # Run basic tests
        test_staging_canary_basic()
        test_production_bluegreen_basic()
        
        if HYPOTHESIS_AVAILABLE:
            print("\nRunning property-based tests (100 examples each)...")
            test_staging_uses_canary_strategy()
            print("✓ Property test passed: staging uses canary (100 examples)")
            
            test_production_uses_bluegreen_strategy()
            print("✓ Property test passed: production uses blueGreen (100 examples)")
            
            test_rollout_strategy_consistency()
            print("✓ Property test passed: rollout strategy consistency (100 examples)")
        else:
            print("\nNote: Install hypothesis for full property-based testing:")
            print("  pip install hypothesis")
        
        print("\n" + "=" * 60)
        print("✓ All tests passed!")
        print("=" * 60)
        return 0
        
    except AssertionError as e:
        print(f"\n✗ Test failed: {e}")
        return 1
    except Exception as e:
        print(f"\n✗ Error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
