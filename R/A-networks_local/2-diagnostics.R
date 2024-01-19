#
## 02. Network Model Diagnostics
#

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/A-networks_local/z-context.R", local = TRUE)

est <- readRDS(fs::path(est_dir, paste0("netest-", context, ".rds")))

# Main -------------------------------------------------------------------------
source("R/A-networks_local/main_diag.R", local = TRUE)

# Casual -----------------------------------------------------------------------
source("R/A-networks_local/casl_diag.R", local = TRUE)

# One-Off ----------------------------------------------------------------------
source("R/A-networks_local/ooff_diag.R", local = TRUE)
