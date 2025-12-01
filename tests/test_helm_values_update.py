#!/usr/bin/env python3
"""
Property-based tests for Helm values update consistency.

Feature: serverless-cicd-pipeline, Property 2: Helm values 업데이트 일관성
Validates: Requirements 1.4
"""

import yaml
import sys
import tempfile
import shutil
from pathlib import Path

try:
    from hypothesis import given, settings, strategies as st
    HYPOTHESIS_AVAILABLE = True
except ImportError:
    HYPOTHESIS_AVAILABLE = False
    print("Warning: hypothesis not installed. Running basic tests only.")


def update_helm_values(values_file_path: Path, new_tag: str) -> None:
    """
    Update the image tag in a Helm values file.
    This simulates the logic used in GitHub Actions.
    
    Important: Tags are quoted to prevent YAML from interpreting them as numbers.
    For example, '000000000000000' would be interpreted as 0 without quotes.
    """
    with open(values_file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update the tag using the same pattern as GitHub Actions
    # Match 'tag: <value>' (with or without quotes) and replace with quoted new tag
    import re
    # Use a lambda to avoid issues with backslash sequences in the replacement
    # Quote the tag to prevent YAML from interpreting numeric strings as numbers
    updated_content = re.sub(
        r'(tag:\s*)["\']?([^\s#"\']+)["\']?',
        lambda m: m.group(1) + f'"{new_tag}"',
        content
    )
    
    with open(values_file_path, 'w', encoding='utf-8') as f:
        f.write(updated_content)


def get_image_tag_from_values(values_file_path: Path) -> str:
    """Parse a Helm values file and extract the image tag."""
    with open(values_file_path, 'r', encoding='utf-8') as f:
        values = yaml.safe_load(f)
    
    return values.get('image', {}).get('tag', '')


def test_basic_update_consistency():
    """Basic test: update and verify a single tag"""
    test_tag = "abc123def456789"
    
    # Create a temporary copy of a values file
    source_file = Path(__file__).parent.parent / "helm" / "values" / "values-backend-prod.yaml"
    
    with tempfile.NamedTemporaryFile(mode='w', suffix='.yaml', delete=False) as tmp:
        tmp_path = Path(tmp.name)
    
    try:
        shutil.copy(source_file, tmp_path)
        
        # Update the tag
        update_helm_values(tmp_path, test_tag)
        
        # Parse and verify
        parsed_tag = get_image_tag_from_values(tmp_path)
        
        assert parsed_tag == test_tag, \
            f"Expected tag '{test_tag}', but got '{parsed_tag}'"
        
        print(f"✓ Basic update consistency test passed (tag: {test_tag})")
        
    finally:
        tmp_path.unlink()


if HYPOTHESIS_AVAILABLE:
    # Feature: serverless-cicd-pipeline, Property 2: Helm values 업데이트 일관성
    @given(
        image_tag=st.text(
            min_size=15,
            max_size=15,
            alphabet='0123456789abcdef'
        ),
        service=st.sampled_from(['backend'])
    )
    @settings(max_examples=100)
    def test_helm_values_update_consistency(image_tag, service):
        """
        모든 이미지 태그 업데이트에 대해, Helm values 파일을 업데이트한 후 
        파일을 파싱하면 새로운 이미지 태그가 정확히 반영되어 있어야 함.
        
        Validates: Requirements 1.4
        """
        # Get the source values file
        values_file = f"values-{service}-prod.yaml"
        source_path = Path(__file__).parent.parent / "helm" / "values" / values_file
        
        # Create a temporary copy
        with tempfile.NamedTemporaryFile(mode='w', suffix='.yaml', delete=False) as tmp:
            tmp_path = Path(tmp.name)
        
        try:
            shutil.copy(source_path, tmp_path)
            
            # Update the tag
            update_helm_values(tmp_path, image_tag)
            
            # Parse and verify
            parsed_tag = get_image_tag_from_values(tmp_path)
            
            assert parsed_tag == image_tag, \
                f"For service '{service}', expected tag '{image_tag}', but got '{parsed_tag}'"
            
        finally:
            tmp_path.unlink()


    # Feature: serverless-cicd-pipeline, Property 2: Helm values 업데이트 일관성
    @given(
        image_tag=st.text(
            min_size=15,
            max_size=15,
            alphabet='0123456789abcdef'
        ),
        environment=st.sampled_from(['dev', 'staging', 'prod'])
    )
    @settings(max_examples=100)
    def test_helm_values_update_all_environments(image_tag, environment):
        """
        모든 환경(dev, staging, prod)에 대해, Helm values 업데이트 후 
        파싱하면 새 태그가 정확히 반영되어야 함.
        
        Validates: Requirements 1.4
        """
        # Get the source values file
        values_file = f"values-backend-{environment}.yaml"
        source_path = Path(__file__).parent.parent / "helm" / "values" / values_file
        
        # Create a temporary copy
        with tempfile.NamedTemporaryFile(mode='w', suffix='.yaml', delete=False) as tmp:
            tmp_path = Path(tmp.name)
        
        try:
            shutil.copy(source_path, tmp_path)
            
            # Update the tag
            update_helm_values(tmp_path, image_tag)
            
            # Parse and verify
            parsed_tag = get_image_tag_from_values(tmp_path)
            
            assert parsed_tag == image_tag, \
                f"For environment '{environment}', expected tag '{image_tag}', but got '{parsed_tag}'"
            
        finally:
            tmp_path.unlink()


def main():
    """Run tests"""
    print("=" * 60)
    print("Property-based Test: Helm Values Update Consistency")
    print("Feature: serverless-cicd-pipeline, Property 2")
    print("Validates: Requirements 1.4")
    print("=" * 60)
    print()
    
    try:
        # Run basic test
        test_basic_update_consistency()
        
        if HYPOTHESIS_AVAILABLE:
            print("\nRunning property-based tests (100 examples each)...")
            
            test_helm_values_update_consistency()
            print("✓ Property test passed: Helm values update consistency (100 examples)")
            
            test_helm_values_update_all_environments()
            print("✓ Property test passed: All environments update consistency (100 examples)")
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
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
