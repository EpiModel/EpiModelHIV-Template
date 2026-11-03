library(EpiModelHIV)
source("R/shared_variables.R", local = TRUE)
source("R/B-model_dev/z-context.R")
source("R/netsim_settings.R", local = TRUE)
est <- readRDS(path_to_est)

system.time(
  cl_main <- calibrate_netest(est$fit_main, separable = TRUE)
)
system.time(
  cl_casl <- calibrate_netest(est$fit_main, separable = TRUE)
)

# TODO: set 'ergmkit.control' in netsim_settings

control <- control_msm(
  initialize.FUN = initialize_msm_ergmkit,
  resim_nets.FUN = resim_nets_ergmkit,
  ergmkit.control = list(
    list(per_node = 1, separable = TRUE),
    list(per_node = 1, separable = TRUE),
    list(exact = c("thinning", "types")[2])
  ),
  nsteps = year_steps * 1,
  # cumulative.edgelist = TRUE,
  # truncate.el.cuml = Inf,
  # save.cumulative.edgelist = TRUE,
  # save.nwstats = TRUE,
  verbose = FALSE
)

system.time(
  sim <- netsim(est, param, init, control)
)

control <- control_msm(
  initialize.FUN = initialize_msm_ergmkit,
  resim_nets.FUN = resim_nets_ergmkit,
  ergmkit.control = list(
    list(per_node = 1, separable = TRUE),
    list(per_node = 1, separable = TRUE),
    list(exact = c("thinning", "types")[2])
  ),
  start = year_steps * 1 + 1,
  nsteps = year_steps * 2,
  # cumulative.edgelist = TRUE,
  # truncate.el.cuml = Inf,
  # save.cumulative.edgelist = TRUE,
  # save.nwstats = TRUE,
  verbose = FALSE
)

system.time(
  sim <- netsim(sim, param, init, control)
)

library(dplyr)

# A tibble:  4,214 -  4,178 -  4,243
# A tibble:  8,149 -  8,045 -  8,144
# A tibble: 90,716 - 95,420 - 89,759

sim$cumulative.edgelist$sim1 |>
  group_by(network) |>
  tally() |>
  print()

sim$cumulative.edgelist$sim1 |>
  filter(network == 3, stop > start)

# sim$stats$nwstats$sim1[[1]]
