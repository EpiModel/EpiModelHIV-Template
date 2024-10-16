## 0. Projet Initial Setup
##
## Activate `renv` and install the required packages

# Initialize renv and install the packages logged in the `renv.lock` file
renv::init()

# restart R if it has not been done automatically

source("R/shared_variables.R", local = TRUE)

# This code installs the correct version of EpiModelHIV-p for your project
renv::install(paste0("EpiModel/EpiModelHIV-p@", EMHIVp_branch))

# Snapshot the list of installed packages to the `renv.lock` file
renv::snapshot()

# Get the initial set of parameters from EpiModelHIV-p
fs::file_copy(
  system.file("model_parameters.csv", package = "EpiModelHIV"),
  fs::path(input_dir, "model_parameters.csv"),
  overwrite = TRUE
)

