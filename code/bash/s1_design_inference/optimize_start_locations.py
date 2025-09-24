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


def is_open_start_tile(world_objects, width, height, xy):
    """Open if it's inside the grid, not collidable, and not a supply/cut/delivery/counter."""
    x, y = xy
    if x < 0 or y < 0 or x >= width or y >= height:
        return False
    
    # Check if there's an object at this location
    if (x, y) in world_objects:
        obj = world_objects[(x, y)]
        # Objects that are collidable/not walkable
        if obj in '-*/':  # walls, counters, etc.
            return False
        # Objects that are walkable but not good start locations
        if obj in 'tlopTLOP':  # food items and dispensers
            return False
    
    # For empty spaces, they should be walkable
    return True

def scan_open(world_objects, width, height, start_xy, dir_primary, dir_secondary):
    """
    Scan within the interior bounding box (exclude outer walls) in the pattern:
    - Agent 1: move left along the row; when exhausted, move down a row, reset x to right interior.
    - Agent 2: move up along the column; when exhausted, move right a column, reset y to bottom interior.
    """
    # interior bounds (exclude border walls)
    xmin, xmax = 1, max(1, width - 2)
    ymin, ymax = 1, max(1, height - 2)

    # clamp start into interior
    x, y = start_xy
    x = min(max(x, xmin), xmax)
    y = min(max(y, ymin), ymax)

    visited = set()
    for _ in range(max(1, (xmax - xmin + 1) * (ymax - ymin + 1))):
        if (x, y) not in visited and is_open_start_tile(world_objects, width, height, (x, y)):
            return (x, y)
        visited.add((x, y))

        # step primary
        x += dir_primary[0]
        y += dir_primary[1]

        # if moved out of interior, wrap & step secondary
        if not (xmin <= x <= xmax and ymin <= y <= ymax):
            # undo last step
            x -= dir_primary[0]
            y -= dir_primary[1]
            # step secondary
            x += dir_secondary[0]
            y += dir_secondary[1]
            # reset along primary axis to appropriate interior edge
            if dir_primary[0] != 0:  # horizontal primary (agent 1)
                x = xmax if dir_primary[0] < 0 else xmin
            if dir_primary[1] != 0:  # vertical primary (agent 2)
                y = ymax if dir_primary[1] < 0 else ymin
            # clamp
            x = min(max(x, xmin), xmax)
            y = min(max(y, ymin), ymax)
    # As a last resort, return top-left interior
    return (xmin, ymin)

def get_candidate_locations(level_file):
    """
    Get the two candidate start locations by parsing the level file and using the same
    scanning logic as auto_place_agents to find real open spaces.
    """
    try:
        # Parse the level file to get world dimensions and objects
        with open(level_file, 'r') as f:
            lines = f.readlines()
        
        # Find the end of phase 1 (kitchen map)
        phase = 1
        max_x = 0
        max_y = 0
        world_objects = {}
        
        # Parse the level file to extract objects (similar to load_level in overcooked_environment.py)
        y = 0
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
                
                # Parse objects in this line (similar to load_level logic)
                for x, rep in enumerate(line):
                    # Object, i.e. Tomato, Lettuce, Onion, or Plate.
                    if rep in 'tlop':
                        world_objects[(x, y)] = rep
                    # Food dispenser: make food dispenser object and food on top as a hack
                    elif rep in 'TLOP':
                        world_objects[(x, y)] = rep
                    # GridSquare, i.e. Floor, Counter, Cutboard, Delivery.
                    elif rep in '-*/':
                        world_objects[(x, y)] = rep
                    # Empty spaces are walkable
                    else:
                        world_objects[(x, y)] = ' '
                y += 1
        
        # Calculate world dimensions
        w, h = max_x, max_y
        
        # Get the candidate locations using the same logic as auto_place_agents
        # Start from the same initial positions as the environment
        top_right_interior = (max(1, w - 2), 1)
        bottom_left_interior = (1, max(1, h - 2))
        
        # Use the scanning logic to find actual open spaces
        a1 = scan_open(world_objects, w, h, top_right_interior, dir_primary=(-1, 0), dir_secondary=(0, 1))
        a2 = scan_open(world_objects, w, h, bottom_left_interior, dir_primary=(0, -1), dir_secondary=(1, 0))
        if a2 == a1:
            a2 = scan_open(world_objects, w, h, (a2[0], a2[1]-1), dir_primary=(0, -1), dir_secondary=(1, 0))
        
        return f"{a1[0]} {a1[1]}", f"{a2[0]} {a2[1]}"
        
    except Exception as e:
        print(f"Error getting candidate locations for {level_file}: {e}")
        return None, None


