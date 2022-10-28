# Setup ------------------------------------------------------------------------
# library("EpiModelHIV")
library("dplyr")

# Necessary files
epistats <- readRDS("data/intermediate/estimates/epistats.rds")
netstats <- readRDS("data/intermediate/estimates/netstats.rds")
est      <- readRDS("data/intermediate/estimates/netest.rds")

# Parameters
prep_start <- 54
param <- param.net(
  data.frame.params = readr::read_csv("data/input/params.csv"),
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
scenarios.df <- tibble(
  .scenario.id    = c("scenario_1", "scenario_2"),
  .at             = 1,
  hiv.test.rate_1 = c(0.004, 0.005),
  hiv.test.rate_2 = c(0.004, 0.005),
  hiv.test.rate_3 = c(0.007, 0.008)
)
scenarios.list <- EpiModel::create_scenario_list(scenarios.df)

# Apply a scenario to the param object
param_sc <- EpiModel::use_scenario(param, scenarios.list[[1]])

# Initial conditions (default prevalence initialized in epistats)
# For models without bacterial STIs, these must be initialized here
# with non-zero values
init <- init_msm(
  prev.ugc = 0.1,
  prev.rct = 0.1,
  prev.rgc = 0.1,
  prev.uct = 0.1
)

# Controls
source("R/utils-targets.R")
control <- control_msm(
  nsteps              = 3,
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  verbose             = FALSE,
  raw.output          = TRUE
)

# See listing of modules and other control settings
# Module function defaults defined in ?control_msm
print(control)

out <- numeric(100)
for (i in seq_len(100)) {
  sim <- netsim(est, param, init, control)
  dat <- sim[[1]]
  out[i] <- get_edgelist(dat, 3) |> nrow()
}

mean(out)
median(out)
