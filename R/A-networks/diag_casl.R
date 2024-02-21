## Run the diagnostics for the *casual* network model
##
## This script should not be run directly. But `sourced` by `2-diagnostics.R`

model_casl_dx <- ~edges +
  nodematch("age.grp", diff = TRUE) +
  nodefactor("age.grp", levels = TRUE) +
  nodematch("race", diff = TRUE) +
  nodefactor("race", levels = TRUE) +
  nodefactor("deg.main", levels = TRUE) +
  degrange(from = 4) +
  concurrent +
  nodematch("role.class", diff = TRUE) +
  degree(0:4)

dx_casl <- EpiModel::netdx(
  est$fit_casl,
  nsims = diag_nsims,
  ncores = diag_ncores,
  nsteps = diag_nsteps,
  nwstats.formula = model_casl_dx,
  set.control.ergm = ergm::control.simulate.formula(MCMC.burnin = 1e5),
  set.control.tergm =
    tergm::control.simulate.formula.tergm(MCMC.burnin.min = 2e5)
)

dx_casl_static <- EpiModel::netdx(
  est$fit_casl,
  dynamic = FALSE,
  nsims = 1e4,
  nwstats.formula = model_casl_dx,
  set.control.ergm = ergm::control.simulate.formula(MCMC.burnin = 1e5)
)

dx <- list(dynamic = dx_casl, static = dx_casl_static)
saveRDS(dx, fs::path(diag_dir, paste0("netdx-casl-", context, ".rds")))
rm(dx, dx_casl, dx_casl_static)
