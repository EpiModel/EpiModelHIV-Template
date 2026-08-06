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
# scenario_name <- "scenario_2"
# hpc_context <- FALSE

library(EpiModelHIV)
library(dplyr)
source("R/shared_variables.R", local = TRUE)
source("R/calibration_targets.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
source("R/C-calibration/utils-restart.R", local = TRUE)

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)
targets <- project_calibration_targets()

path_df <- fs::path(
  calib_dir,
  "merged_tibbles",
  paste0("df__", scenario_name, ".rds")
)

d_calibs <- readRDS(path_df) |>
  filter(time >= max(time) - year_steps) |>
  EpiModelHIV::mutate_calibration_targets()
targets <- targets[intersect(names(targets), names(d_calibs))]

d_dist <- d_calibs |>
  select(batch_number, sim_number, any_of(names(targets))) |>
  mutate(across(names(targets), \(x) x - targets[cur_column()])) |>
  summarize(
    across(everything(), mean),
    .by = c("batch_number", "sim_number")
  ) |>
  mutate(cost = 0)

# calculate Squared Error
for (nme in names(targets)) {
  d_dist$cost <- d_dist$cost + d_dist[[nme]]^2
}

# Ensure every STI ir100 is at least 25% of the targets.
# (d_dist contains distances from targets)
for (sti in names(has_sti)) {
  if (has_sti[sti]) {
    sti_tar <- paste0("ir100.", sti)
    d_dist$cost <- ifelse(
      d_dist[[sti_tar]] < -0.75 * targets[[sti_tar]],
      Inf,
      d_dist$cost
    )
  }
}

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
  stop("`sim` file: '", sim_path, "' not present.")

restart_point <- make_restart_point_hiv(
  sim = readRDS(sim_path),
  sim_num = best_sim$sim_number
)

saveRDS(restart_point, path_to_restart)
