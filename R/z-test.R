library(dplyr)
library(tidyr)
library(ggplot2)
library(mvtnorm)
theme_set(theme_light())
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

targets <- EpiModelHIV::get_calibration_targets()
targets$num <- 1e5
results_raws <- readRDS("./rr.rds")

results <- filter(results_raws, .wave >= 1)
race_num <- 2
tar_name <- paste0("i.prev.dx.", c("B", "H", "W")[race_num])
par_name <- paste0("hiv.trans.scale_", race_num)
ggplot(results, aes(x = .data[[par_name]], y = .data[[tar_name]])) +
  geom_smooth() +
  geom_point(aes(col = factor(.wave))) +
  geom_hline(yintercept = targets[[tar_name]])

results <- filter(results_raws, .wave >= 1)
sti_num <- 3
tar_name <- paste0("ir100.", c("gono", "chla", "syph")[sti_num])
par_name <- paste0(c("gono.uret.", "chla.uret.", "syph.")[sti_num], "prob")
ggplot(results, aes(x = .data[[par_name]], y = .data[[tar_name]])) +
  geom_smooth() +
  geom_point(aes(col = factor(.wave))) +
  geom_hline(yintercept = targets[[tar_name]])

results <- filter(results_raws, .wave >= 3)
tar_name <- "num"
par_name <- "a.rate"
ggplot(results, aes(x = .data[[par_name]], y = .data[[tar_name]])) +
  geom_smooth() +
  geom_point(aes(col = factor(.wave))) +
  geom_hline(yintercept = targets[[tar_name]])

# Results of test: -------------------------------------------------------------
d <- readRDS("./data/run/calibration/merged_tibbles/df__default.rds") |>
  EpiModelHIV::mutate_calibration_targets()

ggplot(d, aes(x = time, y = ir100.syph, col = as.factor(sim))) +
  geom_smooth() +
  geom_hline(yintercept = 2)



# AIDSvu NYC 2023:

15100*0.94 / 22354 /2
16800*0.93 / 30495 /2
12870*0.9620 / 53072 /2

### `ir100.hiv.dx`

See sources

- black: 268 / (22354*2 - 15100) * 100 = 3.6945
- hisp: 385 / (30495*2 - 16800) * 100 =  2.8112
- white: 150 / (53072*2 - 12870) * 100 = 0.3731
