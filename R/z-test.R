# Scratchpad for interactive testing before integration in a script
source("R/shared_variables.R", local = TRUE)
# library(EpiModelHIV)
pkgload::load_all("../../EpiModel.git/main/")
pkgload::load_all(EMHIVp_dir)
context <- "local"
source("R/netsim_settings.R", local = TRUE)
est <- readRDS(path_to_est)

# options(error = recover)

control <- control_msm(
  nsteps = 10 * year_steps,
  # check.attrs.types = TRUE,
  verbose = FALSE
)

system.time({
  sim <- netsim(est, param, init, control)
})