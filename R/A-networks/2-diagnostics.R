## 2. Network Model Diagnostics
##
## Compute the diagnostics for the estimated network models. They are assessed
## in the next script.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)

source("R/shared_variables.R", local = TRUE)
source("R/A-networks/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

# Read in the estimated networks
est <- readRDS(fs::path(est_dir, paste0("netest-", context, ".rds")))

# Run diagnostics for the 3 models
source("R/A-networks/diag_main.R", local = TRUE)
source("R/A-networks/diag_casl.R", local = TRUE)
source("R/A-networks/diag_ooff.R", local = TRUE)

message("\n\n", "Network diagnostics are saved in: \"", diag_dir, "\"")
