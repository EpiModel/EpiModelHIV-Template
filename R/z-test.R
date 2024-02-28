# Scratchpad for interactive testing before integration in a script

pkgload::load_all("../EpiModelHIV-p.git/new_node_attr")
# library(EpiModelHIV)

source("R/shared_variables.R", local = TRUE)
source("R/B-netsim_explore/z-context.R")

prep_start <- 2 * year_steps
source("R/netsim_settings.R", local = TRUE)

control <- control_msm(
  nsteps = 4 * year_steps,
  verbose = TRUE,
  raw.output = TRUE
)

# Read in the previously estimated networks and inspect their content
est <- readRDS(path_to_est)
# debugonce(initialize_msm)
# debugonce(EpiModelHIV:::make_computed_attrs)
# options(error = recover)
start <- Sys.time()
dat <- netsim(est, param, init, control)[[1]]
print(Sys.time() - start)


