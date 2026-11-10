## Different setup for HPC and local context for the `D-interventions` step
##
## This script should not be run directly. But `sourced` from other scripts
## within the `R/D-interventions/` directory.

if (!exists("city_spec")) {
  stop("No `city_spec`: source `R/shared_variables.R` before this script.")
}
message("City: ", city_spec$label, " (", city, ")")

if (exists("hpc_context") && hpc_context) {
  context <- "hpc"
} else {
  context <- "local"
}
