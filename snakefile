rule all:
    input:
        # preprocessed reads
        fwd_out="data/preformatted_reads/forward.fastq.gz",
        rev_out="data/preformatted_reads/reverse.fastq.gz",
        # qza
        multiplexed="data/qiime2_out/multiplexed-seqs.qza",
        # demultiplex
        out_sample_seqs="data/qiime2_out/demux.qza",
        untrimmed_seqs="data/qiime2_out/untrimmed.qza",
        # demultiplex vis
        demux_vis="data/qiime2_out/demux.qzv",
        # trim
        trimmed="data/qiime2_out/demux-trimmed-no-untrimmed.qza",
        # trim vis
        trimmed_vis="data/qiime2_out/demux-trimmed-no-untrimmed.qzv",
        # denoising 
        rep_seqs="data/qiime2_out/rep-seqs.qza",
        table="data/qiime2_out/rep-seqs.qza",
        denoising="data/qiime2_out/denoising-stats.qza",
        # classify 
        classification="data/qiime2_out/taxonomy-GTDBr220.qza",
        # build tree
        alignment="data/qiime2_out/rep-seqs-aligned.qza",
        masked_alignment="data/qiime2_out/rep-seqs-aligned-masked.qza",
        tree="data/qiime2_out/unrooted-tree.qza",
        rooted_tree="data/qiime2_out/rooted-tree.qza"

rule preprocessing:
    input: 
        fwd="data/raw_reads/EQK-1_S2_R1_001.fastq.gz",
        rev="data/raw_reads/EQK-1_S2_R2_001.fastq.gz"
    output: 
        fwd_out="data/preformatted_reads/forward.fastq.gz",
        rev_out="data/preformatted_reads/reverse.fastq.gz"
    shell: 
        """
        mkdir -p $(dirname {output.fwd_out})
        cp {input.fwd} {output.fwd_out}
        cp {input.rev} {output.rev_out}
        """

rule import_seqs_as_qza:
    input:
        fwd="data/preformatted_reads/forward.fastq.gz",
        rev="data/preformatted_reads/reverse.fastq.gz"
    output: 
        multiplexed="data/qiime2_out/multiplexed-seqs.qza"
    shell: 
        """
        module load python-miniconda3
        module load qiime2/2024.5-amplicon

        qiime tools import \
        --type MultiplexedPairedEndBarcodeInSequence \
        --input-path data/preformatted_reads \
        --output-path {output.multiplexed}
        """

rule demultiplex:
    input:
        input_seqs="data/qiime2_out/multiplexed-seqs.qza",
        barcodes_file="data/metadata/Osburn10-EQK.tsv"
    output:
        out_sample_seqs="data/qiime2_out/demux.qza",
        untrimmed_seqs="data/qiime2_out/untrimmed.qza"
    resources:
        slurm_account="p32449",
        slurm_partition="normal",
        runtime=24*60, 
        nodes=1,
        mem_mb=16000,
        slurm_extra="--mail-user=esmee@u.northwestern.edu --mail-type=END,FAIL"
    shell: 
        """
        module load python-miniconda3
        module load qiime2/2024.5-amplicon

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
        """
    
rule demultiplex_summarize:
    input:
        demux="data/qiime2_out/demux.qza"
    output:
        demux_vis="data/qiime2_out/demux.qzv"
    shell:
        """
        module load python-miniconda3
        module load qiime2/2024.5-amplicon

        qiime demux summarize \
        --i-data {input.demux} \
        --o-visualization {output.demux_vis}
        """

rule trim_primers:
    input:
        demux="data/qiime2_out/demux.qza"
    output:
        trimmed="data/qiime2_out/demux-trimmed-no-untrimmed.qza"
    threads: 8
    shell:
        """
        module load python-miniconda3
        module load qiime2/2024.5-amplicon

        qiime cutadapt trim-paired \
        --i-demultiplexed-sequences {input.demux} \
        --p-front-f GTGYCAGCMGCCGCGGTAA \
        --p-front-r CCGYCAATTYMTTTRAGTTT \
        --p-match-read-wildcards \
        --p-cores {threads} \
        --p-discard-untrimmed \
        --o-trimmed-sequences {output.trimmed} \
        --verbose
        """

rule trim_vis:
    input:
        trimmed="data/qiime2_out/demux-trimmed-no-untrimmed.qza"
    output:
        trimmed_vis="data/qiime2_out/demux-trimmed-no-untrimmed.qzv"
    shell:
        """
        module load python-miniconda3
        module load qiime2/2024.5-amplicon

        qiime demux summarize \
        --i-data {input.trimmed} \
        --o-visualization {output.trimmed_vis}
        """

rule dada2_denoise:
    input:
        trimmed="data/qiime2_out/demux-trimmed-no-untrimmed.qza"
    output:
        rep_seqs="data/qiime2_out/rep-seqs.qza",
        table="data/qiime2_out/asv_table.qza",
        denoising="data/qiime2_out/denoising-stats.qza"
    shell:
        """
        module load python-miniconda3
        module load qiime2/2024.5-amplicon

        qiime dada2 denoise-paired \
        --i-demultiplexed-seqs {input.trimmed} \
        --p-trim-left-f 0 \
        --p-trim-left-r 0 \
        --p-trunc-len-f 199 \
        --p-trunc-len-r 230 \
        --p-n-reads-learn 1000000 \
        --o-table {output.table} \
        --o-representative-sequences {output.rep_seqs} \
        --o-denoising-stats {output.denoising} \
        --verbose
        """

rule classify:
    input:
        classifier="/projects/p31618/databases/gtdb220/gtdb_classifier_r220.qza",
        reads="data/qiime2_out/rep-seqs.qza"
    output:
        classification="data/qiime2_out/taxonomy-GTDBr220.qza"
    shell:
        """
        module load python-miniconda3
        module load qiime2/2024.5-amplicon

        qiime feature-classifier classify-sklearn \
        --i-classifier {input.classifier} \
        --i-reads {input.reads} \
        --o-classification {output.classification}
        """

rule metadata_tabulate:
    input:
        classification="data/qiime2_out/taxonomy-GTDBr220.qza"
    output:
        classification_vis="data/qiime2_out/taxonomy-GTDBr220.qzv"
    shell:
        """
        module load python-miniconda3
        module load qiime2/2024.5-amplicon

        qiime metadata tabulate \
        --m-input-file {input.classification} \
        --o-visualization {output.classification_vis}
        """

rule build_tree:
    input:
        seqs="data/qiime2_out/rep-seqs.qza"
    output:
        alignment="data/qiime2_out/rep-seqs-aligned.qza",
        masked_alignment="data/qiime2_out/rep-seqs-aligned-masked.qza",
        tree="data/qiime2_out/unrooted-tree.qza",
        rooted_tree="data/qiime2_out/rooted-tree.qza"
    shell:
        """
        module load python-miniconda3
        module load qiime2/2024.5-amplicon

        qiime phylogeny align-to-tree-mafft-fasttree \
        --i-sequences {input.seqs} \
        --o-alignment {output.alignment} \
        --o-masked-alignment {output.masked_alignment} \
        --o-tree {output.tree} \
        --o-rooted-tree {output.rooted_tree} \
        --verbose
        """