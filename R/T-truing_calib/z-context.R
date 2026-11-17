## Context for the `T-truing_calib` chapter: an automated `truing` calibration
## on the HPC (10k nodes, 70-year runs from restart points, ergmkit modules).
##
## This script should not be run directly. But `sourced` from the other scripts
## of `R/T-truing_calib/`.

context <- "local" # the 10k-node estimates, also on the HPC

# One calibration = one directory of state, results, batches and pools
truing_calib_name <- Sys.getenv("TRUING_CALIB", "emhiv10k_2026-11")
truing_calib_dir  <- fs::path(run_dir, "truing_calib", truing_calib_name)

# The engine: the `truing` package sources, synced next to the project root
# on the HPC (`rsync calibration_work/truing/ <hpc project>/truing/`)
truing_engine_dir <- Sys.getenv("TRUING_ENGINE", "truing")

# Each run is scored on its outputs' means over its last years
truing_score_years <- 5L

# Array tasks: `truing_runs_per_task` runs on as many cores
truing_runs_per_task <- 8L

# Slurm
truing_job_prefix <- "claude_"
truing_partition <-
  "epimodel,short-cpu,day-long-cpu,week-long-cpu,month-long-cpu"

# `TRUING_TINY=1`: a tiny calibration of 1-year runs (calibration "TINY")
# `TRUING_LOCAL_TEST=1`: the same, run here without Slurm ("LOCAL_TEST")
truing_local_test <- nzchar(Sys.getenv("TRUING_LOCAL_TEST"))
truing_tiny <- truing_local_test || nzchar(Sys.getenv("TRUING_TINY"))
if (truing_tiny) {
  truing_calib_name <- if (truing_local_test) "LOCAL_TEST" else "TINY"
  truing_calib_dir  <- fs::path(run_dir, "truing_calib", truing_calib_name)
  truing_runs_per_task <- 2L
  truing_score_years <- 1L
}
