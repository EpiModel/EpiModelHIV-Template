## Different setup for HPC and local context for the `A-networks` step
##
## This script should not be run directly. But `sourced` from other scripts
## within the `R/A-networks/` directory.

if (exists("hpc_context") && hpc_context) {
  context <- "hpc"
  networks_size   <- 100 * 1e3
  est_cores <- 10

  control_ergm <- ergm::control.ergm(
    main.method = "MCMLE",
    MCMLE.maxit = 500,
    SAN.maxit = 3,
    SAN.nsteps.times = 4,
    MCMC.samplesize = 1e4,
    MCMC.interval = 5e3,
    parallel = est_cores
  )

  diag_ncores <- 10
  diag_nsims <- 100
  diag_nsteps <- 500

} else {
  context <- "local"
  networks_size   <- 10 * 1e3
  control_ergm <- ergm::control.ergm(
    main.method = "Stochastic-Approximation",
    MCMLE.maxit = 500,
    SAN.maxit = 3,
    SAN.nsteps.times = 4,
    MCMC.samplesize = 1e4,
    MCMC.interval = 5e3,
    parallel = 1
  )

  diag_ncores <- 2
  diag_nsims <- 4
  diag_nsteps <- 50
}
