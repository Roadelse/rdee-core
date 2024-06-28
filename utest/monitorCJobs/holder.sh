#!/bin/bash
#SBATCH --job-name=helloworld
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --partition=normal

if [[ -n "$SLURM_NTASKS" ]]; then
    echo "Submitted to SLURM with $SLURM_NTASKS tasks"
fi

sleep 100

