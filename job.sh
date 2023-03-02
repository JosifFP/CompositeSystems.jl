#!/bin/bash
#SBATCH --time=0-00:05:00

#SBATCH --job-name="rts_dc"
#SBATCH --nodes=1
#SBATCH --cpus-per-task=10
#SBATCH --mem-per-cpu=2000M
#SBATCH --error="rts_dc_%a.err.out"
#SBATCH --mail-type=end
#SBATCH --mail-user=josif.figueroa@unb.ca

export JULIA_NUM_THREADS=10
julia --project="." --startup-file=no "test/test_cases.jl"