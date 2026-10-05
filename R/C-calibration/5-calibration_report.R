source("R/shared_variables.R", local = TRUE)
rmarkdown::render(
  "Rmd/calibration_values.Rmd",
  output_file = "calibration_report.html",
  knit_root_dir = getwd(),
  output_dir = output_dir,
  params = list(
    context = "local",
    path_df = "./data/run/calibration_dx/merged_tibbles/df__default.rds"
    # path_df = "./data/run/variance/df__variance_long.rds"
  )
)
