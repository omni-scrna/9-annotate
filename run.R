#!/usr/bin/env Rscript


# arg parsing
source("src/common/cli.R")
p <- arg_parser("ANNO module")
p <- add_base_args(p)                    # --output_dir, --name
p <- add_stage_args(p, "ANNO")     # the stage I/O contract
# your own method params — argparser directly (its add_argument requires `help`):
p <- add_argument(p, "--number_selected", type = "integer", help = "number of PCs")
args <- parse_args(p)                    # argparser's own parser

# logging
cat(sprintf("Full command: %s\n", paste(commandArgs(trailingOnly = FALSE), collapse = " ")))
cat(sprintf("LOG: command line args\n----------------------------------\n"))
for (i in 1:length(args)) {
  cat(sprintf("  %s: %s\n", names(args)[i], args[[i]]))
}
cat(sprintf("----------------------------------\n"))


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
  out <- file.path(args$output_dir, paste0(args$name, "_annotations.tsv"))
  cat("output_file:", out, "\n")
  fwrite(data.frame(cell_id = rownames(prediction), prediction$labels), out, 
         sep = "\t", quote = FALSE, row.names = FALSE)
  cat(sprintf("  wrote: %s\n", out))
}


annotate_cells(args)
