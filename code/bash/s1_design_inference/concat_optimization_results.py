#!/usr/bin/env python3
import json
import sys
import os
from pathlib import Path

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 concat_optimization_results.py <output_file> <temp_file>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    temp_file = sys.argv[2]
    
    # Load existing results or create empty list
    if os.path.exists(output_file):
        with open(output_file, 'r') as f:
            results = json.load(f)
    else:
        results = []
    
    # Load new result
    if os.path.exists(temp_file):
        with open(temp_file, 'r') as f:
            new_result = json.load(f)
        results.append(new_result)
        
        # Save updated results
        with open(output_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        # Clean up temp file
        os.remove(temp_file)
        print(f"Added result for {new_result['level']}")
    else:
        print(f"Warning: Temp file {temp_file} not found")

if __name__ == "__main__":
    main()
