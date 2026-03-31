library(dplyr)

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
    if (nme %in% names(d) && !any(is.na(d[[nme]]))) {
      d$cost <- d$cost + d[[nme]]^2 / length(targets)
    }
  }

  # Ensure every STI ir100 is at least 25% of the targets.
  # (d contains distances from targets)
  for (sti in names(has_sti)) {
    if (has_sti[sti]) {
      sti_tar <- paste0("ir100.", sti)
      d$cost <- ifelse(d[[sti_tar]] < -0.75, Inf, d$cost)
    }
  }

  d
}

make_restart_point_hiv <- function(sim, sim_num, sim_cost = Inf) {
  attrs_names <- names(EpiModelHIV::get_default_attrs())
  time_prefixes <- c(".last$", ".time$")

  time_attrs <- Reduce(
    function(a, prefix) c(a, grepv(prefix, attrs_names)),
    time_prefixes,
    init = character(0)
  )

  restart_point <- make_restart_point(sim, time_attrs, sim_num, keep_steps = 1)
  restart_point[["_calibration_cost"]] <- sim_cost

  restart_point
}
