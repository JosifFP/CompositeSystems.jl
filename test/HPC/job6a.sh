#!/bin/bash
#SBATCH --time=3-00:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=0
#SBATCH --mail-type=end
#SBATCH --mail-user=josif.figueroa@unb.ca

export JULIA_NUM_THREADS=64
module load julia/1.8.5
module load gurobi/10.0.1
julia --project="." --startup-file=no "run6a.jl"