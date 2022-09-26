# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)
source("R/00-project_settings.R")


# Necessary files
epistats <- readRDS("data/intermediate/estimates/epistats.rds")
netstats <- readRDS("data/intermediate/estimates/netstats.rds")
est      <- readRDS("data/intermediate/estimates/netest.rds")

# Parameters
prep_start <- 54
param <- param.net(
  data.frame.params = readr::read_csv("data/input/params-100000.csv"),
  netstats          = netstats,
  epistats          = epistats,
  prep.start        = prep_start,
  riskh.start       = prep_start - 53,
  .param.updater.list = list(
    # High PrEP intake for the first year; go back to normal to get to 15%
    list(at = prep_start, param = list(prep.start.prob = function(x) x * 2)),
    list(at = prep_start + 52, param = list(prep.start.prob = function(x) x/2))
  )
)

# Define test scenarios
scenarios.df <- dplyr::tibble(
  .scenario.id = c("scenario_1", "scenario_2"),
  .at = 1,
  hiv.test.rate_1 = c(0.004, 0.005),
  hiv.test.rate_2 = c(0.004, 0.005),
  hiv.test.rate_3 = c(0.007, 0.008)
)
scenarios.list <- EpiModel::create_scenario_list(scenarios.df)

# Apply a scenario to the param object
param_sc <- EpiModel::use_scenario(param, scenarios.list[[1]])

# Initial conditions
init <- init_msm(
  prev.ugc = 0.1,
  prev.rct = 0.1,
  prev.rgc = 0.1,
  prev.uct = 0.1
)

# Controls
source("R/utils-targets.R")
control <- control_msm(
  nsteps              = 52 * 7,
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = TRUE,
  raw.output          = FALSE
)

# Simulation and exploration ---------------------------------------------------
# debug(stitrans_msm)
sim <- netsim(est, param_sc, init, control)

d_sim <- as_tibble(sim)

glimpse(d_sim)
d_sim$prep_startat___ALL
d_sim$prep_ret1y___ALL
d_sim$prep_ret2y___ALL

dd <- d_sim %>%
  select(
    starts_with("s_prep___"),
    prep_startat___ALL, prep_ret1y___ALL
  ) %>%
  mutate(prep_prop_ret = prep_ret1y___ALL / lag(prep_startat___ALL, 52))

dd$prep_prop_ret[110:156] |> mean()

library(ggplot2)
ggplot(d_sim, aes(x = time)) +
  geom_line(aes(y = prev.ct)) +
  geom_line(aes(y = prev.gc), col = "blue")
