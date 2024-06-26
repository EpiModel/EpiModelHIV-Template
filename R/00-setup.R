## 0. Projet Initial Setup
##
## Activate `renv` and install the required packages

# Initialize renv but do not install anything yet
renv::init(bare = TRUE)

# restart R if it has not been done automatically

source("R/shared_variables.R", local = TRUE)

# This code installs the packages only available on GitHub (not CRAN ones)
renv::install(c(
  paste0("EpiModel/EpiModelHIV-p@", EMHIVp_branch),
  "EpiModel/EpiModelHPC",
  "EpiModel/ARTnet"
))

# This code finds and install the libraries used by the project (CRAN version)
renv::hydrate(prompt = FALSE)
renv::update(prompt = FALSE)

# Snapshot the list of installed packages to the `renv.lock` file
renv::snapshot()

# Force `renv` to discover the following packages
if (FALSE) {
  library("rmarkdown")
  library("pkgload")
  library("sessioninfo")
}

fs::file_copy(
  system.file("model_parameters.xlsx", package = "EpiModelHIV"),
  fs::path(input_dir, "model_parameters.xlsx")
)
