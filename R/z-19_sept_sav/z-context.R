## Different setup for HPC and local context for the `C-calibration` step
##
## This script should not be run directly. But `sourced` from other scripts
## within the `R/C-calibration/` directory.

if (exists("hpc_context") && hpc_context) {
  context <- "hpc"
} else {
  context <- "local"
}
