##
## 20. Epidemic Model Restart Point, Local simulation runs
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
  nsteps              = calibration_end,
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = FALSE
)

# No scenarios are used here

EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control,
  scenarios_list = NULL,
  n_rep = 3,
  n_cores = 3,
  output_dir = "data/intermediate/calibration",
  libraries = NULL,
  save_pattern = "restart" # more data is required to allow restarting
)

# Check the files produced
list.files("data/intermediate/calibration")
