## 1. Epidemic Model Scenarios Playground
##
## Run `netsim` via the scenario API. This mimics how things will be run on the
## HPC later on and ensure a smooth transition to the HPC setup.

# This script should be run in a fresh R session
rs()

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)

source("R/shared_variables.R", local = TRUE)
source("R/C-netsim_scenarios/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

# Necessary files
prep_start <- 2 * year_steps
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  nsteps = prep_start + year_steps * 3
)

# Controls
# `nsims` and `ncores` will be overridden later

print(control)


# Define test scenarios
scenarios_df <- tibble(
  .scenario.id    = c("scenario_1", "scenario_2"),
  .at             = 1,
  hiv.test.rate_1 = c(0.004, 0.005),
  hiv.test.rate_2 = c(0.004, 0.005),
  hiv.test.rate_3 = c(0.007, 0.008)
)

glimpse(scenarios_df)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

# Where to save the output of these tests
sc_test_dir <- "data/intermediate/scenarios_test"

# Here 2 scenarios will be used "scenario_1" and "scenario_2".
# This will generate 6 files (3 per scenarios)
EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control,
  scenarios_list = scenarios_list, # set to NULL to run with default params
  n_rep = 3,
  n_cores = 2,
  output_dir = sc_test_dir,
  save_pattern = "all"
)
fs::dir_ls(sc_test_dir)

# merge the simulations. Keeping one `tibble` per scenario
EpiModelHPC::merge_netsim_scenarios_tibble(
  sim_dir = sc_test_dir,
  output_dir = fs::path(sc_test_dir, "merged_tibbles"),
  steps_to_keep = year_steps * 1
)

# Convert to data frame
d_sim <- readRDS(fs::path(sc_test_dir, "merged_tibbles", "df__scenario_1.rds"))

glimpse(d_sim)
head(d_sim)

## Clean folder
# fs::dir_delete(sc_test_dir)
