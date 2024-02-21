## Different setup for HPC and local context for the `Z-calibration` step
##
## This script should not be run directly. But `sourced` from other scripts
## within the `R/Z-calibration/` directory.

if (exists("hpc_context") && hpc_context) {
  context <- "hpc"
} else {
  context <- "local"
}
