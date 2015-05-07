# Set our default repo
# http://stackoverflow.com/questions/8475102/set-default-cran-mirror-permanent-in-r
options(repos=structure(c(CRAN="http://cran.rstudio.com/")))
# Update installed packages
update.packages(ask=FALSE, checkBuilt=TRUE)
# Install some packages
install.packages('RCurl')
install.packages('XML')
install.packages('/tmp/GalaxyConnector.tar.gz', repos=NULL, type="source")

# addition from base image:

# RODBC
install.packages('RODBC')

# bioconductor base
source("http://bioconductor.org/biocLite.R")
biocLite()

# bioconductor packages
biocLite("edgeR")
biocLite("Rgraphviz")

