#!/bin/bash

# Plot the developmental expression pattern for a particular gene from RNA-seq
# expression data downloaded from the BrainSpan Developmental Transcriptome.
#
# Usage:
#     plot_human_developmental_expression <gene> [<brain_regions>]
#
# e.g. plot_human_developmental_expression ARID1B 
#          DFC,VFC,MFC,OFC,M1C,S1C,A1C,IPC,STC,ITC,V1C
#
# Dependencies:
# - uses csvcut from csvkit:
#     http://csvkit.readthedocs.org/en/latest/index.html

# If specified, REGIONS should be a comma separated list of structure acronyms
# corresponding to values in field 7 of the downloaded file
# "columns_metadata.csv"
GENE=$1
REGIONS=$2

DATA_DIR=data

# Download RPKM values for all genes from BrainSpan
if [ ! -d "$DATA_DIR" ]; then
    DATA_FILE=267666525

    wget http://www.brainspan.org/api/v2/well_known_file_download/$DATA_FILE
    unzip $DATA_FILE

    mkdir $DATA_DIR
    mv *.csv $DATA_DIR
    rm readme.txt
    rm $DATA_FILE
fi

# Extract all expression values for the specified gene
GENE_METADATA=$DATA_DIR/rows_metadata.csv
GENE_ROWNUM=$(grep "\"$GENE\"" data/rows_metadata.csv | cut -d , -f 1)

ALL_GENES_EXPRESSION=$DATA_DIR/expression_matrix.csv
GENE_EXPRESSION=expression.csv
grep "^${GENE_ROWNUM}," $ALL_GENES_EXPRESSION | cut -d , -f 1 --complement > $GENE_EXPRESSION

# Extract only those expression values for desired brain regions and join the
# gene expression and samples data together.
SAMPLES_METADATA=$DATA_DIR/columns_metadata.csv
EXPRESSION_TEMP_FILE=expression_tmp.csv
SAMPLES_TEMP_FILE=samples_tmp.csv

if [ -n "$REGIONS" ]; then
    SEARCH_STRING="\\\"${REGIONS//,/\\\"\\|\\\"}\\\""
    grep $SEARCH_STRING $SAMPLES_METADATA > $SAMPLES_TEMP_FILE

    EXPRESSION_FIELDS=$(csvcut -d , -c 1 $SAMPLES_TEMP_FILE | tr '\n' ',')
    EXPRESSION_FIELDS=${EXPRESSION_FIELDS%,}
    csvcut -d , -c $EXPRESSION_FIELDS $GENE_EXPRESSION | tr ',' '\n' > $EXPRESSION_TEMP_FILE
else
    # In this case, just remove the header line of the samples file 
    tail -n +2 $SAMPLES_METADATA > $SAMPLES_TEMP_FILE

    cat $GENE_EXPRESSION | tr ',' '\n' > $EXPRESSION_TEMP_FILE
fi

paste -d , $SAMPLES_TEMP_FILE $EXPRESSION_TEMP_FILE > $GENE_EXPRESSION
rm $SAMPLES_TEMP_FILE $EXPRESSION_TEMP_FILE

# Finally plot a developmental time course of RPKM values for gene expression.
# For the plot to be in any way valid, this assumes that the BrainSpan RPKM
# values have been normalised between samples using spike-in RNA - but it's
# quite unclear from the documentation whether this has actually taken place:
#
# http://help.brain-map.org/download/attachments/3506181/Transcriptome_Profiling.pdf
#
# There has also been no correction for possible batch effects (e.g. see
# Extended in Experimental Procedures in Parikshak et al., "Integrative
# Functional Genomic Analyses Implicate Specific Molecular Pathways and
# Circuits in Autism", Cell (2013), which used the same data).

Rscript bin/R/plot_developmental_expression.R $GENE_EXPRESSION $GENE
rm $GENE_EXPRESSION
