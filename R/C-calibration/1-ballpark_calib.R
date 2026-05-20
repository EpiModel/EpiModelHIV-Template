## 1. Ballpark Calibration (local)
##
## Local equivalent of `workflow-ballpark_calib.R`. Explore parameter grids
## locally and produce simulations that can be used by `3-choose_restart.R`
## to create a restart point.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)

source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

n_cores <- 4
# Process ----------------------------------------------------------------------

# Necessary files
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  nsteps = calibration_end
)

n_scenarios <- 3
ors_calib <- seq(0.7, 1.3, length.out = n_scenarios)
scenarios_df <- tibble(
  .scenario.id = paste0("scenario_", seq_len(n_scenarios)),
  .at = 1,
  prep.start.rate_1 = param$prep.start.rate[[1]] * ors_calib,
  prep.start.rate_2 = param$prep.start.rate[[2]] * ors_calib,
  prep.start.rate_3 = param$prep.start.rate[[3]] * ors_calib,
  hiv.test.rate_1 = param$hiv.test.rate[[1]] * ors_calib,
  hiv.test.rate_2 = param$hiv.test.rate[[2]] * ors_calib,
  hiv.test.rate_3 = param$hiv.test.rate[[3]] * ors_calib,
  tx.halt.rate_1 = param$tx.halt.rate[[1]] * ors_calib,
  tx.halt.rate_2 = param$tx.halt.rate[[2]] * ors_calib,
  tx.halt.rate_3 = param$tx.halt.rate[[3]] * ors_calib,
  hiv.trans.scale_1 = param$hiv.trans.scale[[1]] * ors_calib,
  hiv.trans.scale_2 = param$hiv.trans.scale[[2]] * ors_calib,
  hiv.trans.scale_3 = param$hiv.trans.scale[[3]] * ors_calib,
  gono.uret.prob = param$gono.uret.prob * ors_calib,
  chla.uret.prob = param$chla.uret.prob * ors_calib,
  syph.prob      = param$syph.prob * ors_calib,
  aids.off.tx.mort.rate = param$aids.off.tx.mort.rate * ors_calib,
  a.rate = param$a.rate * ors_calib
)

glimpse(scenarios_df)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control,
  scenarios_list = scenarios_list,
  n_rep = n_cores,
  n_cores = n_cores,
  output_dir = calib_dir
)

EpiModelHPC::merge_netsim_scenarios_tibble(
  sim_dir = calib_dir,
  output_dir = fs::path(calib_dir, "merged_tibbles"),
  steps_to_keep = Inf
)

# Process the calibration to give the mean (sd) deviance from the target in %
# of the target
source("R/C-calibration/process_calibs.R")
