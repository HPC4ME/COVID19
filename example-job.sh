#!/bin/bash
#SBATCH --job-name=protein-ligand
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00

#SBATCH --account=e793-wbattell

#SBATCH --partition=standard
#SBATCH --qos=standard

# Run the job

echo "This file was created by submitting a job to the queue" > output.txt

sleep 60s
