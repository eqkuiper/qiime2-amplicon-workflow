#!/bin/bash
#SBATCH -A p32449
#SBATCH -p normal                                                                                        
#SBATCH -t 2:00:00                                                                                     
#SBATCH --mem=48G
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --mail-user=esmee@northwestern.edu # change to your email
#SBATCH --mail-type=END                                                                                  
#SBATCH --job-name="import_demux_cutadapt"
#SBATCH --output=%j-%x.out

# Load QIIME2 environment
module load python-miniconda3
module load qiime2/2024.5-amplicon

# Paths
RAW_FWD="/projects/p32449/amplicon-analysis-shell/data/raw_reads/EQK-1_S2_R1_001.fastq.gz"
RAW_REV="/projects/p32449/amplicon-analysis-shell/data/raw_reads/EQK-1_S2_R2_001.fastq.gz"
PREPROC_DIR="/projects/p32449/amplicon-analysis-shell/data/preformatted_reads"
QIIME2_OUT="/projects/p32449/amplicon-analysis-shell/data/qiime2_out"
BARCODES="/projects/p32449/amplicon-analysis-shell/data/metadata/Osburn10-EQK.tsv"

# Make output directories
mkdir -p "${PREPROC_DIR}" "${QIIME2_OUT}"

echo "=== Step 1: Preprocessing (copy raw reads) ==="
cp "${RAW_FWD}" "${PREPROC_DIR}/forward.fastq.gz"
cp "${RAW_REV}" "${PREPROC_DIR}/reverse.fastq.gz"

echo "=== Step 2: Import sequences into QIIME2 as multiplexed ==="
qiime tools import \
  --type MultiplexedPairedEndBarcodeInSequence \
  --input-path "${PREPROC_DIR}" \
  --output-path "${QIIME2_OUT}/multiplexed-seqs.qza"

echo "=== Step 3: Demultiplex sequences ==="
qiime cutadapt demux-paired \
  --i-seqs "${QIIME2_OUT}/multiplexed-seqs.qza" \
  --m-forward-barcodes-file "${BARCODES}" \
  --m-forward-barcodes-column "barcode" \
  --p-error-rate 0.1 \
  --o-per-sample-sequences "${QIIME2_OUT}/demux.qza" \
  --o-untrimmed-sequences "${QIIME2_OUT}/untrimmed.qza" \
  --p-mixed-orientation TRUE \
  --p-anchor-forward-barcode TRUE \
  --p-anchor-reverse-barcode TRUE \
  --verbose \
  --p-cores 4

echo "=== Step 4: Summarize demultiplexed sequences ==="
qiime demux summarize \
  --i-data "${QIIME2_OUT}/demux.qza" \
  --o-visualization "${QIIME2_OUT}/demux.qzv" 

echo "=== Step 5: Trim primers ==="
qiime cutadapt trim-paired \
  --i-demultiplexed-sequences "${QIIME2_OUT}/demux.qza" \
  --p-front-f GTGYCAGCMGCCGCGGTAA \
  --p-front-r CCGYCAATTYMTTTRAGTTT \
  --p-match-read-wildcards \
  --p-cores 8 \
  --p-discard-untrimmed \
  --o-trimmed-sequences "${QIIME2_OUT}/demux-trimmed-no-untrimmed.qza" \
  --verbose

echo "=== Step 6: Summarize trimmed sequences ==="
qiime demux summarize \
  --i-data "${QIIME2_OUT}/demux-trimmed-no-untrimmed.qza" \
  --o-visualization "${QIIME2_OUT}/demux-trimmed-no-untrimmed.qzv"

echo "Pipeline complete!"
