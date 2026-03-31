source("R/shared_variables.R", local = TRUE)
library(EpiModelHIV)
library(dplyr)

hpc_context <- TRUE
source("R/C-calibration/z-context.R", local = TRUE)

mutate_sim_cost <- function(d, has_sti, year_steps) {
  targets <- EpiModelHIV::get_calibration_targets()

  d <- d |>
    filter(time >= max(time) - year_steps) |>
    EpiModelHIV::mutate_calibration_distances(scaled = TRUE) |>
    select(any_of(names(targets))) |>
    summarize(across(everything(), mean), .groups = "drop") |>
    mutate(cost = 0)

  # calculate Squared Error - distances are scaled by the targets value
  for (nme in names(targets)) {
    if (nme %in% names(d_dist) && !any(is.na(d_dist[[nme]]))) {
      d_dist$cost <- d_dist$cost + d_dist[[nme]]^2 / length(targets)
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

  d
}

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
