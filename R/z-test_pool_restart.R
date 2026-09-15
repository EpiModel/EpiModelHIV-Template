# TODO:
#   1. make a 3 sim netsim obj
#   2. make a restart_pool of 3, and doctor the attrs so it's easier to
#      distinguish
#   3. restart from pool: 4 sims, test both options + default and check vals

scenario_name <- "empty_scenario"
hpc_context <- TRUE
# scenario_name <- "scenario_2"
# hpc_context <- FALSE

pkgload::load_all("../EpiModel/")
library(EpiModelHIV)
library(dplyr)
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
source("R/C-calibration/utils-restart.R", local = TRUE)

# Process ----------------------------------------------------------------------
sim <- readRDS("./data/run/calibration_sav/sim__empty_scenario__1.rds")

attrs_names <- names(EpiModelHIV::get_default_attrs())
time_prefixes <- c(".last$", ".time$")
time_attrs <- Reduce(
  function(a, prefix) c(a, grepv(prefix, attrs_names)),
  time_prefixes,
  init = character(0)
)

restart_point <- make_restart_point(
  sim,
  time_attrs,
  sims_num = c(2, 6),
  keep_steps = 1
)

attr_int <- "ins.quot"

for (i in 1:2) {
  restart_point$run[[i]]$attr[[attr_int]] <-
    restart_point$run[[i]]$attr[[attr_int]] + i * 0.05
}

source("./R/netsim_settings.R", local = TRUE)

param$a.rate <- 0
control <- control_msm(
  start          = 2,
  nsteps         = 3,
  nsims = 4,
  initialize.FUN = initialize.net,
  randomize.restart = FALSE,
  verbose = TRUE
)

rest_sim <- netsim(restart_point, param, init, control)

for (i in 1:4) {
  rs <- rest_sim$run[[i]][["_restart_simnum"]]
  print(rs)
  print(restart_point$run[[rs]]$attr[[attr_int]] |> mean(na.rm = TRUE))
  print(rest_sim$run[[i]]$attr[[attr_int]] |> mean(na.rm = TRUE))
  print("")
}

names(restart_point$run[[1]]$attr)
