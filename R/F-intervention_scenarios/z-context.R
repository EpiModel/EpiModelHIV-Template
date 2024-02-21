## Different setup for HPC and local context for the `F-intervention_scenarios` step
##
## This script should not be run directly. But `sourced` from other scripts
## within the `R/F-intervention_scenarios/` directory.

if (exists("hpc_context") && hpc_context) {
  context <- "hpc"
} else {
  context <- "local"
}
