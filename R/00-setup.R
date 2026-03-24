## 0. Project Initial Setup
##
## Run this script step by step in a fresh R session.
## Do NOT source the whole file at once — there is a required restart in the
## middle.

## Step 1: Initialize renv ----
## This sets up package version management for the project and install the
## required packages using the "renv.lock" file.
renv::init()

## >>> RESTART R NOW (Ctrl+Shift+F10 in RStudio) before continuing <<<

## Step 2: Install packages ----
source("R/shared_variables.R", local = TRUE)

# Install the correct version of EpiModelHIV-p for your project
renv::install(paste0("EpiModel/EpiModelHIV-p@", EMHIVp_branch))

# Lock the installed package versions
renv::snapshot()

## Step 3: Copy the default parameter file ----
fs::file_copy(
  system.file("model_parameters.csv", package = "EpiModelHIV"),
  fs::path(input_dir, "model_parameters.csv"),
  overwrite = TRUE
)

## Step 4: Verify ARTnetData access ----
## This line will error if you don't have access to ARTnetData.
## If it does, ask a lab member for access.
library(ARTnetData)

## Manually install all dependencies
# renv::install(
#   paste0(
#     "epimodel/", c("artnetdata", "epimodelhpc", "slurmworkflow", "swfcalib")
#   )
# )
# renv::hydrate()
