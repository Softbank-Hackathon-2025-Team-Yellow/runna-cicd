#!/usr/bin/env python3
"""
Dockerfile syntax validator
Validates Dockerfile syntax without requiring Docker to be installed
"""

import sys
import re
from pathlib import Path


class DockerfileValidator:
    """Validates Dockerfile syntax"""
    
    VALID_INSTRUCTIONS = {
        'FROM', 'RUN', 'CMD', 'LABEL', 'EXPOSE', 'ENV', 'ADD', 'COPY',
        'ENTRYPOINT', 'VOLUME', 'USER', 'WORKDIR', 'ARG', 'ONBUILD',
        'STOPSIGNAL', 'HEALTHCHECK', 'SHELL'
    }
    
    def __init__(self, dockerfile_path):
        self.dockerfile_path = Path(dockerfile_path)
        self.errors = []
        self.warnings = []
        
    def validate(self):
        """Validate the Dockerfile"""
        if not self.dockerfile_path.exists():
            self.errors.append(f"Dockerfile not found: {self.dockerfile_path}")
            return False
            
        with open(self.dockerfile_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        has_from = False
        line_num = 0
        in_continuation = False
        
        for i, line in enumerate(lines, 1):
            line_num = i
            stripped = line.strip()
            
            # Skip empty lines and comments
            if not stripped or stripped.startswith('#'):
                continue
            
            # Handle line continuations
            if in_continuation:
                # We're in a continuation, skip validation until we reach the end
                if not stripped.endswith('\\'):
                    in_continuation = False
                continue
                
            if stripped.endswith('\\'):
                in_continuation = True
                # Still validate the instruction on the first line
                
            # Extract instruction (first word)
            parts = stripped.split(None, 1)
            if not parts:
                continue
                
            instruction = parts[0].upper()
            
            # Check if instruction is valid
            if instruction not in self.VALID_INSTRUCTIONS:
                self.errors.append(
                    f"Line {line_num}: Unknown instruction '{instruction}'"
                )
                continue
                
            # Check for FROM instruction
            if instruction == 'FROM':
                has_from = True
                # Validate FROM syntax
                if len(parts) < 2:
                    self.errors.append(
                        f"Line {line_num}: FROM requires an image name"
                    )
                    
            # Validate EXPOSE instruction
            elif instruction == 'EXPOSE':
                if len(parts) < 2:
                    self.errors.append(
                        f"Line {line_num}: EXPOSE requires a port number"
                    )
                else:
                    port_spec = parts[1].split()[0]
                    if not re.match(r'^\d+(/tcp|/udp)?$', port_spec):
                        self.warnings.append(
                            f"Line {line_num}: EXPOSE port format may be invalid: {port_spec}"
                        )
                        
            # Validate COPY/ADD
            elif instruction in ('COPY', 'ADD'):
                if len(parts) < 2:
                    self.errors.append(
                        f"Line {line_num}: {instruction} requires source and destination"
                    )
                else:
                    args = parts[1].split()
                    if len(args) < 2:
                        self.errors.append(
                            f"Line {line_num}: {instruction} requires at least 2 arguments"
                        )
                        
            # Validate USER
            elif instruction == 'USER':
                if len(parts) < 2:
                    self.errors.append(
                        f"Line {line_num}: USER requires a username or UID"
                    )
                    
            # Validate WORKDIR
            elif instruction == 'WORKDIR':
                if len(parts) < 2:
                    self.errors.append(
                        f"Line {line_num}: WORKDIR requires a path"
                    )
                    
        # Check if Dockerfile has at least one FROM instruction
        if not has_from:
            self.errors.append("Dockerfile must contain at least one FROM instruction")
            
        return len(self.errors) == 0
        
    def print_results(self):
        """Print validation results"""
        if self.errors:
            print(f"\n❌ Validation FAILED for {self.dockerfile_path}")
            print("\nErrors:")
            for error in self.errors:
                print(f"  - {error}")
        else:
            print(f"\n✅ Validation PASSED for {self.dockerfile_path}")
            
        if self.warnings:
            print("\nWarnings:")
            for warning in self.warnings:
                print(f"  - {warning}")
                
        return len(self.errors) == 0


def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage: python validate-dockerfile.py <dockerfile-path> [<dockerfile-path> ...]")
        sys.exit(1)
        
    all_valid = True
    
    for dockerfile_path in sys.argv[1:]:
        validator = DockerfileValidator(dockerfile_path)
        is_valid = validator.validate()
        validator.print_results()
        
        if not is_valid:
            all_valid = False
            
    if all_valid:
        print("\n" + "="*60)
        print("✅ All Dockerfiles are valid!")
        print("="*60)
        sys.exit(0)
    else:
        print("\n" + "="*60)
        print("❌ Some Dockerfiles have errors")
        print("="*60)
        sys.exit(1)


if __name__ == "__main__":
    main()
