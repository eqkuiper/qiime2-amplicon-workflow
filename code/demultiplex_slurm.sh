#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 4:00:00
#SBATCH -N 1
#SBATCH -c 8                 
#SBATCH --mem=50G
#SBATCH --job-name=demultiplex
#SBATCH --output=%A-%x.out

echo "Entering snakemake env..."
module purge all
module load python-miniconda3
eval "$(conda shell.bash hook)"
conda activate /software/qiime2/2024.5-amplicon/amplicon-env/

echo "Demultiplexing paired-end reads..."
qiime cutadapt demux-paired \
--i-seqs data/qiime2_out/multiplexed-seqs.qza \
--m-forward-barcodes-file data/metadata/Osburn10_eqk_2.tsv \
--m-forward-barcodes-column barcode \
--p-error-rate 0.1 \
--o-per-sample-sequences data/qiime2_out/demux.qza \
--o-untrimmed-sequences data/qiime2_out/untrimmed.qza \
--p-mixed-orientation TRUE \
--p-anchor-forward-barcode TRUE \
--p-anchor-reverse-barcode TRUE 
echo "Demultiplexing complete!"

