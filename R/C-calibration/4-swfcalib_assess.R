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

# range at each iteration
results |>
  group_by(.iteration) |>
  summarize(
    lo = min(a.rate),
    med = median(a.rate),
    hi = max(a.rate)
  )

results |>
  select(starts_with("hiv.trans"), starts_with("i.prev.dx")) |>
  mutate(
    i.prev.dx.B = i.prev.dx.B - 0.33,
    i.prev.dx.H = i.prev.dx.H - 0.127,
    i.prev.dx.W = i.prev.dx.W - 0.09,
    se = i.prev.dx.B^2 + i.prev.dx.H^2 + i.prev.dx.W^2,
    B = abs(i.prev.dx.B),
    H = abs(i.prev.dx.H),
    W = abs(i.prev.dx.W),
  ) |>
  select(se, everything()) |>
  arrange(se) |>
  filter(B < 0.02, H < 0.02, W < 0.01) |>
  summarise(across(starts_with("hiv.trans"), median))
