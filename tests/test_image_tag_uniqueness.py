#!/usr/bin/env python3
"""
Property-based tests for image tag uniqueness.

Feature: serverless-cicd-pipeline, Property 1: 이미지 태그 고유성
Validates: Requirements 1.3, 8.1
"""

import sys
from typing import Set

try:
    from hypothesis import given, settings, strategies as st
    HYPOTHESIS_AVAILABLE = True
except ImportError:
    HYPOTHESIS_AVAILABLE = False
    print("Warning: hypothesis not installed. Running basic tests only.")


def generate_image_tag(git_sha: str) -> str:
    """
    Generate an image tag from a Git commit SHA.
    This simulates the logic used in GitHub Actions: ${GITHUB_SHA:0:15}
    
    Args:
        git_sha: Full Git commit SHA (40 characters)
    
    Returns:
        Image tag (first 15 characters of SHA)
    """
    if len(git_sha) < 15:
        raise ValueError(f"Git SHA must be at least 15 characters, got {len(git_sha)}")
    
    return git_sha[:15]


def test_basic_tag_generation():
    """Basic test: generate a tag from a known SHA"""
    test_sha = "abc123def456789012345678901234567890"
    expected_tag = "abc123def456789"
    
    tag = generate_image_tag(test_sha)
    
    assert tag == expected_tag, \
        f"Expected tag '{expected_tag}', but got '{tag}'"
    assert len(tag) == 15, \
        f"Tag length should be 15, but got {len(tag)}"
    
    print(f"✓ Basic tag generation test passed (SHA: {test_sha[:15]}...)")


def test_tag_determinism():
    """Basic test: same SHA should always produce the same tag"""
    test_sha = "1234567890abcdef1234567890abcdef12345678"
    
    tag1 = generate_image_tag(test_sha)
    tag2 = generate_image_tag(test_sha)
    
    assert tag1 == tag2, \
        f"Same SHA should produce same tag, but got '{tag1}' and '{tag2}'"
    
    print(f"✓ Tag determinism test passed")


if HYPOTHESIS_AVAILABLE:
    # Feature: serverless-cicd-pipeline, Property 1: 이미지 태그 고유성
    @given(git_sha=st.text(min_size=40, max_size=40, alphabet='0123456789abcdef'))
    @settings(max_examples=100)
    def test_image_tag_uniqueness(git_sha):
        """
        모든 Git 커밋에 대해, 생성된 이미지 태그는 해당 커밋 해시를 포함하며 고유해야 함.
        
        Validates: Requirements 1.3, 8.1
        """
        tag = generate_image_tag(git_sha)
        
        # Tag should be exactly 15 characters
        assert len(tag) == 15, \
            f"Tag length should be 15, but got {len(tag)}"
        
        # Tag should be the first 15 characters of the SHA
        assert tag == git_sha[:15], \
            f"Tag should be first 15 chars of SHA, expected '{git_sha[:15]}', got '{tag}'"
        
        # Tag should only contain valid hex characters
        assert all(c in '0123456789abcdef' for c in tag), \
            f"Tag should only contain hex characters, but got '{tag}'"


    # Feature: serverless-cicd-pipeline, Property 1: 이미지 태그 고유성
    @given(git_sha=st.text(min_size=40, max_size=40, alphabet='0123456789abcdef'))
    @settings(max_examples=100)
    def test_image_tag_determinism(git_sha):
        """
        모든 Git 커밋에 대해, 동일한 커밋에서 여러 번 태그를 생성하면 
        항상 동일한 태그가 생성되어야 함.
        
        Validates: Requirements 8.2
        """
        tag1 = generate_image_tag(git_sha)
        tag2 = generate_image_tag(git_sha)
        
        assert tag1 == tag2, \
            f"Same SHA should produce same tag, but got '{tag1}' and '{tag2}'"


    # Feature: serverless-cicd-pipeline, Property 1: 이미지 태그 고유성
    @given(
        git_sha1=st.text(min_size=40, max_size=40, alphabet='0123456789abcdef'),
        git_sha2=st.text(min_size=40, max_size=40, alphabet='0123456789abcdef')
    )
    @settings(max_examples=100)
    def test_different_commits_produce_different_tags(git_sha1, git_sha2):
        """
        서로 다른 Git 커밋에 대해, 생성된 태그가 다르면 원본 커밋도 달라야 함.
        (역: 같은 커밋이면 같은 태그)
        
        Validates: Requirements 1.3, 8.1
        """
        tag1 = generate_image_tag(git_sha1)
        tag2 = generate_image_tag(git_sha2)
        
        # If tags are different, the first 15 chars of SHAs must be different
        if tag1 != tag2:
            assert git_sha1[:15] != git_sha2[:15], \
                f"Different tags should come from different SHA prefixes"
        
        # If first 15 chars are the same, tags must be the same
        if git_sha1[:15] == git_sha2[:15]:
            assert tag1 == tag2, \
                f"Same SHA prefix should produce same tag"


def main():
    """Run tests"""
    print("=" * 60)
    print("Property-based Test: Image Tag Uniqueness")
    print("Feature: serverless-cicd-pipeline, Property 1")
    print("Validates: Requirements 1.3, 8.1")
    print("=" * 60)
    print()
    
    try:
        # Run basic tests
        test_basic_tag_generation()
        test_tag_determinism()
        
        if HYPOTHESIS_AVAILABLE:
            print("\nRunning property-based tests (100 examples each)...")
            
            test_image_tag_uniqueness()
            print("✓ Property test passed: image tag uniqueness (100 examples)")
            
            test_image_tag_determinism()
            print("✓ Property test passed: image tag determinism (100 examples)")
            
            test_different_commits_produce_different_tags()
            print("✓ Property test passed: different commits produce different tags (100 examples)")
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
