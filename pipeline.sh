#!/bin/bash

MAIN_DIR="Genomes/"
OUTPUT_DIR="Results/"
ASSEMBLIES_DIR="$OUTPUT_DIR/All_Assemblies"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$ASSEMBLIES_DIR"

for GENOME_DIR in "$MAIN_DIR"/*; do
  if [[ -d "$GENOME_DIR" ]]; then
    GENOME_NAME=$(basename "$GENOME_DIR")
    echo "Processing $GENOME_NAME..."

    GENOME_OUTPUT_DIR="$OUTPUT_DIR/$GENOME_NAME"
    mkdir -p "$GENOME_OUTPUT_DIR/fastqc"

    READS_1=$(find "$GENOME_DIR" -name "*_1.fq.gz")
    READS_2=$(find "$GENOME_DIR" -name "*_2.fq.gz")

    if [[ -n "$READS_1" && -n "$READS_2" ]]; then
      fastqc "$READS_1" "$READS_2" -o "$GENOME_OUTPUT_DIR/fastqc"

      fastp -i "$READS_1" -I "$READS_2" \
            -o "$GENOME_OUTPUT_DIR/${GENOME_NAME}_1_trimmed.fq.gz" \
            -O "$GENOME_OUTPUT_DIR/${GENOME_NAME}_2_trimmed.fq.gz" \
            -h "$GENOME_OUTPUT_DIR/trimming_report.html"

      ASSEMBLY_DIR="$GENOME_OUTPUT_DIR/spades_assembly"
      spades.py -1 "$GENOME_OUTPUT_DIR/${GENOME_NAME}_1_trimmed.fq.gz" \
                -2 "$GENOME_OUTPUT_DIR/${GENOME_NAME}_2_trimmed.fq.gz" \
                --careful -o "$ASSEMBLY_DIR" -t 8 -m 32

      if [[ -s "$ASSEMBLY_DIR/contigs.fasta" ]]; then
        # Filter contigs shorter than 500 bp
        awk '/^>/{if(length(seq)>=500) print h ORS seq; h=$0; seq=""} \
             !/^>/{seq=seq$0} END{if(length(seq)>=500) print h ORS seq}' \
             "$ASSEMBLY_DIR/contigs.fasta" > "$ASSEMBLY_DIR/contigs_filtered.fasta"

        # Prepare input folder for CheckM
        CHECKM_INPUT="$GENOME_OUTPUT_DIR/checkm_input/$GENOME_NAME"
        mkdir -p "$CHECKM_INPUT"
        cp "$ASSEMBLY_DIR/contigs_filtered.fasta" "$CHECKM_INPUT/contigs_filtered.fasta"

        # Run CheckM contamination check
        checkm lineage_wf -x fasta \
          "$GENOME_OUTPUT_DIR/checkm_input/" \
          "$GENOME_OUTPUT_DIR/checkm_output/" \
          -t 8

        # Annotation with Prokka
        prokka --outdir "$GENOME_OUTPUT_DIR/prokka_annotation" \
               --prefix "${GENOME_NAME}_annotated" \
               --kingdom Bacteria "$ASSEMBLY_DIR/contigs_filtered.fasta"

        # Copy filtered contigs to centralized folder
        cp "$ASSEMBLY_DIR/contigs_filtered.fasta" "$ASSEMBLIES_DIR/${GENOME_NAME}_contigs_filtered.fasta"

        echo "Completed processing $GENOME_NAME."
      else
        echo "Warning: Assembly failed for $GENOME_NAME."
      fi
    else
      echo "Warning: Reads not found for $GENOME_NAME."
    fi
  fi
done

echo "Genome assembly, filtering, QC, contamination check, and annotation pipeline completed for all genomes."
