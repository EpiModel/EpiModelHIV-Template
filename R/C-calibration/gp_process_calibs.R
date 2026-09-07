## Process Calibration
##
## Generate a light calibration assessement file to be downloaded locally to
## check the manual calibration advancement.
##
## For each target the mean distance to the target value is reported (positive
## means too high and negative too low)
##
## This script should be called by one of the manual_calibration workflows.

# Setup ------------------------------------------------------------------------
library(dplyr)
library(tidyr)

source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

if (!exists("n_cores")) {
  stop( "The 'process_calibs.R' script requires an `n_cores` variable")
}

# Process ----------------------------------------------------------------------

process_one_calib_tibble <- function(sc_info, calib_steps) {
  targets <- EpiModelHIV::get_calibration_targets()

  d_dist <- readRDS(sc_info$file_path) |>
    filter(time >= max(time) - calib_steps) |>
    EpiModelHIV::mutate_calibration_targets() |>
    select(sim, any_of(names(targets)))

  targets <- targets[intersect(names(targets), names(d_dist))]

  d_dist <- d_dist |>
    # mutate(across(names(targets), \(x) x - targets[cur_column()])) |>
    summarize(across(everything(), mean), .by = c("sim")) |>
    select(-c(sim))


  d_dist |>
    mutate(
      scenario_name = sc_info$scenario_name,
    ) |>
    select(scenario_name, everything())
}

future::plan("multisession", workers = n_cores)

calib_merged_dir <- fs::path(calib_dir, "merged_tibbles")
calib_info_tbl <- EpiModelHPC::get_scenarios_tibble_infos(calib_merged_dir)

d_ls <- future.apply::future_lapply(
  seq_len(nrow(calib_info_tbl)),
  \(i) process_one_calib_tibble(calib_info_tbl[i, ], year_steps)
)

d_calib <- bind_rows(d_ls) |>
  left_join(readRDS("./data/run/lhs_scs2.rds"), by = c("scenario_name" = ".scenario.id"))

saveRDS(d_calib, "./data/run/gp_all_results2.Rds")
