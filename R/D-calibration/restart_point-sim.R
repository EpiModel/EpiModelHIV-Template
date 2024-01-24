# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/B-netsim_local/z-context.R", local = TRUE)

# Libraries  -------------------------------------------------------------------
library("EpiModelHIV")
library("dplyr")

# Necessary files --------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

# Using scenarios --------------------------------------------------------------
EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control_calib_1,
  scenarios_list = NULL,
  n_rep = 3,
  n_cores = 2,
  output_dir = calib_dir,
  save_pattern = "all"
)

