## 1. Intervention Scenarios Playground
##
## Example interactive epidemic simulation run script with more complex
## parameterization and parameters defined in spreadsheet, with example of
## running model scenarios defined with data-frame approach

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)

source("R/shared_variables.R", local = TRUE)
source("R/F-intervention_scenarios/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

# Necessary files
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  start               = restart_time,
  nsteps              = intervention_end,
  initialize.FUN      = reinit_msm,
  verbose             = FALSE
)

# Define test scenarios
scenarios_df <- readr::read_csv("data/input/scenarios.csv")

glimpse(scenarios_df)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

EpiModelHPC::netsim_scenarios(
  path_to_restart, param, init, control,
  scenarios_list = scenarios_list,
  n_rep = 8,
  n_cores = 4,
  output_dir = scenarios_dir,
  save_pattern = "simple"
)
fs::dir_ls(scenarios_dir)

# merge the simulations. Keeping one `tibble` per scenario
EpiModelHPC::merge_netsim_scenarios_tibble(
  sim_dir = scenarios_dir,
  output_dir = fs::path(scenarios_dir, "merged_tibbles"),
  steps_to_keep = intervention_end - intervention_start
)

# Convert to data frame
d_path <- fs::dir_ls(fs::path(scenarios_dir, "merged_tibbles"))[[1]]
d_sim <- readRDS(d_path)

glimpse(d_sim)
head(d_sim)

## Clean folder
# fs::dir_delete(sc_test_dir)
