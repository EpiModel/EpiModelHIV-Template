#
## 02. Network Model Diagnostics
#

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R")
source("R/A-networks_local/z-context.R")

est <- readRDS(fs::path(est_dir, paste0("netest-", context, ".rds")))

# Main -------------------------------------------------------------------------
source("R/A-networks_local/main_diag.R")

# Casual -----------------------------------------------------------------------
source("R/A-networks_local/casl_diag.R")

# One-Off ----------------------------------------------------------------------
source("R/A-networks_local/ooff_diag.R")
