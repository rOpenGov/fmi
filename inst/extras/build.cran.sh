/usr/bin/R CMD BATCH document.R
#/usr/bin/R CMD build ../../ --no-build-vignettes
/usr/bin/R CMD build ../../ 
/usr/bin/R CMD check --as-cran fmi_0.1.11.tar.gz
/usr/bin/R CMD INSTALL fmi_0.1.11.tar.gz
#/usr/bin/R CMD BATCH document.R

