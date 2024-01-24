#
## 02. Network Model Diagnostics
#

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/A-networks/z-context.R", local = TRUE)

est <- readRDS(fs::path(est_dir, paste0("netest-", context, ".rds")))

# Main -------------------------------------------------------------------------
source("R/A-networks/diag_main.R", local = TRUE)

# Casual -----------------------------------------------------------------------
source("R/A-networks/diag_casl.R", local = TRUE)

# One-Off ----------------------------------------------------------------------
source("R/A-networks/diag_ooff.R", local = TRUE)
