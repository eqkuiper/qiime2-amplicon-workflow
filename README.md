# Amplicon Workflow

snakemake analysis of 16S rRNA gene sequencing reads using Qiime2

## How to use this workflow
New to snakemake? No problem! Simply follow these steps :) 
1) Install snakemake into a fresh conda/mamba environment
```
mamba create -n snakemake
mamba activate snakemake
mamba install bioconda::snakemake
```
2) Create a fresh folder for each project and copy over the snakefile and profiles directory.
2) Adjust your slurm preferences in config.yaml (should be in "profiles" dir). It should look something like this:
```
executor: slurm
latency-wait: 10
use-conda: True  

default-resources:
  slurm_account: <your quest allocation> <- change this
  slurm_partition: "short"
  runtime: 240
  #cpus_per_task: 16
  mem_mb: 8000
  nodes: 1
  slurm_extra: "--mail-user=yourEmail@u.northwestern.edu --mail-type=END" <- change this

slurm-logdir: "/projects/your allocation/project folder/slurm_logs" <- change this
```
3) Import your raw reads and metadata into directories under data named raw_reads and metadata, respectively.
4) Run by typing the following in command line:
```
snakemake --profile profiles --jobs <some number of jobs>
```
The number of jobs corresponds directly to the number of steps (called rules in snakemake) you're running. So if you are running everything straight through you will need as many jobs as there are rules. But if you're just running the last step, you'll need two jobs (one for the last step, the other for rule "all").