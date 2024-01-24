# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/B-netsim_local/z-context.R", local = TRUE)

# Libraries  -------------------------------------------------------------------
library("EpiModelHIV")
library("dplyr")

# Necessary files --------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

# Using scenarios --------------------------------------------------------------

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

EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control_calib_2,
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

