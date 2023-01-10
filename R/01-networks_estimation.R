##
## 01. Network Model Estimation
##
## This file estimates the ERGMs. When run locally `context == "local"` it fits
## 5k nodes networks. They can be used for local testing of the project.
## When run on the HPC (`context` is set in the workflow definition to "hpc"),
## 100k nodes networks are used.

# Libraries  -------------------------------------------------------------------
library("EpiModelHIV")
library("ARTnet")

# Settings ---------------------------------------------------------------------
context <- if (!exists("context")) "local" else context
source("R/utils-0_project_settings.R")

if (context == "local") {
  networks_size   <- 5 * 1e3
  estimation_method <- "Stochastic-Approximation"
  estimation_ncores <- 1
} else if (context == "hpc") {
  networks_size   <- 100 * 1e3
} else  {
  stop("The `context` variable must be set to either 'local' or 'hpc'")
}

# 0. Initialize Network --------------------------------------------------------
epistats <- build_epistats(
  geog.lvl = "city",
  geog.cat = "Atlanta",
  init.hiv.prev = c(0.33, 0.137, 0.084),
  race = TRUE,
  time.unit = 7
)
saveRDS(epistats, paste0(est_dir, "epistats-", context, ".rds"))

netparams <- build_netparams(
  epistats = epistats,
  smooth.main.dur = TRUE
)

netstats <- build_netstats(
  epistats,
  netparams,
  expect.mort = 0.000478213,
  network.size = networks_size
)
saveRDS(netstats, paste0(est_dir, "netstats-", context, ".rds"))

num <- netstats$demog$num
nw <- EpiModel::network_initialize(num)

attr_names <- names(netstats$attr)
attr_values <- netstats$attr

nw_main <- EpiModel::set_vertex_attribute(nw, attr_names, attr_values)
nw_casl <- nw_main
nw_inst <- nw_main

# 1. Main Model ----------------------------------------------------------------

# Formula
model_main <- ~ edges +
  nodematch("age.grp", diff = TRUE) +
  nodefactor("age.grp", levels = -1) +
  nodematch("race", diff = FALSE) +
  nodefactor("race", levels = -1) +
  nodefactor("deg.casl", levels = -1) +
  concurrent +
  degrange(from = 3) +
  nodematch("role.class", diff = TRUE, levels = c(1, 2))

# Target Stats
netstats_main <- c(
  edges                = netstats$main$edges,
  nodematch_age.grp    = netstats$main$nodematch_age.grp,
  nodefactor_age.grp   = netstats$main$nodefactor_age.grp[-1],
  nodematch_race       = netstats$main$nodematch_race_diffF,
  nodefactor_race      = netstats$main$nodefactor_race[-1],
  nodefactor_deg.casl  = netstats$main$nodefactor_deg.casl[-1],
  concurrent           = netstats$main$concurrent,
  degrange             = 0,
  nodematch_role.class = c(0, 0)
)
netstats_main <- unname(netstats_main)

# Fit model
fit_main <- netest(
  nw_main,
  formation = model_main,
  target.stats = netstats_main,
  coef.diss = netstats$main$diss.byage,
  set.control.ergm = control.ergm(
    main.method = estimation_method,
    MCMLE.maxit = 500,
    SAN.maxit = 3,
    SAN.nsteps.times = 4,
    MCMC.samplesize = 1e4,
    MCMC.interval = 5e3,
    parallel = estimation_ncores
  ),
  verbose = FALSE
)
fit_main <- trim_netest(fit_main)

# 2. Casual Model ---------------------------------------------------------

# Formula
model_casl <- ~ edges +
  nodematch("age.grp", diff = TRUE) +
  nodefactor("age.grp", levels = -5) +
  nodematch("race", diff = FALSE) +
  nodefactor("race", levels = -1) +
  nodefactor("deg.main", levels = -3) +
  concurrent +
  degrange(from = 4) +
  nodematch("role.class", diff = TRUE, levels = c(1, 2))

# Target Stats
netstats_casl <- c(
  edges                = netstats$casl$edges,
  nodematch_age.grp    = netstats$casl$nodematch_age.grp,
  nodefactor_age.grp   = netstats$casl$nodefactor_age.grp[-5],
  nodematch_race       = netstats$casl$nodematch_race_diffF,
  nodefactor_race      = netstats$casl$nodefactor_race[-1],
  nodefactor_deg.main  = netstats$casl$nodefactor_deg.main[-3],
  concurrent           = netstats$casl$concurrent,
  degrange             = 0,
  nodematch_role.class = c(0, 0)
)
netstats_casl <- unname(netstats_casl)

# Fit model
fit_casl <- netest(
  nw_casl,
  formation = model_casl,
  target.stats = netstats_casl,
  coef.diss = netstats$casl$diss.byage,
  set.control.ergm = control.ergm(
    main.method = estimation_method,
    MCMLE.maxit = 500,
    SAN.maxit = 3,
    SAN.nsteps.times = 4,
    MCMC.samplesize = 1e4,
    MCMC.interval = 5e3,
    parallel = estimation_ncores
  ),
  verbose = FALSE
)
fit_casl <- trim_netest(fit_casl)

# 3. One-Off Model -------------------------------------------------------------

# Formula
model_inst <- ~ edges +
  nodematch("age.grp", diff = FALSE) +
  nodefactor("age.grp", levels = -1) +
  nodematch("race", diff = FALSE) +
  nodefactor("race", levels = -1) +
  nodefactor("risk.grp", levels = -5) +
  nodefactor("deg.tot", levels = -1) +
  nodematch("role.class", diff = TRUE, levels = c(1, 2))

# Target Stats
netstats_inst <- c(
  edges                = netstats$inst$edges,
  nodematch_age.grp    = sum(netstats$inst$nodematch_age.grp),
  nodefactor_age.grp   = netstats$inst$nodefactor_age.grp[-1],
  nodematch_race       = netstats$inst$nodematch_race_diffF,
  nodefactor_race      = netstats$inst$nodefactor_race[-1],
  nodefactor_risk.grp  = netstats$inst$nodefactor_risk.grp[-5],
  nodefactor_deg.tot   = netstats$inst$nodefactor_deg.tot[-1],
  nodematch_role.class = c(0, 0)
)
netstats_inst <- unname(netstats_inst)

# Fit model
fit_inst <- netest(
  nw_inst,
  formation = model_inst,
  target.stats = netstats_inst,
  coef.diss = dissolution_coefs(~ offset(edges), 1),
  set.control.ergm = control.ergm(
    main.method = estimation_method,
    MCMLE.maxit = 500,
    SAN.maxit = 3,
    SAN.nsteps.times = 4,
    MCMC.samplesize = 1e4,
    MCMC.interval = 5e3,
    parallel = estimation_ncores
  ),
  verbose = FALSE
)
fit_inst <- trim_netest(fit_inst)

# 4. Save Data -----------------------------------------------------------------
out <- list(fit_main = fit_main, fit_casl = fit_casl, fit_inst = fit_inst)
saveRDS(out, paste0(est_dir, "netest-", context, ".rds"))
