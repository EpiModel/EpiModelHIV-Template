## 0. Projet Initial Setup
##
## Activate `renv` and install the required packages

# This script should be run in a fresh R session
rs()

# Setup ------------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)

# Process ----------------------------------------------------------------------
#
## Setup `renv` for the project and install the necessary packages
source("R/shared_variables.R", local = TRUE)

# Initialize renv but do not install anything yet
renv::init(bare = TRUE)

# restart R
rs()

# This code installs the packages only available on GitHub (not CRAN ones)
renv::install(c(
  paste0("EpiModel/EpiModelHIV-p@", EMHIVp_branch),
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
