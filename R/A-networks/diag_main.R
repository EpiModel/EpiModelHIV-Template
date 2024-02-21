## Run the diagnostics for the *main* network model
##
## This script should not be run directly. But `sourced` by `2-diagnostics.R`

model_main_dx <- ~edges +
  nodematch("age.grp", diff = TRUE) +
  nodefactor("age.grp", levels = TRUE) +
  nodematch("race", diff = TRUE) +
  nodefactor("race", levels = TRUE) +
  nodefactor("deg.casl", levels = TRUE) +
  degrange(from = 3) +
  concurrent +
  nodematch("role.class", diff = TRUE) +
  degree(0:3)

dx_main <- EpiModel::netdx(
  est$fit_main,
  nsims = diag_nsims,
  ncores = diag_ncores,
  nsteps = diag_nsteps,
  nwstats.formula = model_main_dx,
  set.control.ergm = ergm::control.simulate.formula(MCMC.burnin = 1e5),
  set.control.tergm =
    tergm::control.simulate.formula.tergm(MCMC.burnin.min = 2e5)
)

dx_main_static <- EpiModel::netdx(
  est$fit_main,
  dynamic = FALSE,
  nsims = 1e4,
  nwstats.formula = model_main_dx,
  set.control.ergm = ergm::control.simulate.formula(MCMC.burnin = 1e5)
)

dx <- list(dynamic = dx_main, static = dx_main_static)
saveRDS(dx, fs::path(diag_dir, paste0("netdx-main-", context, ".rds")))
rm(dx, dx_main, dx_main_static)
