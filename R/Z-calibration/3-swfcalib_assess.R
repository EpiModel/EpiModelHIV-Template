# Libraries --------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
swfcalib_dir <- fs::path("data", "intermediate", "swfcalib")
theme_set(theme_light())

# Assessment -------------------------------------------------------------------
swfcalib::render_assessment(fs::path(swfcalib_dir, "assessments.rds"))

# Results ----------------------------------------------------------------------
results <- readRDS(fs::path(swfcalib_dir, "results.rds"))

results |>
  filter(.iteration == max(.iteration)) |>
  pull(hiv.test.rate_1) |>
  range()

ggplot(results, aes(x = hiv.test.rate_1, y = cc.dx.B, col = .iteration)) +
  geom_point() +
  geom_hline(yintercept = 0.8)

