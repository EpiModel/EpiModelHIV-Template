library(EpiModelHIV)
load_local_EpiModelHIV()
library(dplyr)
library(ggplot2)
theme_set(theme_light())
hpc_context <- TRUE
source("./R/C-new_calibration/z-context.R")
source("./R/shared_variables.R")
targets <- get_calibration_targets()
results <- readRDS("./results.rds")


glimpse(results)

par <- "hiv.test.rate_3"
tar <- "cc.dx.W"
results |>
  ggplot(aes(x = .data[[par]], y = .data[[tar]])) +
  geom_point() +
  geom_smooth() +
  geom_hline(yintercept = targets[tar])

summary(results)

results |>
  summarise(across(starts_with("ir100"), mean))

d <- readRDS("./data/run/calibration/merged_tibbles/df__empty_scenario.rds") |>
  mutate_calibration_targets()
glimpse(d)

d |>
  filter(time >= max(time) - 52) |>
  mutate(
    tx_prev.B = hiv.tx.B / hiv.dx.B,
    tx_prev.H = hiv.tx.H / hiv.dx.H,
    tx_prev.W = hiv.tx.W / hiv.dx.W
  ) |>
  summarise(across(starts_with("tx_prev"), mean))

d |>
  filter(time >= max(time) - 52) |>
  summarise(across(starts_with(c("ir100.hiv", "i.prev")), mean)) |>
  t()
