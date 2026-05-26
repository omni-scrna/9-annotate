#!/usr/bin/env Rscript

library(argparse)

# Parse command line arguments
parser <- ArgumentParser(description="OmniBenchmark module")

# Required by OmniBenchmark
parser$add_argument("--output_dir", dest="output_dir", type="character", required=TRUE,
                   help="Output directory for results")
parser$add_argument("--name", dest="name", type="character", required=TRUE,
                   help="Module name/identifier")
# Stage-specific inputs
parser$add_argument("--normalized_selected.h5", dest="normalized_selected_h5",
                   type="character", nargs="+", required=TRUE,
                   help="Input: normalized_selected.h5")
parser$add_argument("--reference", dest="reference_type", 
                    type="character", help="Input file")

args <- parser$parse_args()

cat("Output directory:", args$output_dir, "\n")
cat("Module name:", args$name, "\n")
cat("normalized_selected.h5:", args$normalized_selected_h5, "\n")
cat("clusters.tsv:", args$clusters_tsv, "\n")

# TODO: Implement your module logic
# Process the data using main function
annotate_cells <- function(args){
  require("HDF5Array")
  require("Matrix")
  require("celldex") 
  require("SingleR")
  require("data.table")
  #load the expression Matrix - adapted from https://github.com/omni-scrna/scrapper/blob/main/pca.R
  m <- TENxMatrix(args$normalized_selected_h5, group = "matrix")
  m <- as(m, "dgCMatrix") # read into memory
  #load the reference - coded along the `singleR` vignettes
  #https://www.bioconductor.org/packages/release/bioc/vignettes/SingleR/inst/doc/SingleR.html
  if(args$reference == "HumanPrimaryCellAtlasData"){
    ref <- HumanPrimaryCellAtlasData()
  }else if(args$reference == "BlueprintEncodeData"){
    ref <- BlueprintEncodeData()
  }
  prediction <- SingleR(test = m, ref = ref, assay.type.test=1,
    labels = ref$label.main)

  #adapted from https://github.com/omni-scrna/scrapper/blob/main/pca.R
  out <- file.path(args$output_dir, sprintf("%s_prediction_labels.tsv", args$name))
  cat("output_file:", out, "\n")
  fwrite(data.frame(cell_id = rownames(prediction), prediction$labels), out, 
         sep = "\t", quote = FALSE, row.names = FALSE)
  cat(sprintf("  wrote: %s\n", out))
}


annotate_cells(args)
