## Example interactive epidemic simulation run script with more complex
## parameterization and parameters defined in spreadsheet, with example of
## running model scenarios defined with data-frame approach

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/F-intervention_scenarios/z-context.R", local = TRUE)

# Libraries  -------------------------------------------------------------------
library("EpiModelHIV")
library("dplyr")

# Necessary files --------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  start               = restart_time,
  nsteps              = intervention_end,
  initialize.FUN      = reinit_msm,
  verbose             = FALSE
)

# Using scenarios --------------------------------------------------------------

# Define test scenarios
scenarios_df <- readr::read_csv("./data/input/scenarios.csv")

glimpse(scenarios_df)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

# Where to save the output of these tests
sc_test_dir <- "data/intermediate/scenarios_test"

# Here 2 scenarios will be used "scenario_1" and "scenario_2".
# This will generate 6 files (3 per scenarios)
EpiModelHPC::netsim_scenarios(
  path_to_restart, param, init, control,
  scenarios_list = scenarios_list, # set to NULL to run with default params
  n_rep = 3,
  n_cores = 2,
  output_dir = sc_test_dir,
  save_pattern = "simple"
)
fs::dir_ls(sc_test_dir)

# merge the simulations. Keeping one `tibble` per scenario
EpiModelHPC::merge_netsim_scenarios_tibble(
  sim_dir = sc_test_dir,
  output_dir = fs::path(sc_test_dir, "merged_tibbles"),
  steps_to_keep = intervention_end - intervention_start
)

# Convert to data frame
d_sim <- readRDS(fs::path(sc_test_dir, "merged_tibbles", "df__scenario_1.rds"))

glimpse(d_sim)
head(d_sim)

## Clean folder
# fs::dir_delete(sc_test_dir)
