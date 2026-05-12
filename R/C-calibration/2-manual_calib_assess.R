# See "data/run/calibration/calib_assess.csv" for quick comparison of
# calibration scenarios

# Plot calibration targets for a given scenario --------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/utils-calib_plots.R", local = TRUE)

d_calib <- readRDS(fs::path(calib_dir, "merged_tibbles/df__scenario_2.rds")) |>
  EpiModelHIV::mutate_calibration_targets()

make_calib_plot(d_calib, calib_plot_infos[["cc.dx"]], year_steps)

# Plot them all
for (p_info in calib_plot_infos) {
  message("Targets: ", paste0(p_info$names, sep = ", "))
  make_calib_plot(d_calib, p_info, year_steps)
  tmp <- readline(prompt = "Press Enter to continue")
}

# Manual exploration -----------------------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_light())

source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

d_sc <- readRDS(fs::path(calib_dir, "merged_tibbles/df__scenario_2.rds")) |>
  EpiModelHIV::mutate_calibration_targets()

d_sc |>
  tail() |>
  glimpse()

ggplot(d_sc, aes(x = time, y = disease.mr100)) +
  geom_smooth()
