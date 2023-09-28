## Example interactive epidemic simulation run script with more complex
## parameterization and parameters defined in spreadsheet, with example of
## running model scenarios defined with data-frame approach

# Libraries  -------------------------------------------------------------------
library("EpiModelHIV")
library("dplyr")

# Settings ---------------------------------------------------------------------
context <- "local"
source("R/utils-0_project_settings.R")

#  -----------------------------------------------------------------------------
# Necessary files
source("R/utils-default_inputs.R") # generate `path_to_est`, `param` and `init`

# Controls
source("R/utils-targets.R")
# `nsims` and `ncores` will be overridden later
control <- control_msm(
  nsteps = year_steps * 1,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = FALSE
)

# See listing of modules and other control settings
# Module function defaults defined in ?control_msm
print(control)

# Using scenarios --------------------------------------------------------------

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

# Here 2 scenarios will be used "scenario_1" and "scenario_2".
# This will generate 6 files (3 per scenarios)
EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control,
  scenarios_list = scenarios_list, # set to NULL to run with default params
  n_rep = 3,
  n_cores = 2,
  output_dir = "data/intermediate/scenario_test",
  libraries = "EpiModelHIV",
  save_pattern = "simple"
)
fs::dir_ls("data/intermediate/scenario_test")

EpiModelHPC::merge_netsim_scenarios(
  input_dir = "data/intermediate/scenario_test",
  output_dir = "data/intermediate/scenario_test/merged_sims"
)
EpiModelHPC::merge_netsim_scenarios_tibble(
  input_dir = "data/intermediate/scenario_test",
  output_dir = "data/intermediate/scenario_test/merged_tibbles"
)

# Load one of the simulation files
sim <- readRDS("data/intermediate/scenario_test/sim__scenario_1__1.rds")
names(sim)

# Examine the model object output
print(sim)

# Plot outcomes
plot(sim, y = "i.num")
plot(sim, y = "ir100")

# Convert to data frame
df <- as_tibble(sim)
head(df)
glimpse(df)

# Clean folder
fs::dir_delete("data/intermediate/scenario_test")
