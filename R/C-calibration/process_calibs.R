## Process Calibration
##
## Generate a light calibration assessement file to be downloaded locally to
## check the manual calibration advancement.
##
## For each target the mean distance to the target value is reported (positive
## means too high and negative too low)
##
## `calib_tolerance.csv` says whether each target is within its tolerance, the
## rule for stopping a calibration after its confirmation run
## (`target_tolerance()` in `R/calibration_targets.R`):
##   - care-cascade proportions (`cc.*`): 1 percentage point
##   - every other target: 10% of the target
## Its `fitted` column is TRUE for the targets a wave of the calibration fits
## (`fitted_targets`, which `workflow-swfcalib.R` passes from
## `swfcalib_config.R`); the others are checks. The stop rule and the printed
## summary count only the fitted targets. Callers without waves (the ballpark
## and restart workflows) leave `fitted` empty, and every target counts.
##
## `calib_sti_checks.csv` adds two checks on the bacterial STIs that the
## tolerance rule does not make: the share of runs in which each has died out
## (no infection in the final year), and, if the project gives one
## (`project_calibration_incidence_guard()`), its mean true incidence against
## the range a calibrated model should not leave. A mean that meets its target
## as an average of extinct and persisting runs is not a fit.
##
## `calib_drift.csv` checks that the model is at rest at the targets, not
## passing through them on a sloped path (EpiModelHIV-p#374): see
## `drift_table()`.
##
## This script should be called by one of the manual_calibration workflows.

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)
library(tidyr)

