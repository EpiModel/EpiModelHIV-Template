# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/D-restart_point/z-context.R", local = TRUE)

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
  path_to_est, param, init, control,
  scenarios_list = NULL,
  n_rep = 1,
  n_cores = 1,
  output_dir = calib_dir,
  save_pattern = "all"
)

best <- readRDS(fs::path(calib_dir, "sim__empty_scenario__1.rds"))
best <- EpiModel::get_sims(best, 1)
epi_num <- best$epi$num

# Remove all epi except `num`
best$epi <- list(num = epi_num)

saveRDS(best, path_to_restart)

