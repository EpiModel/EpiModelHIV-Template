## 1. Network Model Estimation
##
## Fit the network models using data from ARTnet

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(ARTnet)
library(EpiModelHIV)

source("R/shared_variables.R", local = TRUE)
source("R/A-networks/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

# Create the shared objects required by the project
source("R/A-networks/initialize.R", local = TRUE)

# 1. Main model
source("R/A-networks/model_main.R", local = TRUE)

# 2. Casual model
source("R/A-networks/model_casl.R", local = TRUE)

# 3. One-Off model
source("R/A-networks/model_ooff.R", local = TRUE)


# Save the data ----------------------------------------------------------------
netest <- list(fit_main = fit_main, fit_casl = fit_casl, fit_ooff = fit_ooff)
saveRDS(netest, fs::path(est_dir, paste0("netest-", context, ".rds")))

# Reduce the size of netstats and epistats before saving them
netstats <- ARTnet::trim_netstats(netstats)
epistats <- ARTnet::trim_epistats(epistats)

saveRDS(netstats, fs::path(est_dir, paste0("netstats-", context, ".rds")))
saveRDS(epistats, fs::path(est_dir, paste0("epistats-", context, ".rds")))
