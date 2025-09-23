#!/usr/bin/env python3
"""
Script to find optimal start locations for agents in Overcooked environments.

This script runs 1-agent greedy model runs on each candidate start location
(top-right interior and bottom-left interior) and determines which location
results in fewer timesteps for agent1.
"""

import os
import sys
import json
import subprocess
import argparse
from pathlib import Path


def get_candidate_locations(level_file):
    """
    Get the two candidate start locations (top-right and bottom-left interior)
    by parsing the level file to determine world dimensions.
    """
    try:
        # Parse the level file to get dimensions
        with open(level_file, 'r') as f:
            lines = f.readlines()
        
        # Find the end of phase 1 (kitchen map)
        phase = 1
        max_x = 0
        max_y = 0
        
        for line in lines:
            line = line.strip()
            if line == '':
                phase += 1
                if phase > 1:
                    break
                continue
            
            if phase == 1:
                max_x = max(max_x, len(line))
                max_y += 1
        
        # Calculate interior locations based on auto_place_agents logic
        w, h = max_x, max_y
        top_right_interior = (max(1, w - 2), 1)
        bottom_left_interior = (1, max(1, h - 2))
        
        return f"{top_right_interior[0]} {top_right_interior[1]}", f"{bottom_left_interior[0]} {bottom_left_interior[1]}"
        
    except Exception as e:
        print(f"Error parsing level file {level_file}: {e}")
        return None, None


def run_single_agent_test(level_file, start_location, model_type="greedy", seed=1):
    """
    Run a single 1-agent test with the specified start location.
    Returns the number of timesteps taken to complete the task.
    """
    cmd = [
        sys.executable,
        "gym-cooking/gym_cooking/main.py",
        "--level", level_file,
        "--num-agents", "1",
        "--seed", str(seed),
        "--model1", model_type,
        "--return-timesteps-only",
        "--start-location-model1", start_location
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, 
                              cwd=os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
        
        if result.returncode != 0:
            print(f"Error running test for {level_file} at {start_location}: {result.stderr}")
            return None
        
        # Parse the output to extract timesteps
        for line in result.stdout.split('\n'):
            if line.startswith('TIMESTEPS:'):
                return int(line.split(':')[1])
        
        print(f"No timesteps found in output for {level_file} at {start_location}")
        return None
        
    except Exception as e:
        print(f"Exception running test for {level_file} at {start_location}: {e}")
        return None


def find_optimal_start_locations(level_file, model_type="greedy", num_seeds=3):
    """
    Find optimal start locations by testing both candidate locations
    with multiple seeds and taking the average performance.
    """
    # Get candidate locations
    loc1, loc2 = get_candidate_locations(level_file)
    if loc1 is None or loc2 is None:
        return None, None
    
    print(f"Testing {level_file} with locations: {loc1}, {loc2}")
    
    # Test each location with multiple seeds
    loc1_times = []
    loc2_times = []
    
    for seed in range(1, num_seeds + 1):
        print(f"  Testing seed {seed}...")
        
        # Test location 1
        time1 = run_single_agent_test(level_file, loc1, model_type, seed)
        if time1 is not None:
            loc1_times.append(time1)
        
        # Test location 2
        time2 = run_single_agent_test(level_file, loc2, model_type, seed)
        if time2 is not None:
            loc2_times.append(time2)
    
    if not loc1_times or not loc2_times:
        print(f"Failed to get valid results for {level_file}")
        return None, None
    
    # Calculate average times
    avg_time1 = sum(loc1_times) / len(loc1_times)
    avg_time2 = sum(loc2_times) / len(loc2_times)
    
    print(f"  Average times: {loc1}={avg_time1:.1f}, {loc2}={avg_time2:.1f}")
    
    # Return optimal assignment (agent1 gets the better location)
    if avg_time1 <= avg_time2:
        return loc1, loc2  # agent1 gets loc1, agent2 gets loc2
    else:
        return loc2, loc1  # agent1 gets loc2, agent2 gets loc1


def main():
    parser = argparse.ArgumentParser(description="Find optimal start locations for Overcooked environments")
    parser.add_argument("--level", type=str, required=True, help="Level file to test")
    parser.add_argument("--model", type=str, default="greedy", help="Model type to use for testing")
    parser.add_argument("--seeds", type=int, default=3, help="Number of seeds to test with")
    parser.add_argument("--output", type=str, help="Output file to save results (JSON format)")
    
    args = parser.parse_args()
    
    # Find optimal locations
    agent1_loc, agent2_loc = find_optimal_start_locations(args.level, args.model, args.seeds)
    
    if agent1_loc is None or agent2_loc is None:
        print("Failed to determine optimal start locations")
        sys.exit(1)
    
    result = {
        "level": args.level,
        "agent1_location": agent1_loc,
        "agent2_location": agent2_loc,
        "model": args.model,
        "seeds_tested": args.seeds
    }
    
    print(f"Optimal start locations for {args.level}:")
    print(f"  Agent 1: {agent1_loc}")
    print(f"  Agent 2: {agent2_loc}")
    
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(result, f, indent=2)
        print(f"Results saved to {args.output}")
    
    return result


if __name__ == "__main__":
    main()
