## 0. Project Initial Setup
##
## Run this script step by step in a fresh R session.
## Do NOT source the whole file at once — there is a required restart in the
## middle.

## Step 1: Initialize renv ----
## This sets up package version management for the project and installs the
## required packages using the "renv.lock" file.
##
## With pixi, always start R from the project root through pixi (`pixi run R`,
## `pixi run Rscript ...`), first `pixi install`. renv then installs only the
## packages pixi does not provide (the GitHub ones and hetGP); renv's
## "required system packages are not installed" warning is spurious there,
## pixi ships those libraries.
renv::init()

## >>> RESTART R NOW (Ctrl+Shift+F10 in RStudio) before continuing <<<

## Step 2: Install packages ----------------------------------------------------
source("R/shared_variables.R", local = TRUE)

# Two setups share this script and `renv.lock`:
# - pixi + renv (local, `pixi run R`): pixi provides R and the CRAN packages,
#   renv only installs what is below (the pixi library stays visible because
#   `pixi.toml` disables the renv sandbox).
# - spack + renv (default HPC): renv installs every package, CRAN ones
#   included, from the same lockfile.

# Install ergmkit first: EpiModelHIV imports it. It builds its Rust engine at
# install time, so cargo and rustc (>= 1.85) must be on the PATH (pixi ships
# them).
renv::install("EpiModel/ergmkit-R")

# Install the correct version of EpiModelHIV-p for your project
renv::install(paste0("AdrienLeGuillou/EpiModelHIV-p@", EMHIVp_branch))

renv::install(c(
  "EpiModel/EpiModel",
  "EpiModel/ARTnetData",
  "EpiModel/ARTnet",
  "EpiModel/EpiModelHPC@restart_pool_review", # EpiModelHPC PR #74
  "EpiModel/slurmworkflow@feature/step-child-shell", # slurmworkflow PR #37
  "EpiModel/swfcalib",
  "hetGP" # CRAN, not on conda-forge
))

# Lock the installed package versions
renv::snapshot()

## Parameters: nothing to copy. The model reads its defaults from the
## `model_parameters.csv` shipped with EpiModelHIV, then applies the project
## overrides in "data/input/model_parameters.csv" (see `read_model_params()` in
## "R/netsim_settings.R").

## Step 3: Verify ARTnetData access --------------------------------------------
## This line will error if you don't have access to ARTnetData.
## If it does, ask a lab member for access.
library(ARTnetData)

## Manually install all dependencies
# source("R/shared_variables.R", local = TRUE)
# renv::install(
#   paste0(
#     "epimodel/",
#     c("artnetdata", "epimodelhpc", "slurmworkflow", "swfcalib",
#        paste0("EpiModel/EpiModelHIV-p@", EMHIVp_branch))
#   )
# )
# renv::hydrate()
