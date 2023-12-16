##
## 01. Network Model Estimation
##

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R")
source("R/A-networks/z-context.R")
source("R/A-networks/initialize.R")

# 1. Main Model ----------------------------------------------------------------
source("R/A-networks/main_model.R")

# 2. Casual Model --------------------------------------------------------------
source("R/A-networks/casl_model.R")

# 3. One-Off Model -------------------------------------------------------------
source("R/A-networks/ooff_model.R")

# 4. Save Data -----------------------------------------------------------------
out <- list(fit_main = fit_main, fit_casl = fit_casl, fit_ooff = fit_ooff)
saveRDS(out, paste0(est_dir, "netest-", context, ".rds"))

# Reduce the size of netstats and epistats before saving them
netstats <- ARTnet::trim_netstats(netstats)
saveRDS(netstats, paste0(est_dir, "netstats-", context, ".rds"))

epistats <- ARTnet::trim_epistats(epistats)
saveRDS(epistats, paste0(est_dir, "epistats-", context, ".rds"))

