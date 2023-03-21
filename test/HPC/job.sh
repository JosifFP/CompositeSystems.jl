#!/bin/bash
#SBATCH --time=0-00:01:00

#SBATCH --job-name="rts_dc"
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32000M
#SBATCH --error="rts_dc_%a.err.out"
#SBATCH --mail-type=end
#SBATCH --mail-user=josif.figueroa@unb.ca

export JULIA_NUM_THREADS=16
module load julia
julia --project="." --startup-file=no "run.jl"