library(EpiModelHIV)
# pkgload::load_all("../EpiModelHIV-p/")
source("R/shared_variables.R", local = TRUE)
hpc_context <- FALSE
source("R/B-model_dev/z-context.R")
source("R/netsim_settings.R", local = TRUE)
est <- readRDS(path_to_est)

control <- control_msm(
  # nsims = 8, ncores = 8,
  # initialize.FUN = initialize_msm_ergmkit,
  # resim_nets.FUN = resim_nets_ergmkit,
  ergmkit.control = ergmkit_control,
  # ergmkit.control = list(list(), list(), list(exact =  "thinning")),
  nsteps = year_steps * 5,
  inst.resim = "exact",
  verbose = FALSE
)

profvis::profvis({
  sim <- netsim(est, param, init, control)
})

# control_restart <- control_msm(
#   initialize.FUN = initialize_msm_ergmkit,
#   resim_nets.FUN = resim_nets_ergmkit,
#   ergmkit.control = ergmkit_control,
#   start = year_steps * 1 + 1,
#   nsteps = year_steps * 1 + 1 + year_steps * 1,
#   verbose = FALSE
# )
#
# sim2 <- netsim(sim, param, init, control_restart)
#
#
# ekit <- c(
#   0.99, 1.06, 1.03, 1.15, 1.15, 1.15, 1.16,
#   1.17, 1.2, 0.91, 1.16, 1.2, 1.2, 1.17, 1.21
# )
#
# tgm <- c(
#   1.26, 1.26, 1.11, 1.42, 1.1, 1.48, 1.54, 1.45, 1.06, 1.42, 1.14, 1.1, 1.13,
#   1.41, 1.11, 1.43
# )
#
# (summary(ekit) - summary(tgm)) / summary(tgm)
