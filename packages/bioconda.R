options(repos=structure(c(CRAN="https://cran.rstudio.com/")))

# bioconductor base
source("http://bioconductor.org/biocLite.R")
biocLite()

# bioconductor packages
biocLite("edgeR")
biocLite("Rgraphviz")
biocLite("biomaRt")
biocLite("topGO")
biocLite("limma")
biocLite("DESeq2")
biocLite("cummeRbund")
biocLite("Biostrings")
biocLite("GenomicRanges")
biocLite("Rsamtools")
