## Run the diagnostics for the *one-off* network model
##
## This script should not be run directly. But `sourced` by `2-diagnostics.R`
##
## One-off partnerships are instantaneous so only static diagnostics are needed

model_ooff_dx <- ~edges +
  nodematch("age.grp", diff = FALSE) +
  nodefactor("age.grp", levels = TRUE) +
  nodematch("race", diff = TRUE) +
  nodefactor("race", levels = TRUE) +
  nodefactor("risk.grp", levels = TRUE) +
  nodefactor("deg.tot", levels = TRUE) +
  nodematch("role.class", diff = TRUE) +
  degree(0:4)

dx_ooff <- EpiModel::netdx(
  est$fit_ooff,
  nsims = 1e4,
  dynamic = FALSE,
  nwstats.formula = model_ooff_dx,
  set.control.ergm = ergm::control.simulate.formula(MCMC.burnin = 1e5)
)

dx_ooff_exact <- EpiModelHIV::netdx_exact(
  est$fit_ooff,
  nsims = 1e2, # only 100, otherwise very slow
  nwstats.formula = model_ooff_dx,
  verbose = TRUE
)

dx <- list(static = dx_ooff, exact = dx_ooff_exact)
dx_path <- fs::path(diag_dir, paste0("netdx-ooff-", context, ".rds"))
saveRDS(dx, dx_path)
rm(dx)
