## Process Calibration
##
## Generate a light calibration assessement file to be downloaded locally to
## check the manual calibration advancement.
##
## This script should be called by one of the manual_calibration workflows.

# Setup ------------------------------------------------------------------------
library(dplyr)
library(tidyr)

source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

process_one_calib_tibble <- function(sc_info, calib_steps) {
  targets <- EpiModelHIV::get_calibration_targets()

  d_dist <- readRDS(sc_info$file_path) |>
    filter(time >= max(time) - calib_steps) |>
    EpiModelHIV::mutate_calibration_targets() |>
    select(sim, any_of(names(targets)))

  # Scale distances
  for (t_name in intersect(names(targets), names(d_dist)))
    d_dist[[t_name]] <- (d_dist[[t_name]] - targets[[t_name]]) /
                          abs(targets[[t_name]])

  d_dist <- d_dist |>
    group_by(sim) |>
    summarize(across(everything(), mean), .groups = "drop") |>
    select(-c(sim))

  fmtr <- scales::label_percent(0.1)

  d_dist <- d_dist |>
    summarize(across(
      everything(),
      \(x) paste0(fmtr(mean(x)), " (", fmtr(sd(x)), ")")
    )) |>
    mutate(
      scenario_name = sc_info$scenario_name,
    ) |>
    select(scenario_name, everything())
}

future::plan("multisession", workers = 8)

calib_merged_dir <- fs::path(calib_dir, "merged_tibbles")
calib_info_tbl <- EpiModelHPC::get_scenarios_tibble_infos(calib_merged_dir)

d_ls <- future.apply::future_lapply(
  seq_len(nrow(calib_info_tbl)),
  \(i) process_one_calib_tibble(calib_info_tbl[i, ], year_steps)
)

d_calib <- bind_rows(d_ls)
write.csv(d_calib, fs::path(calib_dir, "calib_assess.csv"), row.names = FALSE)
