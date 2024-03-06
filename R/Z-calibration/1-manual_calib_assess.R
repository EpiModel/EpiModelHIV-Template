## 1. Calibration Assessment
##
## Interactively assess a manual calibration batch. This bust be run after
## having downloaded the `calib_assess.csv` file produced by a calibration
## workflow.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_light())

source("R/shared_variables.R", local = TRUE)
source("R/Z-calibration/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

d_calib <- readr::read_csv(fs::path(calib_dir, "calib_assess.csv"))

# look only at medians
d_calib |>
  select(scenario_name, ends_with("__q2")) |>
  as.list()

d_calib |>
  select(scenario_name, starts_with("cc.dx"))

# download the merged_tibbles to make plot for finer exploration
