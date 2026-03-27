## 3. Epidemic Model Scenarios Playground
##
## Run `netsim` via the scenario API. This mimics how things will be run on the
## HPC later on and ensures a smooth transition to the HPC setup.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)

source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

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
  prep.start.rate_1 = param$prep.start.rate_1 * ors,
  prep.start.rate_2 = param$prep.start.rate_2 * ors,
  prep.start.rate_3 = param$prep.start.rate_3 * ors,
  hiv.test.rate_1 = param$hiv.test.rate_1 * ors,
  hiv.test.rate_2 = param$hiv.test.rate_2 * ors,
  hiv.test.rate_3 = param$hiv.test.rate_3 * ors,
  tx.halt.rate_1 = param$tx.halt.rate_1 * ors,
  tx.halt.rate_2 = param$tx.halt.rate_2 * ors,
  tx.halt.rate_3 = param$tx.halt.rate_3 * ors,
  hiv.trans.scale_1 = param$hiv.trans.scale_1 * ors,
  hiv.trans.scale_2 = param$hiv.trans.scale_2 * ors,
  hiv.trans.scale_3 = param$hiv.trans.scale_3 * ors,
  gono.uret.prob = param$gono.uret.prob * ors,
  chla.uret.prob = param$chla.uret.prob * ors,
  syph.prob      = param$syph.prob * ors,
  aids.off.tx.mort.rate = param$aids.off.tx.mort.rate * ors,
  a.rate = param$a.rate * ors
)

glimpse(scenarios_df)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control,
  scenarios_list = scenarios_list,
  n_rep = 8,
  n_cores = 8,
  output_dir = calib_dir
)

EpiModelHPC::merge_netsim_scenarios_tibble(
  sim_dir = calib_dir,
  output_dir = fs::path(calib_dir, "merged_tibbles"),
  steps_to_keep = Inf
)

source("R/C-calibration/process_calibs.R")

