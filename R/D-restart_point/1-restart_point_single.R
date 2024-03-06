## 1. Epidemic Restart Point
##
## Generate an uncalibrated restart point to test the next part of the models
## before the calibration is finished

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)

source("R/shared_variables.R", local = TRUE)
source("R/D-restart_point/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

# Necessary files
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  nsteps = calibration_end,
  .tracker.list = EpiModelHIV::make_calibration_trackers()
)

# Using no scenarios
EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control,
  scenarios_list = NULL,
  n_rep = 1,
  n_cores = 1,
  output_dir = calib_dir,
  save_pattern = "all" # required to make a restart point
)

best <- readRDS(fs::path(calib_dir, "sim__empty_scenario__1.rds"))
best <- EpiModel::get_sims(best, 1)

# Remove all epi except `num`
best$epi <- list(
  num = best$epi$num,
  sim.num = best$epi$sim.num
)

saveRDS(best, path_to_restart)

