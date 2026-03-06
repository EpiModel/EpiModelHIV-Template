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
netest_path <- fs::path(est_dir, paste0("netest-", context, ".rds"))
saveRDS(netest, netest_path)

# Reduce the size of netstats and epistats before saving them
netstats <- ARTnet::trim_netstats(netstats)
epistats <- ARTnet::trim_epistats(epistats)

netstats_path <- fs::path(est_dir, paste0("netstats-", context, ".rds"))
saveRDS(netstats, netstats_path)

epistats_path <- fs::path(est_dir, paste0("epistats-", context, ".rds"))
saveRDS(epistats, epistats_path)

message(
  "\nEstimation files where saved to \"", est_dir , "\":\n",
  "    `netest`   -> \"", netest_path, "\"\n",
  "    `netstats` -> \"", netstats_path, "\"\n",
  "    `epistats` -> \"", epistats_path, "\"\n"
)
