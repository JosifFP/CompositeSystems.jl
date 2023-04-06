#!/bin/bash
#SBATCH --time=1-24:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=32
#SBATCH --mem-per-cpu=40000M
#SBATCH --mail-type=end
#SBATCH --mail-user=josif.figueroa@unb.ca

export JULIA_NUM_THREADS=32
module load julia/1.8.5
module load gurobi/10.0.1
julia --project="." --startup-file=no "run.jl"