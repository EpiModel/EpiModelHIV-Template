## 3. swfcalib Assessment
##
## interactive script to evaluate why an swfcalib process did not returned the
## expected results. It creates the assessment report and interactively look
## into the `results.rds` object found in the calibration folder.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Render calib assessment ------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
swfcalib::render_assessment(fs::path(swfcalib_dir, "assessments.rds"))

# Setup ------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_light())
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

results <- readRDS(fs::path(swfcalib_dir, "results.rds"))

results |>
  filter(.iteration == max(.iteration)) |>
  pull(hiv.test.rate_1) |>
  range()

ggplot(results, aes(
  x = hiv.test.rate_3,
  y = cc.dx.W,
  col = as.factor(.iteration)
)) +
geom_point() +
geom_hline(yintercept = 0.862) +
geom_vline(xintercept = 0.0013)

filter(results, .iteration > 2) |>
ggplot( aes(
  x = syph.prob,
  y = ir100.syph,
  col = as.factor(.iteration)
)) +
geom_hline(yintercept = 1) +
geom_point()


d_eval <- results[, c('ir100.syph', 'syph.prob')]
d_eval$ir100.syph <- ifelse(d_eval$ir100.syph == 0, -Inf, d_eval$ir100.syph)
