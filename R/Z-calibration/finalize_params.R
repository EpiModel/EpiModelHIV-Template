library(dplyr)
source("R/shared_variables.R", local = TRUE)

params_df_all <- read.csv(fs::path(input_dir, "model_parameters.csv")) |>
  select(-value)

params_calib <- read.csv("./params.csv") |>
  select(param, value)

final_prms <- left_join(params_df_all, params_calib, by = "param") |>
  select(param, value, type, everything())

readr::write_csv(final_prms, fs::path(input_dir, "model_parameters.csv"))
