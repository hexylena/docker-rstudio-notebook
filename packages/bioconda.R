options(repos=structure(c(CRAN="https://cran.rstudio.com/")))

# bioconductor base
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install()

# bioconductor packages
BiocManager::install(c("edgeR", "Rgraphviz", "biomaRt", "topGO", "limma", "DESeq2", "cummeRbund", "Biostrings", "GenomicRanges", "Rsamtools"))
