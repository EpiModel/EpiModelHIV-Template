##
## 01. Network Model Estimation
##

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/A-networks/z-context.R", local = TRUE)

# Create the shared objects required by the project
source("R/A-networks/initialize.R", local = TRUE)

# 1. Main Model ----------------------------------------------------------------
source("R/A-networks/model_main.R", local = TRUE)

# 2. Casual Model --------------------------------------------------------------
source("R/A-networks/model_casl.R", local = TRUE)

# 3. One-Off Model -------------------------------------------------------------
source("R/A-networks/model_ooff.R", local = TRUE)

# 4. Save Data -----------------------------------------------------------------
netest <- list(fit_main = fit_main, fit_casl = fit_casl, fit_ooff = fit_ooff)
saveRDS(netest, fs::path(est_dir, paste0("netest-", context, ".rds")))

# Reduce the size of netstats and epistats before saving them
netstats <- ARTnet::trim_netstats(netstats)
saveRDS(netstats, fs::path(est_dir, paste0("netstats-", context, ".rds")))

epistats <- ARTnet::trim_epistats(epistats)
saveRDS(epistats, fs::path(est_dir, paste0("epistats-", context, ".rds")))
