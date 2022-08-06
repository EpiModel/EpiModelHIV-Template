##
## 11. Epidemic Model Parameter Calibration, Simulations
##

# Setup ------------------------------------------------------------------------
library(EpiModel)
library(EpiModelHIV)

# Create the output directory
output_dir <- "data/output/calibration"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Necessary files
epistats <- readRDS("data/netsim_inputs/epistats.rds")
netstats <- readRDS("data/netsim_inputs/netstats.rds")
est      <- readRDS("data/netsim_inputs/netest.rds")

# Parameters
prep_start <- 65 * 52
param <- param.net(
  data.frame.params = readr::read_csv("data/input/params.csv"),
  netstats          = netstats,
  epistats          = epistats,
  prep.start        = prep_start,
  riskh.start       = prep_start - 53
)

# Initial conditions
init <- init_msm()

# Controls
source("R/utils-targets.R")
control <- control_msm(
  nsteps              = 10, #prep_start - 5 * 52,
  nsims               = 4,
  ncores              = 4,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  tracker.list        = calibration_trackers,
  verbose             = FALSE
)

# Calibration scenarios --------------------------------------------------------
scenarios_df <- tibble(
  .scenario.id = c("0", "1", "2", "3"),
  .at = 1,
  hiv.trans.scale_1	= c(4, 4.1, 4.2, 4.3),
  hiv.trans.scale_2	= c(.53, .53, .53, .53),
  hiv.trans.scale_3	= c(.33, .32, .32, .32)
)
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

# Simulation of all scenarios --------------------------------------------------
batch_num <- 1
for (scenario in scenarios_list) {
  # Apply the scenario to the parameters
  param <- use_scenario(param, scenario)

  # Simulate the scenario
  print(paste0("Starting simulation for scenario: ", scenario[["id"]]))
  sim <- netsim(est, param, init, control)

  # Save the result
  file_name <- paste0("simcalib__", scenario[["id"]], "__", batch_num, ".rds")
  print(paste0("Saving simulation in file: ", file_name))
  saveRDS(sim, paste0(output_dir, "/", file_name))
}

print("Done!")
