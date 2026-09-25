library(dplyr)
library(tidyr)
library(ggplot2)
library(mvtnorm)
theme_set(theme_light())
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

targets <- EpiModelHIV::get_calibration_targets()
targets$num <- 1e5

d_sc <- readRDS(fs::path(calib_dir, "merged_tibbles/df__bad_calib_pool.rds")) |>
  EpiModelHIV::mutate_calibration_targets()

d_sc |>
  tail() |>
  glimpse()

ggplot(d_sc, aes(x = time, y = disease.mr100)) +
  geom_smooth()

d_calib |>
  filter(time >= max(time) - 52) |>
  mutate(
    tx_prev.B = hiv.tx.B / hiv.dx.B,
    tx_prev.H = hiv.tx.H / hiv.dx.H,
    tx_prev.W = hiv.tx.W / hiv.dx.W
  ) |>
  summarise(across(starts_with("tx_prev"), mean))
