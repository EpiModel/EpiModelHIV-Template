# library(EpiModelHIV)
pkgload::load_all("../EpiModelHIV-p/")
source("R/shared_variables.R", local = TRUE)
hpc_context <- FALSE
source("R/B-model_dev/z-context.R")
source("R/netsim_settings.R", local = TRUE)
est <- readRDS(path_to_est)

control <- control_msm(
  # nsims = 8, ncores = 8,
  initialize.FUN = initialize_msm_ergmkit,
  resim_nets.FUN = resim_nets_ergmkit,
  ergmkit.control = ergmkit_control,
  nsteps = year_steps * 1,
  inst.resim = "exact",
  verbose = FALSE
)

system.time(sim <- netsim(est, param, init, control))

control_restart <- control_msm(
  initialize.FUN = initialize_msm_ergmkit,
  resim_nets.FUN = resim_nets_ergmkit,
  ergmkit.control = ergmkit_control,
  start = year_steps * 1 + 1,
  nsteps = year_steps * 1 + 1 + year_steps * 1,
  verbose = FALSE
)

sim2 <- netsim(sim, param, init, control_restart)
