#!/usr/bin/env bash
#SBATCH --partition=genoa
#SBATCH --job-name=dti_workflow
#SBATCH --time=02-00:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4GB
#SBATCH --output=logs/nesi/%j-%x.out
#SBATCH --error=logs/nesi/%j-%x.out
#SBATCH --dependency=singleton

# exit on errors, undefined variables and errors in pipes
set -euo pipefail

# load environment modules
module purge
#module load Mamba/23.1.0-1 
#module load Apptainer/1.1.9 
module load snakemake/7.32.3-gimkl-2022a-Python-3.11.3
module load Miniforge3

# ensure user's local Python packages are not overriding Python module packages
export PYTHONNOUSERSITE=1

# parent folder for cache directories
NOBACKUPDIR="/nesi/nobackup/$SLURM_JOB_ACCOUNT/$USER"

# configure conda cache directory
#conda config --add pkgs_dirs "$NOBACKUPDIR/conda_pkgs"

# ensure conda channel priority is strict (otherwise environment may no be built)
#conda config --set channel_priority strict

# deactivate any conda environment already activate (e.g. base environment)
source $(conda info --quiet --base)/etc/profile.d/conda.sh
conda deactivate

# configure apptainer build and cache directories
export APPTAINER_CACHEDIR="$NOBACKUPDIR/apptainer_cachedir"
export APPTAINER_TMPDIR="$NOBACKUPDIR/apptainer_tmpdir"
mkdir -p "$APPTAINER_CACHEDIR" "$APPTAINER_TMPDIR"
setfacl -b "$APPTAINER_TMPDIR"  # avoid apptainer issues due to ACLs set on this folder

# run snakemake using the NeSI profile
snakemake \
    --profile profiles/nesi \
    --workflow-profile profiles/nesi \
    --config account="$SLURM_JOB_ACCOUNT" \
    "$@"
