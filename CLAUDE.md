# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

As an agent, you should plan your approach in the `claude/` folder. Be vigilant with keeping the contents of this folder up to date and minimal at all times. 

## Overview

This is a psychology research project studying how people infer design intent from physical arrangements in a cooking simulation environment. The project uses a modified version of the gym-cooking submodule to run computational model simulations and compare them against human behavioral data.

We are currently working on the study s1_design_inference. 

## Environment Setup

The project uses two separate conda environments:

**Primary environment (`design-inference`):**
```bash
conda env create -f environment.yml
conda activate design-inference
```
Used for data analysis, visualization, and general Python work. Includes Jupyter, pandas, matplotlib, seaborn.

**Simulation environment (`design-overcooked`):**
```bash
cd gym-cooking
conda env create -f environment.yml    # creates "design-overcooked"
conda activate design-overcooked
```
Required for running the gym-cooking simulations. Separate environment needed for Apple Silicon compatibility.

## Key Commands

**Run model simulations:**
```bash
# Activate the simulation environment first
conda activate design-overcooked

bash code/bash/s1_design_inference/submit_all.sh
```

**Get model layouts**
In the behavioral experiment, participants see an empty kitchen layout and judge either (1) whether it's designed for one or two cooks, or (2) whether it's designed to make a tomato salad ("Salad") or an onion salad ("SaladOL"). Generation of these layouts is handled using:
```bash
conda activate design-overcooked

bash code/bash/s1_design_inference_get_layouts.sh
```
The current implementation is messy and needs to be cleaned up substantially. 

**Data analysis:**
```bash
conda activate design-inference
jupyter lab  # Open analysis notebooks in code/python/254a/ or code/python/s1_design_inference/
```

## Project Structure

### Core Components

- **gym-cooking/**: Modified Overcooked simulation framework with multi-agent planning algorithms
  - `gym_cooking/main.py`: Main simulation entry point
  - `gym_cooking/utils/`: Core simulation utilities (world, agents, objects)
  - `gym_cooking/recipe_planner/`: Recipe planning algorithms
  - `gym_cooking/navigation_planner/`: Agent navigation planning
  - `gym_cooking/delegation_planner/`: Multi-agent coordination algorithms

- **stimuli/**: Experimental level designs
  - `s1_design_inference/txt/`: Trial level files (trial_XX.txt)
  - `s1_design_inference/trials_metadata.csv`: Trial metadata with types and parameters
  - `gym-cooking-levels/`: Additional level configurations

- **code/python/**: Analysis and model execution scripts
  - `s1_design_inference/model_runs.py`: Main script for running model simulations
  - `254a/`: Jupyter notebooks for experimental analysis
  - `s1_design_inference/`: Processing notebooks for model outputs

- **data/**: Experimental and simulation data storage
  - `models/s1_design_inference/`: Model simulation outputs
  - `behavioral_results/`: Human behavioral data

### Model Types

The simulation supports several agent models:
- `greedy`: Greedy planning agent
- `bd`: Bayesian delegation agent
- `up`: Uniform priors agent
- `dc`: Divide & conquer agent
- `fb`: Fixed beliefs agent

### Trial Types

Two main experimental conditions:
- **cooks**: Varying number of agents (1-2) with fixed recipe (Salad)
- **dish**: Fixed single agent with varying recipes (Salad vs SaladOL)

## Running Simulations

Model simulations are computationally intensive and run in parallel. The main execution script is `code/python/s1_design_inference/model_runs.py`, which:

1. Reads trial metadata from `stimuli/s1_design_inference/trials_metadata.csv`
2. For each trial, runs multiple model configurations with different seeds (default: 20 seeds)
3. Outputs simulation results to `data/models/s1_design_inference/`
4. Uses CPU parallelization (configurable via `--jobs` parameter)

The simulation records timesteps, agent behaviors, and success metrics for each run, which are later analyzed to compare against human behavioral data.