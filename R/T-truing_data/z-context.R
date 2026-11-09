## Context for the `T-truing_data` chapter
##
## Black-box calibration data for `truing`: cold 70-year runs on the 10k-node
## (local) estimates, also on the HPC, with the ergmkit modules.
##
## This script should not be run directly. But `sourced` from the other scripts
## of `R/T-truing_data/`.

# The 10k-node estimates (`data/run/estimates/*-local.rds`) everywhere: upload
# them to the HPC clone before the first workflow.
context <- "local"

# One campaign = one sequence of waves, from one set of starting values
truing_campaign <- "cold10k_2026-11"
truing_dir      <- fs::path(run_dir, "truing", truing_campaign)

# Intermediates (raw `netsim` batches, merged tibbles): the gather step deletes
# them once the formatted results are written.
truing_sim_dir <- fs::path(calib_dir, "truing_sims")
truing_df_dir  <- fs::path(calib_dir, "truing_df")

# Base seed of the campaign: array element `k` of a design runs after
# `set.seed(truing_seed + 1e6 * design_index + k)` (see `.Rprofile`)
truing_seed <- 20261107L

# Cores available at once on the HPC
truing_max_cores <- 32
