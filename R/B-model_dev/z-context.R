## Different setup for HPC and local context for the `B-model_dev` step
##
## This script should not be run directly. But `sourced` from other scripts
## within the `R/B-model_dev/` directory.

if (exists("hpc_context") && hpc_context) {
  context <- "hpc"
} else {
  context <- "local"
}