source("R/shared_variables.R", local = TRUE)
source("R/calibration_targets.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
source("R/netsim_settings.R", local = TRUE)

# Callers may or may not set this: workflow-swfcalib.R does not, the ballpark
# and restart workflows do.
if (!exists("n_cores")) {
  n_cores <- 8
}
if (!exists("fitted_targets")) {
  fitted_targets <- NULL
}

# Process ----------------------------------------------------------------------

# Runs that start from the same restart-pool member are not independent, so
# the drift intervals are clustered on it. EpiModelHPC gives simulation k pool
# member ((k - 1) %% pool size) + 1. A probe run passes the pool its runs
# started from as `cluster_pool`.
if (!exists("cluster_pool")) cluster_pool <- path_to_restart_pool
pool_index_file <- fs::path(cluster_pool, "pool_index.csv")
n_pool <- if (fs::file_exists(pool_index_file)) {
  nrow(read.csv(pool_index_file))
} else {
  NA_integer_
}

#' Drift of each target at the end of the runs.
#'
#' Fit is not the same as rest (EpiModelHIV-p#374): a target met in passing on
#' a sloped path moves once the run goes on, and the parameter fitted to it
#' absorbs wherever the run happened to stop. For each target, the slope of
#' each run's annual means over the final `fit_window` years, per decade,
#' averaged over runs, with a 95% interval clustered on the restart-pool
#' member. `mde` is the smallest drift the runs resolve, 2.8 standard errors
#' (80% power at the 5% level). A target is at rest if its drift is within
#' `max_drift` tolerances per decade or its interval includes zero.
#'
#' Diagnosed HIV prevalence by race is not fitted (the HIV wave fits the
#' diagnosis rates), but it integrates the slowest mode of the HIV epidemic
#' and is about ten times less noisy than the diagnosis rates, so it is the
#' sentinel for that mode: over the same window it must change by less than
#' `max_prev_drift` of its own level per decade. The relative bound judges a
#' 45 percent stratum and a 3 percent stratum alike.
#'
#' The window and bounds come from the first-pass confirmations of a four-city
#' calibration (November 2026). 256 runs resolved 0.25 tolerances per decade
#' over 20 years for every fitted target but P&S syphilis, and over 10 years
#' for fewer than half of one city's targets. The window must stay inside the
#' last 50 years, since a change in arrivals or mortality reshapes the age
#' structure over the 50-year age span. In one city, fitted HIV diagnosis rates
#' drifted 0.15 to 0.23 tolerances per decade on a mode with a time constant of
#' 35 years or more, which only the sentinel caught (prevalence rising 2.1 to
#' 3.3 percent of its level per decade); 1 percent per decade on a 40-year mode
#' leaves about 0.4 tolerances of a diagnosis rate still to come.
#'
#' @param d_full A merged tibble with at least the final `fit_window` years.
#' @param targets,tol Named targets and their tolerances.
#'
#' @return One row per measure, or `NULL` if the runs are too short.
drift_table <- function(d_full, targets, tol, fit_window = 20,
                        max_drift = 0.25, max_prev_drift = 0.01) {
  t_end <- max(d_full$time)
  if (t_end - min(d_full$time) + 1 < fit_window * year_steps) return(NULL)
  prev_names <- paste0("i.prev.dx.", c("B", "H", "W"))

  d <- d_full |>
    filter(time > t_end - fit_window * year_steps) |>
    EpiModelHIV::mutate_calibration_targets() |>
    mutate(yr = fit_window - floor((t_end - time) / year_steps))
  measures <- intersect(c(names(targets), prev_names), names(d))
  d_year <- d |>
    summarize(across(all_of(measures), \(x) mean(x, na.rm = TRUE)),
              .by = c("sim", "yr"))
  cluster <- if (is.na(n_pool)) d_year$sim else (d_year$sim - 1) %% n_pool + 1
  d_year$cluster <- cluster

  slope <- function(y, x) {
    x <- x - mean(x)
    sum(x * (y - mean(y))) / sum(x^2)
  }
  one <- function(m) {
    b <- d_year |>
      filter(!is.na(.data[[m]])) |>
      summarize(b = 10 * slope(.data[[m]], yr), .by = c("sim", "cluster"))
    cm <- tapply(b$b, b$cluster, mean)
    se <- stats::sd(cm) / sqrt(length(cm))
    # Prevalence against its own mean level; every other target against its
    # tolerance
    scale <- if (m %in% prev_names) mean(d_year[[m]], na.rm = TRUE) else
      tol[[m]]
    tibble(measure = m, window_years = fit_window,
           drift_per_decade = mean(b$b),
           lower = mean(b$b) - 1.96 * se, upper = mean(b$b) + 1.96 * se,
           scale = scale, drift_scaled = mean(b$b) / scale,
           mde_scaled = 2.8 * se / scale)
  }
  bind_rows(lapply(measures, one)) |>
    mutate(
      scale_kind = if_else(measure %in% prev_names, "level", "tolerance"),
      bound = if_else(measure %in% prev_names, max_prev_drift, max_drift),
      resolved = mde_scaled <= bound,
      at_rest = if_else(
        measure %in% prev_names,
        abs(drift_scaled) < bound,
        abs(drift_scaled) <= bound | (lower <= 0 & upper >= 0)
      )
    )
}

process_one_calib_tibble <- function(sc_info, calib_steps) {
  targets <- project_calibration_targets()

  d_full <- readRDS(sc_info$file_path)
  d_raw <- d_full |>
    filter(time >= max(time) - calib_steps) |>
    EpiModelHIV::mutate_calibration_targets()
  d_dist <- select(d_raw, sim, any_of(names(targets)))

  targets <- targets[intersect(names(targets), names(d_dist))]

  d_dist <- d_dist |>
    mutate(across(names(targets), \(x) x - targets[cur_column()])) |>
    summarize(across(everything(), mean), .by = c("sim")) |>
    select(-c(sim))

  fmtr <- scales::label_scientific(3)

  mean_dist <- vapply(d_dist, mean, numeric(1))
  tol <- target_tolerance(targets)
  d_tol <- tibble(
    scenario_name = sc_info$scenario_name,
    target = names(targets),
    target_value = unname(targets),
    model_mean = unname(targets + mean_dist[names(targets)]),
    difference = unname(mean_dist[names(targets)]),
    tolerance = unname(tol),
    within = !is.na(difference) & abs(difference) <= tolerance
  )

  d_assess <- d_dist |>
    summarize(across(everything(), \(x) fmtr(mean(x)))) |>
    mutate(
      scenario_name = sc_info$scenario_name,
    ) |>
    select(scenario_name, everything())

  # True incidence over the scoring window; fade-out on the final year only,
  # since an epidemic that died in year 66 is gone
  sti_true <- intersect(c("ir100.gono", "ir100.chla", "ir100.syph"),
                        names(d_raw))
  d_sti <- d_raw |>
    select(sim, all_of(sti_true)) |>
    summarize(across(everything(), mean), .by = "sim")
  d_sti_end <- d_raw |>
    filter(time > max(time) - year_steps) |>
    select(sim, all_of(sti_true)) |>
    summarize(across(everything(), mean), .by = "sim")
  guard <- project_calibration_incidence_guard()
  guard_end <- function(m, i) {
    if (m %in% names(guard)) guard[[m]][i] else NA_real_
  }
  d_sti_check <- tibble(
    scenario_name = sc_info$scenario_name,
    measure = sti_true,
    true_incidence = vapply(sti_true, \(m) mean(d_sti[[m]]), numeric(1)),
    fadeout_share = vapply(sti_true, \(m) mean(d_sti_end[[m]] == 0),
                           numeric(1)),
    guard_lower = vapply(sti_true, guard_end, numeric(1), i = 1),
    guard_upper = vapply(sti_true, guard_end, numeric(1), i = 2),
    within_guard = true_incidence >= guard_lower &
      true_incidence <= guard_upper
  )

  d_drift <- drift_table(d_full, targets, tol)
  if (!is.null(d_drift)) {
    d_drift <- mutate(d_drift, scenario_name = sc_info$scenario_name,
                      .before = 1)
  }

  list(assess = d_assess, tolerance = d_tol, sti_check = d_sti_check,
       drift = d_drift)
}

future::plan("multisession", workers = n_cores)

# A probe run (`workflow-pass_probe.R`) passes its own folder as `out_dir`
if (exists("out_dir")) calib_dir <- out_dir
calib_merged_dir <- fs::path(calib_dir, "merged_tibbles")
calib_info_tbl <- EpiModelHPC::get_scenarios_tibble_infos(calib_merged_dir)

d_ls <- future.apply::future_lapply(
  seq_len(nrow(calib_info_tbl)),
  \(i) process_one_calib_tibble(calib_info_tbl[i, ], year_steps)
)

d_calib <- bind_rows(lapply(d_ls, `[[`, "assess"))
write.csv(d_calib, fs::path(calib_dir, "calib_assess.csv"), row.names = FALSE)

d_tol <- bind_rows(lapply(d_ls, `[[`, "tolerance")) |>
  mutate(
    fitted = if (is.null(fitted_targets)) NA else target %in% fitted_targets,
    .after = target
  )
write.csv(d_tol, fs::path(calib_dir, "calib_tolerance.csv"), row.names = FALSE)
d_tol |>
  filter(is.na(fitted) | fitted) |>
  summarize(
    n_within = sum(within), n = n(),
    outside = paste(target[!within], collapse = ", "),
    .by = scenario_name
  ) |>
  print(width = Inf)

d_sti_check <- bind_rows(lapply(d_ls, `[[`, "sti_check"))
write.csv(d_sti_check, fs::path(calib_dir, "calib_sti_checks.csv"),
          row.names = FALSE)
print(d_sti_check, width = Inf)

d_drift <- bind_rows(lapply(d_ls, `[[`, "drift"))
if (nrow(d_drift) > 0) {
  write.csv(d_drift, fs::path(calib_dir, "calib_drift.csv"), row.names = FALSE)
  d_drift |>
    summarize(
      n_at_rest = sum(at_rest), n = n(),
      moving = paste(measure[!at_rest], collapse = ", "),
      unresolved = paste(measure[!resolved], collapse = ", "),
      .by = scenario_name
    ) |>
    print(width = Inf)
}
