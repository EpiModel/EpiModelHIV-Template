## 1. Calibration Assessment
##
## Interactively assess a manual calibration batch. This bust be run after
## having downloaded the `calib_assess.csv` file produced by a calibration
## workflow.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Finalized calibration assessment  --------------------------------------------
source("R/shared_variables.R", local = TRUE)
sc_df <- readRDS(fs::path(calib_dir, "merged_tibbles/df__empty_scenario.rds"))
rmarkdown::render(
  "R/Z-calibration/calibration_values.Rmd",
  output_file = "calibration_report.html",
  knit_root_dir = getwd(),
  output_dir = "./",
  params = list(
    sc_df = sc_df
  )
)

# Setup ------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_light())

source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------
d_calib <- read.csv(fs::path(calib_dir, "calib_assess.csv"))

# look only at medians
d_calib |>
  select(scenario_name, ends_with("__q2")) |>
  tail(3) |>
  glimpse()

d_calib |>
  select(scenario_name, starts_with("cc.vsupp.W"))

# download the merged_tibbles to make plot for finer exploration

sc_df <- readRDS(fs::path(calib_dir, "merged_tibbles/df__1.rds"))

sc_df <- sc_df |>
  EpiModelHIV::mutate_calibration_targets()

sc_df |>
  tail() |>
  glimpse()

ggplot(sc_df, aes(x = time, y = disease.mr100)) +
  geom_smooth()

