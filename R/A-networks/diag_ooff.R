## Run the diagnostics for the *one-off* network model
##
## This script should not be run directly. But `sourced` by `2-diagnostics.R`

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

dx <- list(static = dx_ooff)
saveRDS(dx, fs::path(diag_dir, paste0("netdx-ooff-", context, ".rds")))
