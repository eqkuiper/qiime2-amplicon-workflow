rule preprocessing:
    input: 
        fwd="data/raw_reads/EQK-1_S2_R1_001.fastq.gz",
        rev="data/raw_reads/EQK-1_S2_R2_001.fastq.gz"
    output: 
        fwd_out="data/preformatted_reads/forward.fastq.gz",
        rev_out="data/preformatted_reads/reverse.fastq.gz"
    shell: """
    mkdir -p data/preformatted_reads
cp {input.fwd} {output.fwd_out}
cp {input.rev} {output.rev_out}
"""

rule import_seqs_as_qza:
    input:
        fwd="data/preformatted_reads/forward.fastq.gz",
        rev="data/preformatted_reads/reverse.fastq.gz"
    output: 
        "data/qiime2_out/multiplexed-seqs.qza"
    conda: 
        "/projects/p32449/goop_stirrers/miniconda3/envs/qiime2-amplicon"
    shell: """
echo "Importating data into Qiime2..."
qiime tools import \
--type MultiplexedPairedEndBarcodeInSequence \
--input-path data/preformatted_reads \
--output-path {output}
"""

rule demultiplex:
    input:
        input_seqs="data/qiime2_out/multiplexed-seqs.qza",
        barcodes_file="data/metadata/Osburn10_eqk.tsv"
    output:
        out_sample_seqs="data/qiime2_out/demux.qza",
        untrimmed_seqs="data/qiime2_out/untrimmed.qza"
    conda:
         "/projects/p32449/goop_stirrers/miniconda3/envs/qiime2-amplicon"
    shell: """
echo "Demultiplexing paired-end reads..."
qiime cutadapt demux-paired \
--i-seqs {input.input_seqs} \
--m-forward-barcodes-file {input.barcodes_file} \
--m-forward-barcodes-column "barcode" \
--p-error-rate 0.1 \
--o-per-sample-sequences {output.out_sample_seqs} \
--o-untrimmed-sequences {output.untrimmed_seqs} \
--p-mixed-orientation TRUE \
--p-anchor-forward-barcode TRUE \
--p-anchor-reverse-barcode TRUE 
echo "Demultiplexing complete!"
"""
    

