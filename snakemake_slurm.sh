#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 4:00:00
#SBATCH -N 1
#SBATCH -c 8                 
#SBATCH --mem=50G
#SBATCH --job-name=snakemake
#SBATCH --output=%A-%x.out

# USER INPUTS
snake_dir=/projects/p32449/amplicon-analysis
snakemake_env=/projects/p32449/goop_stirrers/miniconda3/envs/snakemake
rule=demultiplex
#

# Activate snakemake environment
echo "Entering snakemake env..."
module purge all
module load python-miniconda3
eval "$(conda shell.bash hook)"
conda activate $snakemake_env

# Run snakemake
snakemake $rule --cores $SLURM_CPUS_PER_TASK --use-conda --conda-frontend conda

# Check exit status
if [[ $? -eq 0 ]]; then
    echo "Snakemake completed successfully!"
else
    echo "Snakemake encountered an error."
    exit 1
fi