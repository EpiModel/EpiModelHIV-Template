# NOTE: restart pool
# - folder containing files named: X.rds
# - need utility to make it and validate it
# - wrapper:
#   - similar to netsim except "path_to_est" instead of "est"
#   - if "est" is unique: read -> start
#   - else if dir: read correct file -> start (record)

library(EpiModelHIV)
pkgload::load_all("../EpiModel/")
library(dplyr)
source("R/shared_variables.R", local = TRUE)
hpc_context <- TRUE
source("R/C-new_calibration/z-context.R", local = TRUE)
source("R/netsim_settings.R", local = TRUE)
source("R/utils-restart_pool.R", local = TRUE)

pool_dir <- "./data/run/estimates/pool_dir"

# # Create a restart_pool_dir ----------------------------------------------------
# old_pool <- readRDS(pool_dir)
# sims <- lapply(1:32, get_sims, x = old_pool)
# add_to_restart_pool(sims, new_pool)

# Netsim wrapper ---------------------------------------------------------------
future::plan("multicore", workers = 4)
# future::plan("sequential")

control <- control_msm(
  nsteps = 5,
  start = 2,
  initialize.FUN = initialize.net,
  verbose = TRUE
)

out <- netsim_path_wrapper_multi(
  pool_dir,
  param,
  init,
  control,
  c(32, 52, 12, 66)
)
final <- Reduce(merge.netsim, out)

control1 <- control_msm(nsteps = 5, verbose = FALSE)
out <- netsim_path_wrapper_multi(
  "./data/run/estimates/netest-local.rds",
  param,
  init,
  control1,
  c(32, 52, 12, 66)
)
final <- Reduce(merge.netsim, out)
