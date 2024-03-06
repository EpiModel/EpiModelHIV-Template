## 0. Projet Initial Setup
##
## Activate `renv` and install the required packages

# Initialize renv but do not install anything yet
renv::init(bare = TRUE)

# restart R if it has not been done automatically

source("R/shared_variables.R", local = TRUE)

# This code installs the packages only available on GitHub (not CRAN ones)
#     `rebuild = TRUE` and `dependencies = "all"` forces the installation of
#     the remote dependencies in the DESCRIPTION files
renv::install(
  packages = c(
    paste0("EpiModel/EpiModelHIV-p@", EMHIVp_branch),
    "EpiModel/EpiModelHPC"
  ),
  rebuild = TRUE,
  dependencies = "all"
)

# This code finds and install the libraries used by the project (CRAN version)
renv::hydrate(prompt = FALSE)
renv::update(prompt = FALSE)

# Force `renv` to discover the following packages
if (FALSE) {
  library("rmarkdown")
  library("pkgload")
  library("sessioninfo")
}
