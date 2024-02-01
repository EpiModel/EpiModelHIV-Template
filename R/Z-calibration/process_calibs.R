# can I simply use the manual_1_process.R

# To be run after merge_netsim_tibble

# for each merged_tibble
#   make calibration targets
#   calc q1, q2, q3
#   combine calib_vals
#
#   make calibration dist
#   calc q1, q2, q3
#   combine calib_dists
source("./R/shared_variables.R", local = TRUE)

process_one_calib_tibble <- function(sc_info, calib_steps) {
  targets <- EpiModelHIV::get_calibration_targets()

  d_dist <- readRDS(sc_info$file_path) |>
    dplyr::filter(time >= max(time) - calib_steps) |>
    EpiModelHIV::mutate_calibration_distances() |>
    dplyr::select(batch_number, sim, dplyr::any_of(names(targets)))

  d_dist <- d_dist |>
    dplyr::group_by(batch_number, sim) |>
    dplyr::summarize(
      dplyr::across(dplyr::everything(), mean),
      .groups = "drop"
    ) |>
    dplyr::select(-c(batch_number, sim))

  d_dist <- d_dist |>
    dplyr::summarize(dplyr::across(
      dplyr::everything(),
      .fns = list(
        q1 = \(x) quantile(x, 0.25, na.rm = TRUE),
        q2 = \(x) quantile(x, 0.50, na.rm = TRUE),
        q3 = \(x) quantile(x, 0.75, na.rm = TRUE)
      ),
      .names = "{.col}__{.fn}"
    )) |>
    dplyr::mutate(scenario_name = sc_info$scenario_name) |>
    dplyr::select(scenario_name, dplyr::everything())
}

future::plan("multisession", workers = 8)

calib_merged_dir <- fs::path(calib_dir, "merged_tibbles")
calib_info_tbl <- EpiModelHPC::get_scenarios_tibble_infos(calib_merged_dir)

d_ls <- future.apply::future_lapply(
  seq_len(nrow(calib_info_tbl)),
  \(i) process_one_calib_tibble(calib_info_tbl[i, ], year_steps)
)

d_calib <- dplyr::bind_rows(d_ls)
readr::write_csv(d_calib, fs::path(calib_dir, "calib_assess.csv"))
