## Configuration for cycle 4 of the restart-variance assessment
##
## This script should not be run directly. But `sourced` from the scripts in
## `R/E-restart_assessment/cycle4/`.
##
## Cycle 4 analyses 256 x 600-year runs restarted from a POOL of 32 states
## (`df__variance_long_pool.rds`, made by `R/C-new_calibration/workflow-variance.R`
## with `path_to_restart` and `randomize.restart = TRUE`). The 32 states are
## the final (year-600) states of cold-start runs 1-32 of cycle 3. Earlier
## cycles are read READ-ONLY; cycle 4 writes only to its own folders.
##
## Time convention (as the x0 runs of cycles 1-2): step 2 is the copied
## restart state. Year k after the restart covers steps
## (k - 1) * 52 + 2 ... k * 52 + 1. A research window of L years started
## after a burn-in B covers years B + 1 ... B + L.

# Cycle 1-3 settings (paths, tunables, design constants) ----------------------
source("R/E-restart_assessment/cycle3/c3_config.R")
source("R/E-restart_assessment/cycle3/c3_utils.R")

# Output locations (override the cycle 3 ones used by write_tab / save_fig)
C4_DIR     <- "R/E-restart_assessment/cycle4/"
RES_DIR    <- fs::path(C4_DIR, "results")
TAB_DIR    <- fs::path(RES_DIR, "tables")
FIG_DIR    <- fs::path(RES_DIR, "figures")
LOG_DIR    <- fs::path(RES_DIR, "logs")
INTER4_DIR <- fs::path(INTER_DIR, "cycle4")
C3_TAB_DIR <- "R/E-restart_assessment/cycle3/results/tables" # read-only
for (d in c(TAB_DIR, FIG_DIR, LOG_DIR, INTER4_DIR)) fs::dir_create(d)

# Data -------------------------------------------------------------------------
POOL_PATH        <- fs::path(run_dir, "variance", "df__variance_long_pool.rds")
POOL_ANNUAL_PATH <- fs::path(INTER4_DIR, "c4_01_annual_pool.rds")
POOL_RESTART     <- fs::path(est_dir, "restart_pool_2026-09-27.rds") # the 32 states (renamed 2026-09-29, when a new pool replaced restart_pool.rds)
WF_POOL_MAP      <- "workflows/variance_assess_pool/SWF/steps/2/map.rds"
N_WEEKS_SEAM     <- 104 # weeks on each side of the restart (continuity)

# Direct ICC (steps c4_02, c4_04) -------------------------------------------------
H_MAX      <- 150            # horizons 1 ... H_MAX (years after restart)
B_MAX      <- 150            # burn-ins 0 ... B_MAX for window functionals
N_BOOT_PT  <- 500            # bootstraps over restart points
H_REPORT   <- c(1, 2, 5, 10, 20, 30, 50, 70, 100)
B_REPORT   <- c(0, 5, 10, 20, 30, 50)
EPS_ICC    <- c(0.05, 0.1, 0.2) # "full variance" tolerances for one point

# Pool design (step c4_05) -----------------------------------------------------
POOL_K_C4  <- c(1, 2, 4, 8, 16, 32, 64, 128, 256)
PLANNED_N_C4 <- c(32, 256, 1024)
INFL_TOL   <- c(0.10, 0.25)  # tolerated MCSE inflation
