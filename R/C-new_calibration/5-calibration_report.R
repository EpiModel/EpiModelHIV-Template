source("R/shared_variables.R", local = TRUE)
rmarkdown::render(
  "Rmd/calibration_values.Rmd",
  output_file = "calibration_report.html",
  knit_root_dir = getwd(),
  output_dir = output_dir,
  params = list(
    context = "local",
    # path_df = fs::path(calib_dir, "merged_tibbles/df__empty_scenario.rds")
    # path_df = fs::path(calib_dir, "merged_tibbles/df__bad_calib.rds")
    path_df = fs::path(calib_dir, "merged_tibbles/df__default.rds")
    # path_df = "./data/run/variance/df__variance_long.rds"
  )
)
