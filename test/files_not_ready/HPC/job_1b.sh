#!/bin/bash
#SBATCH --time=0-08:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=0
#SBATCH --mail-type=end
#SBATCH --mail-user=josif.figueroa@unb.ca

# Load the required modules
module load julia/1.8.5
module load gurobi/10.0.1

# Set the number of threads
export JULIA_NUM_THREADS=64

julia --project="." --startup-file=no "run_1b.jl"