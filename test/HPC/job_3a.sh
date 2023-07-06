#!/bin/bash
#SBATCH --time=0-12:00:00
#SBATCH --nodes=8
#SBATCH --cpus-per-task=50
#SBATCH --mem=0
#SBATCH --mail-type=end
#SBATCH --mail-user=josif.figueroa@unb.ca

# Load the required modules
module load julia/1.8.5
module load gurobi/10.0.2

# Set the number of threads
export JULIA_NUM_THREADS=50

echo "file run_3a.jl"
echo ""
echo "Starting job!!! ${SLURM_JOB_ID} on partition ${SLURM_JOB_PARTITION}"
echo ""
echo "NUM_THREADS=$SLURM_CPUS_PER_TASK"
echo "NUM_NODES=$SLURM_JOB_NUM_NODES"
echo ""
julia -p $SLURM_JOB_NUM_NODES --project="." --startup-file=no "run_3a.jl"