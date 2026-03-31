## Choose Restart Point
##
##  Assess the candidates simulations for restart point, pick the best one and
##  save it in `path_to_restart`.
##
## This script should not be run directly. But `sourced` from the restart_point
## workflow

# Setup ------------------------------------------------------------------------
scenario_name <- "empty_scenario"
hpc_context <- TRUE

library(EpiModelHIV)
library(dplyr)
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
source("R/C-calibration/utils-restart.R", local = TRUE)

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()
path_df <- fs::path(
  calib_dir,
  "merged_tibbles",
  paste0("df__", scenario_name, ".rds")
)

d_dist <- readRDS(path_df) |>
  group_by(batch_number, sim_number) |>
  mutate_sim_cost(has_sti, year_steps)

if (all(d_dist$cost == Inf))
  stop("No simulation has all the STI epidemics ongoing. Aborting")

# pick best sim
best_sim <- d_dist |>
  arrange(cost) |>
  head(1)

glimpse(best_sim)

sim_path <- fs::path(
  calib_dir,
  paste0("sim__", scenario_name, "__", best_sim$batch_number, ".rds")
)

if (!fs::file_exists(sim_path))
  stop("`sim` file: '", sim_path, "' not present. Download it from HPC")

restart_point <- make_restart_point_hiv(
  sim = readRDS(sim_path),
  sim_num = best_sim$sim_number,
  sim_cost = best_sim$cost
)

saveRDS(restart_point, path_to_restart)
