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

# Ergmkit calibration ----------------------------------------------------------
# The proposals per node the main and casual steps need with the separable
# step. The one-off network is drawn exactly and makes no proposals.
ergmkit_calibration <- list(
  main = calibrate_netest(est$fit_main, separable = TRUE),
  casl = calibrate_netest(est$fit_casl, separable = TRUE)
)
ergmkit_calibration_path <- fs::path(
  est_dir,
  paste0("ergmkit-calibration-", context, ".rds")
)
saveRDS(ergmkit_calibration, ergmkit_calibration_path)
message(
  "\nErgmkit calibration saved to \"", ergmkit_calibration_path, "\"\n"
)
