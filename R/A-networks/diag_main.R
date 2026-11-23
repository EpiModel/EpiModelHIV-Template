## Run the diagnostics for the *main* network model
##
## This script should not be run directly. But `sourced` by `2-diagnostics.R`
##
## Produces two types of diagnostics:
## - Dynamic: simulates the network forward in time to check
##   temporal stability
## - Static: samples from the ERGM once to check target statistic reproduction

# Diagnostic formula — uses `levels = TRUE` to show all levels (more detail than
# the estimation formula) and adds `degree(0:3)` to inspect the degree
# distribution directly
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

# Dynamic diagnostics: simulate network over time. The tergm sampling per step
# is the one every netsim run uses (`control_tergm_sim()` in
# R/shared_variables.R), so these diagnostics test the networks as the
# simulations will move them.
dx_main <- EpiModel::netdx(
  est$fit_main,
  nsims = diag_nsims,
  ncores = diag_ncores,
  nsteps = diag_nsteps,
  nwstats.formula = model_main_dx,
  set.control.ergm = ergm::control.simulate.formula(MCMC.burnin = 1e5),
  set.control.tergm = control_tergm_sim()
)

# Static diagnostics: sample from the fitted ERGM (no dynamics)
dx_main_static <- EpiModel::netdx(
  est$fit_main,
  dynamic = FALSE,
  nsims = 1e4,
  nwstats.formula = model_main_dx,
  set.control.ergm = ergm::control.simulate.formula(MCMC.burnin = 1e5)
)

# The setting the dynamic diagnostics ran at goes with them: the network check
# (`3-check.R`) refuses diagnostics made at a setting other than the one the
# simulations use.
dx <- list(
  dynamic = dx_main,
  static = dx_main_static,
  tergm_proposals = tergm_proposals
)
dx_path <- fs::path(diag_dir, paste0("netdx-main-", context, ".rds"))
saveRDS(dx, dx_path)
rm(dx, dx_main, dx_main_static)
