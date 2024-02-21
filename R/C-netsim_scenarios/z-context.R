## Different setup for HPC and local context for the `C-netsim_scenarios` step
##
## This script should not be run directly. But `sourced` from other scripts
## within the `R/C-netsim_scenarios/` directory.

if (exists("hpc_context") && hpc_context) {
  context <- "hpc"
} else {
  context <- "local"
}
