## Different setup for HPC and local context for the `B-netsim_explore` step
##
## This script should not be run directly. But `sourced` from other scripts
## within the `R/B-netsim_explore/` directory.

if (exists("hpc_context") && hpc_context) {
  context <- "hpc"
} else {
  context <- "local"
}
