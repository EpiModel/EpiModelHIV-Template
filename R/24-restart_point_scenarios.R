# Settings ---------------------------------------------------------------------
context <- "local"
source("R/utils-0_project_settings.R")

# Run the simulations ----------------------------------------------------------
library("EpiModelHIV")

# Necessary files
source("R/utils-default_inputs.R") # generate `path_to_restart`, `param`, `init`

# Controls
source("R/utils-targets.R")
control <- control_msm(
  start               = restart_time,
  nsteps              = intervention_end,
  nsims               = 1,
  ncores              = 1,
  initialize.FUN      = reinit_msm,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = TRUE
)

# Using scenarios --------------------------------------------------------------

# Define test scenarios
scenarios_df <- tibble(
  .scenario.id    = c("scenario_1", "scenario_2"),
  .at             = prep_start,
  hiv.test.rate_1 = c(0.004, 0.005),
  hiv.test.rate_2 = c(0.004, 0.005),
  hiv.test.rate_3 = c(0.007, 0.008)
)

glimpse(scenarios_df)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

# Here 2 scenarios will be used "scenario_1" and "scenario_2".
# This will generate 4 files (2 per scenarios)
EpiModelHPC::netsim_scenarios(
  path_to_restart, param, init, control, scenarios_list,
  n_rep = 3,
  n_cores = 2,
  output_dir = "data/intermediate/scenario_test",
  libraries = "EpiModelHIV",
  save_pattern = "simple"
)
list.files("data/intermediate/scenario_test")
unlink("data/intermediate/scenario_test")
