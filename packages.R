# Set our default repo
# http://stackoverflow.com/questions/8475102/set-default-cran-mirror-permanent-in-r
options(repos=structure(c(CRAN="https://cran.rstudio.com/")))
# Update installed packages
update.packages(ask=FALSE, checkBuilt=TRUE)
# Install some packages
install.packages(c('devtools'))

if(Sys.getenv(x = "RSTUDIO_FULL", unset="0") == "1") {
    install.packages(c('RCurl', 'XML', 'markdown', 'shiny', 'ggvis', 'dplyr',
                       'ggplot2', 'plyr', 'reshape2', 'RODBC',
                       'maps', 'pheatmap', 'readr', 'tidyr', 'dplyr',
                       'RJSONIO', 'shinyapps', 'knitr'))

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
    biocLite("affy")
}
