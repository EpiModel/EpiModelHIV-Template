# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/B-netsim_local/z-context.R", local = TRUE)

# Libraries  -------------------------------------------------------------------
library("EpiModelHIV")
library("dplyr")

# Necessary files --------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

# Using scenarios --------------------------------------------------------------

# Define test scenarios
n_scenarios <- 2
scenarios_df <- tibble(
  .scenario.id = as.character(seq_len(n_scenarios)),
  .at = 1,
  ugc.prob = seq(0.3225, 0.3275, length.out = n_scenarios), # best 0.325
  rgc.prob = plogis(qlogis(ugc.prob) + log(1.25)),
  uct.prob = seq(0.29, 0.294, length.out = n_scenarios), # best 0.291
  rct.prob = plogis(qlogis(uct.prob) + log(1.25))
)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control_calib_1,
  scenarios_list = scenarios_list, # set to NULL to run with default params
  n_rep = 3,
  n_cores = 2,
  output_dir = calib_dir,
  save_pattern = "simple"
)

# merge the simulations. Keeping one `tibble` per scenario
EpiModelHPC::merge_netsim_scenarios_tibble(
  sim_dir = sc_test_dir,
  output_dir = fs::path(calib_dir, "merged_tibbles"),
  steps_to_keep = year_steps * 3
)

