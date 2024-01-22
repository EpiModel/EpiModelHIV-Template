##
## 10. Epidemic Model Parameter Calibration - phase 2, Local simulation runs
##

# Settings ---------------------------------------------------------------------
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
  part.ident.start    = prep_start,
  prep.start.prob_1   = rep(0.615625, n_scenarios), # 206
  prep.start.prob_2   = rep(0.766, n_scenarios), # 237
  prep.start.prob_3   = seq(0.77, 0.79, length.out = n_scenarios), # 332
  prep.discont.int_1  = rep(107.9573, n_scenarios),
  prep.discont.int_2  = prep.discont.int_1,
  prep.discont.int_3  = prep.discont.int_1
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
