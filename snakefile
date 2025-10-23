rule preprocessing:
    input: 
        fwd="data/raw_reads/EQK-1_S2_R1_001.fastq.gz",
        rev="data/raw_reads/EQK-1_S2_R2_001.fastq.gz"
    output: 
        fwd_out="data/preformatted_reads/forward.fastq.gz",
        rev_out="data/preformatted_reads/reverse.fastq.gz"
    shell:
        """
        mkdir -p data/preformatted_reads
        cp {input.fwd} {output.fwd_out}
        cp {input.rev} {output.rev_out}
        """

rule import_seqs_as_qza:
    input: 
        "data/preformatted_reads"
    output: 
        "data/qiime2_out/multiplexed-seqs.qza"
    conda: 
        "/projects/p32449/goop_stirrers/miniconda3/envs/qiime2-amplicon"
    shell:
        """
        mkdir -p data/qiime2_out
        echo "[`date`] Importating data into Qiime2..."
        qiime tools import \
        --type MultiplexedPairedEndBarcodeInSequence \
        --input-path {input} \
        --output-path {output}
        """

rule demultipex: 
    input: 
        seqs="data/qiime2_out/multiplexed-seqs.qza",
        barcodes="
    output:
        demux="data/qiime2_out/demux.qza",
        untrimmed="data/qiime2_out/untrimmed.qza"
    conda: 
        "/projects/p32449/goop_stirrers/miniconda3/envs/qiime2-amplicon"
    rule:
        """
        qiime cutadapt demux-paired \
            --i-seqs {input.seqs} \
            --m-forward-barcodes-file {input.barcodes} \
            --m-forward-barcodes-column barcode \
            --p-error-rate 0.1 \
            --o-persample-sequences {output.demux} \
            --o-untrimmed-sequences {output.untrimmed} \
            --p-mixed-orientation TRUE \
            --p-anchor-forward-barcode TRUE \
            --p-anchor-reverse-barcode TRUE 
        """

    

