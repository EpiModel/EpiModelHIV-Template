# Scratchpad for interactive testing before integration in a script
source("R/shared_variables.R", local = TRUE)
library(EpiModelHIV)
library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_light())

d_sim <- readRDS("./data/run/calibration/merged_tibbles/df__empty_scenario.rds")
glimpse(d_sim)

with(d_sim, {
  tail(i_dx__B / i__B)
})

sim <- readRDS("./data/run/calibration/sim__empty_scenario__1.rds")

attr <- sim$run$sim1$attr

sum(attr$hiv.inf)
sum(attr$hiv.dx)

#
library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_light())
source("R/shared_variables.R", local = TRUE)
pkgload::load_all("../../EpiModel.git/main/")
pkgload::load_all(EMHIVp_dir)
context <- "local"
source("R/netsim_settings.R", local = TRUE)
est <- readRDS(path_to_est)

control <- control_msm(
  nsteps = 10 * year_steps,
  # .tracker.list = EpiModelHIV::make_calibration_trackers(),
  verbose = TRUE
)

sim <- netsim(est, param, init, control)
d <- as.data.frame(sim)
glimpse(d)

mutate_calibration_targets(d) |> tail() |> glimpse()



