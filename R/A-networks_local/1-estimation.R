##
## 01. Network Model Estimation
##

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R")
source("R/A-networks_local/z-context.R")
source("R/A-networks_local/initialize.R")

# 1. Main Model ----------------------------------------------------------------
source("R/A-networks_local/main_model.R")

# 2. Casual Model --------------------------------------------------------------
source("R/A-networks_local/casl_model.R")

# 3. One-Off Model -------------------------------------------------------------
source("R/A-networks_local/ooff_model.R")

# 4. Save Data -----------------------------------------------------------------
out <- list(fit_main = fit_main, fit_casl = fit_casl, fit_ooff = fit_ooff)
saveRDS(out, fs::path(est_dir, paste0("netest-", context, ".rds")))

# Reduce the size of netstats and epistats before saving them
netstats <- ARTnet::trim_netstats(netstats)
saveRDS(netstats, fs::path(est_dir, paste0("netstats-", context, ".rds")))

epistats <- ARTnet::trim_epistats(epistats)
saveRDS(epistats, fs::path(est_dir, paste0("epistats-", context, ".rds")))
