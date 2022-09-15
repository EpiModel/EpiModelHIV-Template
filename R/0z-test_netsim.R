# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
source("R/000-project_settings.R")


# Necessary files
epistats <- readRDS(fs::path(estimates_dir, "epistats.rds"))
netstats <- readRDS(fs::path(estimates_dir, "netstats.rds"))
est      <- readRDS(fs::path(estimates_dir, "netest.rds"))

# Parameters
prep_start <- 54
param <- param.net(
  data.frame.params = readr::read_csv(fs::path(inputs_dir, "params.csv")),
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

# Initial conditions
init <- init_msm(
  prev.ugc = 0.05,
  prev.rct = 0.05,
  prev.rgc = 0.05,
  prev.uct = 0.05
)

# Controls
source("R/utils-targets.R")
control <- control_msm(
  nsteps              = 52 * 2,
  nsims               = 2,
  ncores              = 2,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  verbose             = TRUE,
  raw.output          = FALSE
)

# Simulation and exploration ---------------------------------------------------
sim <- netsim(est, param, init, control)


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
ggplot(d_sim, aes(x = time, y = s_prep___B)) +
  geom_line()
