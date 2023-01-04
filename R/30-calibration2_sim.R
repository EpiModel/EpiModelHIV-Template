##
## 10. Epidemic Model Parameter Calibration - phase 2, Local simulation runs
##

# Setup ------------------------------------------------------------------------
context <- "local"
source("R/utils-0_project_settings.R")

# Run the simulations ----------------------------------------------------------
library("EpiModelHIV")

# Necessary files
source("R/utils-default_inputs.R") # generate `path_to_est`, `param` and `init`

# Controls
source("R/utils-targets.R")
control <- control_msm(
  start               = restart_time,
  nsteps              = intervention_start,
  nsims               = 1,
  ncores              = 1,
  initialize.FUN      = reinit_msm,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = FALSE
)

# insert test values here
n_scenarios <- 2
scenarios_df <- tibble(
  .scenario.id = as.character(seq_len(n_scenarios)),
  .at                 = 1,
  prep.start.prob_1   = seq(0.28, 0.31, length.out = n_scenarios),
  prep.start.prob_2   = prep.start.prob_1,
  prep.start.prob_3   = prep.start.prob_1,
  prep.discont.rate_1 = rep(0.021, n_scenarios),
  prep.discont.rate_2 = prep.discont.rate_1,
  prep.discont.rate_3 = prep.discont.rate_1
)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

# Each scenario will be run exactly 3 times using up to 3 CPU cores.
# The results are save in the "data/intermediate/test04" folder using the
# following pattern: "sim__<scenario name>__<batch number>.rds".
# See ?EpiModelHPC::netsim_scenarios for details
EpiModelHPC::netsim_scenarios(
  path_to_restart, param, init, control, scenarios_list,
  n_rep = 3,
  n_cores = 3,
  output_dir = "data/intermediate/calibration",
  libraries = NULL,
  save_pattern = "simple"
)

# Check the files produced
list.files("data/intermediate/calibration")
