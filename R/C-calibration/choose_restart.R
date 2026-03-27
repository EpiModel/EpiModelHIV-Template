## Choose Restart Point
##
##  Assess the candidates simulations for restart point, pick the best one and
##  save it in `path_to_restart`.
##
## This script should not be run directly. But `sourced` from the restart_point
## workflow

# Setup ------------------------------------------------------------------------
# library(EpiModelHIV)
source("R/shared_variables.R", local = TRUE)
pkgload::load_all(EMHIVp_dir)
library(dplyr)

hpc_context <- TRUE
source("R/C-calibration/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()
d_calibs <- fs::path(calib_dir, "merged_tibbles", "df__empty_scenario.rds")

d_dist <- readRDS(d_calibs) |>
  filter(time >= max(time) - year_steps) |>
  EpiModelHIV::mutate_calibration_distances(scaled = TRUE) |>
  select(batch_number, sim_number, any_of(names(targets)))

d_dist <- d_dist |>
  group_by(batch_number, sim_number) |>
  summarize(
    across(everything(), mean),
    .groups = "drop"
  )

d_dist$cost <- 0


# calculate Squared Error - distances are scaled by the targets value
for (nme in names(targets)) {
  if (nme %in% names(d_dist) && !any(is.na(d_dist[[nme]]))) {
    d_dist$cost <- d_dist$cost + d_dist[[nme]]
  }
}

# Ensure every STI ir100 is at least 25% of the targets.
# (d_dist contains distances from targets)
for (sti in names(has_sti)) {
  if (has_sti[sti]) {
    sti_tar <- paste0("ir100.", sti)
    d_dist$cost <- ifelse(d_dist[[sti_tar]] < -0.75, Inf, d_dist$cost)
  }
}

if (all(d_dist$cost == Inf))
  stop("No simulation has all the STI epidemics ongoing. Aborting")

# pick best sim
best_sim <- d_dist |>
  arrange(cost) |>
  select(batch_number, sim_number) |>
  head(1)

# Check the values manually
d_dist |>
  arrange(cost) |>
  head(1) |>
  as.list()

print(best_sim)

# Get best sim
best <- readRDS(
  fs::path(
    calib_dir,
    paste0("sim__empty_scenario__", best_sim$batch_number, ".rds")
  )
)

attrs_names <- names(EpiModelHIV::get_default_attrs())
time_prefixes <- c(".last$", ".time$")

time_attrs <- Reduce(
  function(a, prefix) c(a, grepv(prefix, attrs_names)),
  time_prefixes,
  init = character(0)
)

restart_point <- make_restart_point(
  best,
  time_attrs,
  sim_num = best_sim$sim_number,
  keep_steps = 1
)

saveRDS(restart_point, path_to_restart)

# Test Restart point
orig <- readRDS(path_to_restart)
control <- control_msm(
  nsims = 1,
  ncores = 1,
  start               = restart_time,
  nsteps              = restart_time + 12,
  initialize.FUN      = reinit_msm,
  verbose = TRUE
)
sim <- netsim(orig, param, init, control)
