# Set our default repo
# http://stackoverflow.com/questions/8475102/set-default-cran-mirror-permanent-in-r
options(repos=structure(c(CRAN="http://cran.rstudio.com/")))
# Install some packages
install.packages('RCurl')
install.packages('XML')
install.packages('yaml')
install.packages('/tmp/GalaxyConnector.tar.gz', repos=NULL, type="source")
