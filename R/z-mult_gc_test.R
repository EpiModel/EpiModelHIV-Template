source("R/shared_variables.R", local = TRUE)
library(EpiModelHIV)
context <- "local"
source("R/netsim_settings.R", local = TRUE)
est <- readRDS(path_to_est)
control <- control_msm(nsteps = 10 * year_steps, verbose = FALSE)

gc.time(on = TRUE)
st <- system.time({
  EpiModelHPC::netsim_scenarios(
    path_to_est, param, init, control,
    scenarios_list = NULL, # set to NULL to run with default params
    n_rep = 4,
    n_cores = 4,
    output_dir = scenarios_dir
  )
})
gt <- gc.time(on = TRUE)

print(st)
names(gt) <- c("user", "system", "elapsed", "child-user", "child-syst")
print("GC:")
print(gt)
