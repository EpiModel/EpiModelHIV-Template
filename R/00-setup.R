# Initialize renv but do not install anything yet
renv::init(bare = TRUE)

# restart R

# This code installs the packages only available on GitHub (not CRAN ones)
renv::install(c(
  "EpiModel/EpiModelHIV-p@applied_proj",
  "EpiModel/EpiModelHPC"
))

# This code finds and install the libraries used by the project (CRAN version)
renv::hydrate()

# Force `renv` to discover the following packages
if (FALSE) {
  library("rmarkdown")
  library("pkgload")
  library("sessioninfo")
}
