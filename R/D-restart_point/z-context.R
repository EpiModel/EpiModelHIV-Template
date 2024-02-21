## Different setup for HPC and local context for the `D-restart_point` step
##
## This script should not be run directly. But `sourced` from other scripts
## within the `R/D-restart_point/` directory.
##
if (exists("hpc_context") && hpc_context) {
  context <- "hpc"
} else {
  context <- "local"
}
