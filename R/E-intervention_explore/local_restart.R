# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/B-netsim_local/z-context.R", local = TRUE)

# Libraries  -------------------------------------------------------------------
library("EpiModelHIV")
library("dplyr")

# Necessary files --------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

# Using scenarios --------------------------------------------------------------

scenarios_df <- readr::read_csv("./data/input/scenarios.csv")

EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control_restart,
  scenarios_list = scenarios_list, # set to NULL to run with default params
  n_rep = 3,
  n_cores = 2,
  output_dir = scenarios_dir,
  save_pattern = "simple"
)

# merge the simulations. Keeping one `tibble` per scenario
EpiModelHPC::merge_netsim_scenarios_tibble(
  sim_dir = scenarios_dir,
  output_dir = fs::path(scenarios_dir, "merged_tibbles"),
  steps_to_keep = year_steps * 10
)

# Convert to data frame
d_sim <- readRDS(fs::path(scenarios_dir, "merged_tibbles", "df__scenario_1.rds"))

glimpse(d_sim)
head(d_sim)

