#!/usr/bin/env Rscript

library(argparse)

# Source main functions
source("src/main.R")

# Parse command line arguments
parser <- ArgumentParser(description="OmniBenchmark module")

# Required by OmniBenchmark
parser$add_argument("--output_dir", dest="output_dir", type="character", required=TRUE,
                   help="Output directory for results")
parser$add_argument("--name", dest="name", type="character", required=TRUE,
                   help="Module name/identifier")
# Stage-specific inputs
parser$add_argument("--pcas.tsv", dest="pcas_tsv",
                   type="character", nargs="+", required=TRUE,
                   help="Input: pcas.tsv")
parser$add_argument("--normalized_selected.h5", dest="normalized_selected_h5",
                   type="character", nargs="+", required=TRUE,
                   help="Input: normalized_selected.h5")
parser$add_argument("--clusters.tsv", dest="clusters_tsv",
                   type="character", nargs="+", required=TRUE,
                   help="Input: clusters.tsv")

args <- parser$parse_args()

cat("Output directory:", args$output_dir, "\n")
cat("Module name:", args$name, "\n")
cat("pcas.tsv:", args$pcas_tsv, "\n")
cat("normalized_selected.h5:", args$normalized_selected_h5, "\n")
cat("clusters.tsv:", args$clusters_tsv, "\n")

# TODO: Implement your module logic
# Process the data using main function
process_data(args)
