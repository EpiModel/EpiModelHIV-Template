suppressMessages({
  source("R/shared_variables.R", local = TRUE)
  library(EpiModelHIV)
  context <- "local"
  source("R/netsim_settings.R", local = TRUE)
  est <- readRDS(path_to_est)

  control <- control_msm(
    nsims = 12,
    ncores = 6,
    nsteps = 20 * year_steps,
    verbose = FALSE
  )
})
if (file.exists("tmp_sim.Rds")) unlink("tmp_sim.Rds")

start <- Sys.time()
gc.time(on = TRUE)
st <- system.time({
  sim <- netsim(est, param, init, control)
  saveRDS(sim, "tmp_sim.Rds")
})
gt <- gc.time(on = TRUE)
print(start - Sys.time())


print(st)
names(gt) <- c("user", "system", "elapsed", "child-user", "child-syst")
print("GC:")
print(gt)