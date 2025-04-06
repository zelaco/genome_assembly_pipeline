# Genome Assembly and Annotation Pipeline
This repository contains a list of tools to assemble and annotate bacterial genomes, with example usage. This is used primarily in WSL, but can be applied to Unix based systems too.
A bash script with an automated pipeline is also included.

## Step 1. Install Miniconda in WSL

* Download the Miniconda installer:

```
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
```

* Install:

```
bash Miniconda3-latest-Linux-x86_64.sh
```

* Follow the prompts, and restart your terminal afterward.

## Step 2. Create and Activate Conda Environment

Create a new environment, as an example, it will be called `genome_analysis`:

```
conda create -n genome_analysis python=3.9
```

Activate it:

```
conda activate genome_analysis
```

## Step 3. Install Necessary Tools

Set channel priorities clearly (to avoid conflicts) and install the software to use:

```
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda config --set channel_priority strict

conda install fastqc fastp spades checkm-genome prokka
```

## Step 4. Quality Control with FastQC

Check the raw reads quality:

```
fastqc *.fq.gz
```

## Step 5. Trimming and QC Improvement with fastp

Trim adapters and poor-quality bases:

```
fastp -i reads_R1.fq.gz -I reads_R2.fq.gz \
      -o reads_R1_trimmed.fq.gz -O reads_R2_trimmed.fq.gz \
      -h trimming_report.html
```

## Step 6. Genome Assembly with SPAdes

Assemble the genome:

```
spades.py -1 reads_R1_trimmed.fq.gz -2 reads_R2_trimmed.fq.gz \
          -o genome_assembly 
```

## Step 7. Assembly Quality Check with CheckM

Check quality and completeness:

* CheckM:

```
checkm lineage_wf -x fasta checkm_input/ checkm_output/
```
or (using Klebsiella as an example):
```
checkm taxonomy_wf genus Klebsiella -x fasta checkm_input/ checkm_output/
```

## Step 8. Annotation with Prokka

Annotate the genome:

```
prokka --outdir annotation_results --prefix genome_name \
       genome_assembly/contigs.fasta
```
