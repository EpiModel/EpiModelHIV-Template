## Different setup for HPC and local context for the `C-calibration` step
if (exists("hpc_context") && hpc_context) {
  context <- "hpc"
} else {
  context <- "local"
}
