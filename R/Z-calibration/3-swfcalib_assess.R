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

ggplot(results, aes(x = hiv.test.rate_1, y = cc.dx.B, col = as.factor(.iteration))) +
  geom_point() +
  geom_hline(yintercept = 0.847)


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

rgc.prob,0.3002,numeric, CPN-plogis(qlogis(0.25546) + log(1.25)) #0.357;  # gaps appendix 9.4
ugc.prob,0.25546,numeric,CPN-gaps appendix 9.4 | calibrated
rct.prob,0.2054959,numeric, CPN-plogis(qlogis(1714429) + log(1.25)) #0.3216; # gaps appendix 9.3
uct.prob,0.1714429,numeric, CPN-gaps appendix 9.3 | calibrated
