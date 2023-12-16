#
## 02. Network Model Diagnostics
#

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R")
source("R/A-networks/z-context.R")

est <- readRDS(paste0(est_dir, "netest-", context, ".rds"))

# Main -------------------------------------------------------------------------
source("R/A-networks/main_diag.R")

# Casual -----------------------------------------------------------------------
source("R/A-networks/casl_diag.R")

# One-Off ----------------------------------------------------------------------
source("R/A-networks/ooff_diag.R")
