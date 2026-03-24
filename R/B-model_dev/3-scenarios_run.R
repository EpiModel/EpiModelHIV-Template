## 3. Epidemic Model Scenarios Playground
##
## Run `netsim` via the scenario API. This mimics how things will be run on the
## HPC later on and ensure a smooth transition to the HPC setup.
##
## This script only runs the simulation. The outputs are explored in the script
## 2-scenarios_assess.R

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)

source("R/shared_variables.R", local = TRUE)
source("R/B-model_dev/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

# Necessary files
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  nsteps = year_steps * 4
)

# Controls
# `nsims` and `ncores` will be overridden later

print(control)


# Define test scenarios
# Each row is one scenario. Required columns:
#   .scenario.id  — unique name (used in output filenames)
#   .at           — time step at which parameter changes are applied
# All other columns are parameter names with their new values.
# Valid parameter names are those in data/input/model_parameters.csv or any
# argument accepted by param.net().
scenarios_df <- tibble(
  .scenario.id    = c("scenario_1", "scenario_2"),
  .at             = 1,
  gono.uret.prob  = c(0.25, 0.3),
  chla.uret.prob  = c(0.25, 0.3),
  syph.prob       = c(0.15, 0.2)
)

glimpse(scenarios_df)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

# Run all scenarios. Each scenario is replicated `n_rep` times (independent
# simulations) to quantify stochastic variability. Replicates are saved in
# batches of up to `n_cores` per file. With n_rep = 3 and n_cores = 2, each
# scenario produces 2 files (a batch of 2 and a batch of 1).
EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control,
  scenarios_list = scenarios_list, # set to NULL to run with default params
  n_rep = 3,                       # number of replications per scenario
  n_cores = 2,
  output_dir = scenarios_dir
)
fs::dir_ls(scenarios_dir)

# Merge all batches into one tibble per scenario.
# `steps_to_keep` controls how many time steps are retained (from the end of
# the simulation). Keeping fewer steps saves memory.
EpiModelHPC::merge_netsim_scenarios_tibble(
  sim_dir = scenarios_dir,
  output_dir = fs::path(scenarios_dir, "merged_tibbles"),
  steps_to_keep = year_steps * 1 # keep only the last year
)
