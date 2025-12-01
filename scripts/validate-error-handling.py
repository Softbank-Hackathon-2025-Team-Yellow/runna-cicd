#!/usr/bin/env python3
"""
Validation script for GitHub Actions error handling and logging.
Validates that the workflow includes proper error handling for all critical steps.
"""

import yaml
import sys
from pathlib import Path


def validate_error_handling():
    """Validate error handling in GitHub Actions workflow."""
    
    workflow_path = Path('.github/workflows/ci-cd.yml')
    
    if not workflow_path.exists():
        print(f"❌ Workflow file not found: {workflow_path}")
        return False
    
    print(f"📄 Reading workflow file: {workflow_path}")
    
    with open(workflow_path, 'r', encoding='utf-8') as f:
        workflow = yaml.safe_load(f)
    
    print("✅ Workflow YAML is valid")
    
    # Check for build-and-deploy job
    if 'jobs' not in workflow or 'build-and-deploy' not in workflow['jobs']:
        print("❌ build-and-deploy job not found")
        return False
    
    job = workflow['jobs']['build-and-deploy']
    steps = job.get('steps', [])
    
    print(f"\n📋 Found {len(steps)} steps in workflow")
    
    # Required steps with error handling
    required_steps = {
        'Build Docker image': False,
        'Push to Amazon ECR': False,
        'Update Helm values for dev environment': False,
        'Update Helm values for staging environment': False,
        'Update Helm values for prod environment': False,
        'Commit and push Helm values changes': False,
        'Build summary': False,
        'Build failure summary': False,
    }
    
    # Check each step
    for step in steps:
        step_name = step.get('name', '')
        
        if step_name in required_steps:
            required_steps[step_name] = True
            print(f"✅ Found step: {step_name}")
    
    # Validate all required steps are present
    missing_steps = [name for name, found in required_steps.items() if not found]
    
    if missing_steps:
        print(f"\n❌ Missing required steps:")
        for step in missing_steps:
            print(f"   - {step}")
        return False
    
    print("\n✅ All required steps are present")
    
    # Check for retry logic in ECR push
    ecr_push_step = next((s for s in steps if s.get('name') == 'Push to Amazon ECR'), None)
    if ecr_push_step:
        run_script = ecr_push_step.get('run', '')
        if 'MAX_RETRIES=3' in run_script and 'RETRY_COUNT' in run_script:
            print("✅ ECR push has retry logic (max 3 attempts)")
        else:
            print("❌ ECR push missing retry logic")
            return False
    
    # Check for retry logic in Git push
    git_push_step = next((s for s in steps if s.get('name') == 'Commit and push Helm values changes'), None)
    if git_push_step:
        run_script = git_push_step.get('run', '')
        if 'MAX_RETRIES=3' in run_script and 'RETRY_COUNT' in run_script:
            print("✅ Git push has retry logic (max 3 attempts)")
        else:
            print("❌ Git push missing retry logic")
            return False
    
    # Check for error logging patterns
    error_patterns = [
        '::error::',
        '::warning::',
        '::notice::',
        '::group::',
        'Error Type:',
        'Exit Code:',
        'Timestamp:',
    ]
    
    workflow_content = workflow_path.read_text(encoding='utf-8')
    
    print("\n📊 Checking error logging patterns:")
    for pattern in error_patterns:
        if pattern in workflow_content:
            count = workflow_content.count(pattern)
            print(f"✅ Found '{pattern}' ({count} occurrences)")
        else:
            print(f"❌ Missing '{pattern}'")
            return False
    
    # Check for failure summary
    failure_step = next((s for s in steps if s.get('name') == 'Build failure summary'), None)
    if failure_step:
        if failure_step.get('if') == 'failure()':
            print("\n✅ Build failure summary runs on failure")
        else:
            print("\n❌ Build failure summary missing 'if: failure()' condition")
            return False
    
    # Check for success summary
    success_step = next((s for s in steps if s.get('name') == 'Build summary'), None)
    if success_step:
        if success_step.get('if') == 'success()':
            print("✅ Build success summary runs on success")
        else:
            print("❌ Build success summary missing 'if: success()' condition")
            return False
    
    print("\n" + "="*60)
    print("✅ All error handling validations passed!")
    print("="*60)
    
    return True


if __name__ == '__main__':
    try:
        success = validate_error_handling()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n❌ Validation failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
