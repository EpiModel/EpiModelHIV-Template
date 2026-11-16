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
##
## `calib_sti_checks.csv` adds two checks on the bacterial STIs that the
## tolerance rule does not make: the share of runs in which each has died out
## (no infection in the final year), and, if the project gives one
## (`project_calibration_incidence_guard()`), its mean true incidence against
## the range a calibrated model should not leave. A mean that meets its target
## as an average of extinct and persisting runs is not a fit.
##
## This script should be called by one of the manual_calibration workflows.

# Setup ------------------------------------------------------------------------
library(dplyr)
library(tidyr)

source("R/shared_variables.R", local = TRUE)
source("R/calibration_targets.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

# Callers may or may not set this: workflow-swfcalib.R does not, the ballpark
# and restart workflows do.
if (!exists("n_cores")) {
  n_cores <- 8
}

# Process ----------------------------------------------------------------------

process_one_calib_tibble <- function(sc_info, calib_steps) {
  targets <- project_calibration_targets()

  d_raw <- readRDS(sc_info$file_path) |>
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

  list(assess = d_assess, tolerance = d_tol, sti_check = d_sti_check)
}

future::plan("multisession", workers = n_cores)

calib_merged_dir <- fs::path(calib_dir, "merged_tibbles")
calib_info_tbl <- EpiModelHPC::get_scenarios_tibble_infos(calib_merged_dir)

d_ls <- future.apply::future_lapply(
  seq_len(nrow(calib_info_tbl)),
  \(i) process_one_calib_tibble(calib_info_tbl[i, ], year_steps)
)

d_calib <- bind_rows(lapply(d_ls, `[[`, "assess"))
write.csv(d_calib, fs::path(calib_dir, "calib_assess.csv"), row.names = FALSE)

d_tol <- bind_rows(lapply(d_ls, `[[`, "tolerance"))
write.csv(d_tol, fs::path(calib_dir, "calib_tolerance.csv"), row.names = FALSE)
d_tol |>
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
