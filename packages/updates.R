# Set our default repo
# http://stackoverflow.com/questions/8475102/set-default-cran-mirror-permanent-in-r
options(repos=structure(c(CRAN="https://cran.rstudio.com/")))
# Update installed packages
update.packages(ask=FALSE, checkBuilt=TRUE)
