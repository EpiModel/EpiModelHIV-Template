# must be run after the workflow and downloading "calib_assess.csv"

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)

# Libraries --------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_light())

d_calib <- readr::read_csv(fs::path(calib_dir, "calib_assess.csv"))

# look only at medians
d_calib |>
  select(scenario_name, ends_with("__q2")) |>
  as.list()

d_calib |>
  select(scenario_name, starts_with("cc.dx"))

# download the merged_tibbles to make plot for finer exploration
