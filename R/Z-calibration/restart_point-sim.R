# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
context <- "local"

# Libraries  -------------------------------------------------------------------
library("EpiModelHIV")
library("dplyr")

# Necessary files --------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  nsteps = calibration_end
)

# Using scenarios --------------------------------------------------------------
EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control_calib_1,
  scenarios_list = NULL,
  n_rep = 1,
  n_cores = 1,
  output_dir = calib_dir,
  save_pattern = "all"
)

