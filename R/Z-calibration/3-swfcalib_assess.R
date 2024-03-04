## 3. swfcalib Assessment
##
## interactive script to evaluate why an swfcalib process did not returned the
## expected results. It creates the assessment report and interactively look
## into the `results.rds` object found in the calibration folder.

# This script should be run in a fresh R session

# Setup ------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_light())

source("R/shared_variables.R", local = TRUE)
source("R/Z-calibration/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

swfcalib_dir <- fs::path("data", "intermediate", "swfcalib")
theme_set(theme_light())

# Assessment -------------------------------------------------------------------
swfcalib::render_assessment(fs::path(swfcalib_dir, "assessments.rds"))

# Results ----------------------------------------------------------------------
results <- readRDS(fs::path(swfcalib_dir, "results.rds"))

results |>
  filter(abs(ir100.gc - 12.81) < 1) |>
  pull(ugc.prob) |> median()

results |>
  filter(.iteration == max(.iteration)) |>
  pull(hiv.test.rate_1) |>
  range()

# targets = paste0("cc.linked1m.", c("B", "H", "W")),
# targets_val = c(0.829, 0.898, 0.881),
# params = paste0("tx.init.rate_", 1:3),
ggplot(results, aes(
    x = ugc.prob,
    y = ir100.gc,
    col = as.factor(.iteration)
  )) +
  geom_point() +
  geom_hline(yintercept = 12.81)


# range at each iteration
results |>
  group_by(.iteration) |>
  summarize(
    lo = min(hiv.test.rate_1),
    hi = max(hiv.test.rate_1)
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
  filter(B < 0.02, H < 0.02, W < 0.02) |>
  summarise(across(starts_with("hiv.trans"), median))

co <- readRDS("./calib_object.rds")

