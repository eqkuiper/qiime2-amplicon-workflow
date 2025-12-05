#!/bin/bash
#SBATCH -A p32449
#SBATCH -p normal                                                                                        
#SBATCH -t 48:00:00                                                                                     
#SBATCH --mem=64G
#SBATCH -n 2
#SBATCH -N 1
#SBATCH --mail-user=anurup@northwestern.edu # change to your email
#SBATCH --mail-type=END                                                                                  
#SBATCH --job-name="q2-dada2"
#SBATCH --output=%j-%x.out 

# Load QIIME2 environment
module load python-miniconda3
module load qiime2/2024.5-amplicon

# Paths
OUT_DR=data/qiime2_out

echo "[`date`] Denoising and assigning ASVs with DADA2..."

qiime --version

# denoise
echo "=== Step 1: Denoising with DADA2 ==="
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs ${OUT_DR}/demux-trimmed-no-untrimmed.qza \
  --p-trim-left-f 0 \
  --p-trim-left-r 0 \
  --p-trunc-len-f 199 \
  --p-trunc-len-r 230 \
  --p-n-threads $SLURM_NTASKS \
  --p-n-reads-learn 1000000 \
  --o-table ${OUT_DR}/asv_table.qza \
  --o-representative-sequences ${OUT_DR}/rep-seqs.qza \
  --o-denoising-stats ${OUT_DR}/denoising-stats.qza \
  --verbose

echo "=== Step 2: Tabulating metadata ==="
echo "Denoising stats"
qiime metadata tabulate \
    --m-input-file ${OUT_DR}/denoising-stats.qza \
    --o-visualization ${OUT_DR}/denoising_stats.qzv

echo "Rep seqs"
qiime metadata tabulate \
  --m-input-file ${OUT_DR}/rep-seqs.qza \
  --o-visualization ${OUT_DR}/rep_seqs.qzv

echo "Pipeline complete! Have a nice day" 

