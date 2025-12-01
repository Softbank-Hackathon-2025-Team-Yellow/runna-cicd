#!/usr/bin/env python3
"""Validate AnalysisTemplate YAML syntax"""

import yaml
import sys

def validate_analysis_template(file_path):
    """Validate AnalysisTemplate YAML file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = yaml.safe_load(f)
        
        # Check required fields
        assert data['apiVersion'] == 'argoproj.io/v1alpha1', "Invalid apiVersion"
        assert data['kind'] == 'AnalysisTemplate', "Invalid kind"
        assert 'metadata' in data, "Missing metadata"
        assert 'name' in data['metadata'], "Missing metadata.name"
        assert 'spec' in data, "Missing spec"
        assert 'metrics' in data['spec'], "Missing spec.metrics"
        
        # Check metrics
        metrics = data['spec']['metrics']
        assert len(metrics) > 0, "No metrics defined"
        
        for metric in metrics:
            assert 'name' in metric, "Metric missing name"
            assert 'provider' in metric, "Metric missing provider"
            assert 'prometheus' in metric['provider'], "Metric missing prometheus provider"
            assert 'query' in metric['provider']['prometheus'], "Metric missing query"
            assert 'successCondition' in metric, "Metric missing successCondition"
        
        print(f"✓ Valid AnalysisTemplate: {file_path}")
        print(f"  - API Version: {data['apiVersion']}")
        print(f"  - Name: {data['metadata']['name']}")
        print(f"  - Metrics: {len(metrics)}")
        for metric in metrics:
            print(f"    - {metric['name']}: {metric['successCondition']}")
        
        return True
    except Exception as e:
        print(f"✗ Validation failed: {e}")
        return False

if __name__ == '__main__':
    file_path = 'argocd/analysis-templates/success-rate.yaml'
    success = validate_analysis_template(file_path)
    sys.exit(0 if success else 1)