def run_single_agent_test(level_file, start_location, model_type="greedy", seed=1):
    """
    Run a single 1-agent test with the specified start location.
    Returns the number of timesteps taken to complete the task.
    """
    # Use the same conda environment setup as the bash scripts
    conda_cmd = [
        "conda", "run", "-n", "design-overcooked", "python3",
        "gym-cooking/gym_cooking/main.py",
        "--level", level_file,
        "--num-agents", "1",
        "--num-start-locations", "1",
        "--seed", str(seed),
        "--model1", model_type,
        "--return-timesteps-only",
        "--output-prefix", "temp_optimization",
        "--recipe", "Salad",
        "--start-location-model1", start_location
    ]
    
    try:
        result = subprocess.run(conda_cmd, capture_output=True, text=True, 
                              cwd=os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))))
        
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
        return None, None, None, None
    
    print(f"Testing {level_file} with locations: {loc1}, {loc2}")
    
    # Test each location with multiple seeds
    loc1_times = []
    loc2_times = []
    loc1_seed_data = []
    loc2_seed_data = []
    
    for seed in range(1, num_seeds + 1):
        print(f"  Testing seed {seed}...")
        
        # Test location 1
        time1 = run_single_agent_test(level_file, loc1, model_type, seed)
        if time1 is not None:
            loc1_times.append(time1)
            loc1_seed_data.append({"seed": seed, "timesteps": time1})
        
        # Test location 2
        time2 = run_single_agent_test(level_file, loc2, model_type, seed)
        if time2 is not None:
            loc2_times.append(time2)
            loc2_seed_data.append({"seed": seed, "timesteps": time2})
    
    if not loc1_times or not loc2_times:
        print(f"Failed to get valid results for {level_file}")
        return None, None, None, None
    
    # Calculate average times
    avg_time1 = sum(loc1_times) / len(loc1_times)
    avg_time2 = sum(loc2_times) / len(loc2_times)
    
    print(f"  Average times: {loc1}={avg_time1:.1f}, {loc2}={avg_time2:.1f}")
    
    # Return optimal assignment (agent1 gets the better location)
    if avg_time1 <= avg_time2:
        return loc1, loc2, loc1_seed_data, loc2_seed_data  # agent1 gets loc1, agent2 gets loc2
    else:
        return loc2, loc1, loc2_seed_data, loc1_seed_data  # agent1 gets loc2, agent2 gets loc1


def main():
    parser = argparse.ArgumentParser(description="Find optimal start locations for Overcooked environments")
    parser.add_argument("--level", type=str, required=True, help="Level file to test")
    parser.add_argument("--model", type=str, default="greedy", help="Model type to use for testing")
    parser.add_argument("--seeds", type=int, default=3, help="Number of seeds to test with")
    parser.add_argument("--output", type=str, help="Output file to save results (JSON format)")
    
    args = parser.parse_args()
    
    # Find optimal locations
    agent1_loc, agent2_loc, agent1_seed_data, agent2_seed_data = find_optimal_start_locations(args.level, args.model, args.seeds)
    
    if agent1_loc is None or agent2_loc is None:
        print("Failed to determine optimal start locations")
        return None
    
    result = {
        "level": args.level,
        "agent1_location": agent1_loc,
        "agent2_location": agent2_loc,
        "agent1_seed_data": agent1_seed_data,
        "agent2_seed_data": agent2_seed_data,
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
