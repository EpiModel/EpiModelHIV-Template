## Choose Restart Point
##
##  Assess the candidates simulations for restart point, pick the best one and
##  save it in `path_to_restart`.
##
## This script should not be run directly. But `sourced` from the restart_point
## workflow

# for each merged_tibble
#   make calibration targets
#   calc q1, q2, q3
#   combine calib_vals
#
#   make calibration dist
#   calc q1, q2, q3
#   combine calib_dists
#

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)

hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/Z-calibration/z-context.R", local = TRUE)

calib_steps <- year_steps

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()
d_calibs <- fs::path(calib_dir, "merged_tibbles", "df__empty_scenario.rds")

d_dist <- readRDS(d_calibs) |>
  dplyr::filter(time >= max(time) - calib_steps) |>
  EpiModelHIV::mutate_calibration_distances() |>
  dplyr::select(batch_number, sim, dplyr::any_of(names(targets)))

d_dist <- d_dist |>
  dplyr::group_by(batch_number, sim) |>
  dplyr::summarize(
    dplyr::across(dplyr::everything(), mean),
    .groups = "drop"
  )

d_dist$cost <- 0

# calc squared error
for (nme in names(targets)) {
  if (nme %in% names(d_dist) && !any(is.na(d_dist[[nme]]))) {
    d_dist$cost <- d_dist$cost + d_dist[[nme]]^2
  }
}

# pick best sim
best_sim <- d_dist |>
  dplyr::arrange(cost) |>
  dplyr::select(batch_number, sim) |>
  head(1)

# Check the values manually
d_dist |>
  dplyr::arrange(cost) |>
  head(1) |>
  as.list()

# Get best sim
best <- readRDS(fs::path(
  calib_dir,
  paste0("sim__empty_scenario__", best_sim$batch_number, ".rds"))
)

best <- EpiModel::get_sims(best, best_sim$sim)

# Remove all epi except `num`
best$epi <- list(
  num = best$epi$num,
  sim.num = best$epi$sim.num
)

saveRDS(best, path_to_restart)

