##
## 10. Epidemic Model Parameter Calibration, Local simulation runs
##

# Libraries --------------------------------------------------------------------
library("EpiModelHIV")

# Settings ---------------------------------------------------------------------
context <- "local"
source("R/utils-0_project_settings.R")

# Run the simulations ----------------------------------------------------------

# Necessary files
source("R/utils-default_inputs.R") # generate `path_to_est`, `param` and `init`

# Controls
source("R/utils-targets.R")
control <- control_msm(
  nsteps              = calibration_end,
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = FALSE
)

# insert test values here
n_scenarios <- 2
scenarios_df <- tibble(
  # mandatory columns
  .scenario.id = as.character(seq_len(n_scenarios)),
  .at          = 1,
  # parameters to test columns
  ugc.prob     = seq(0.3225, 0.3275, length.out = n_scenarios),
  rgc.prob     = plogis(qlogis(ugc.prob) + log(1.25)),
  uct.prob     = seq(0.29, 0.294, length.out = n_scenarios),
  rct.prob     = plogis(qlogis(uct.prob) + log(1.25))
)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

# Each scenario will be run exactly 3 times using up to 3 CPU cores.
# The results are save in the "data/intermediate/test04" folder using the
# following pattern: "sim__<scenario name>__<batch number>.rds".
# See ?EpiModelHPC::netsim_scenarios for details
EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control, scenarios_list,
  n_rep = 3,
  n_cores = 3,
  output_dir = "data/intermediate/calibration",
  libraries = NULL,
  save_pattern = "simple"
)

# Check the files produced
list.files("data/intermediate/calibration")
