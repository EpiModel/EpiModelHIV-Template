# TODO: assess variance

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("./R/C-new_calibration/z-context.R")
source("./R/shared_variables.R")

d <- readRDS("./data/run/variance/df__variance_long.rds")
glimpse(d)

d_var <- d |>
  EpiModelHIV::mutate_calibration_targets() |>
  # mutate(time = floor(time / 52)) |>
  # summarise(across(everything(), mean), .by = c("sim", "time")) |>
  select(-c(sim, batch_number, sim_number)) |>
  summarise(across(everything(), list(mean = mean, sd = sd)), .by = "time") |>
  filter(time > 520)

glimpse(d_var)


tar_name <- "cc.prep.B"
ggplot(d_var, aes(x = time / 52, y = .data[[paste0(tar_name, "_mean")]])) +
  geom_line(alpha = 0.2) +
  geom_smooth()

ggplot(d_var, aes(x = time / 52, y = .data[[paste0(tar_name, "_sd")]])) +
  geom_line(alpha = 0.2) +
  geom_smooth()
