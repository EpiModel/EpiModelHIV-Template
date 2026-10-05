## Configuration for cycle 3 of the restart-variance assessment
##
## This script should not be run directly. But `sourced` from the scripts in
## `R/E-restart_assessment/cycle3/`.
##
## Cycle 3 analyses the 256 x 600-year runs started from a COLD START
## (`df__variance_long_x0.rds`, made by `R/C-new_calibration/workflow-variance.R`
## from `path_to_est`). It re-uses the cycle 1 and cycle 2 configurations,
## functions, annual dataset and tables READ-ONLY, and writes only to its own
## folders so that the earlier cycles stay untouched for comparison.
##
## Time convention (cold start): step 1 is the initialisation, where only
## `num` is recorded. Year k covers weekly steps (k - 1) * 52 + 1 ... k * 52,
## so year 1 has 51 simulated weeks (steps 2-52). A research run started from
## the state at the end of year B covers years B + 1 ... B + L.
## The x0 runs of cycles 1-2 keep their own convention (year k after the
## restart = steps (k - 1) * 52 + 2 ... k * 52 + 1).

# Cycle 1 and 2 settings (paths, tunables, project design constants) --------
source("R/E-restart_assessment/cycle2/c2_config.R")
source("R/E-restart_assessment/cycle2/c2_utils.R")

# Output locations (override the cycle 2 ones used by write_tab / save_fig)
C3_DIR     <- "R/E-restart_assessment/cycle3/"
RES_DIR    <- fs::path(C3_DIR, "results")
TAB_DIR    <- fs::path(RES_DIR, "tables")
FIG_DIR    <- fs::path(RES_DIR, "figures")
LOG_DIR    <- fs::path(RES_DIR, "logs")
INTER3_DIR <- fs::path(INTER_DIR, "cycle3")
C2_TAB_DIR <- "R/E-restart_assessment/cycle2/results/tables" # read-only
for (d in c(TAB_DIR, FIG_DIR, LOG_DIR, INTER3_DIR)) fs::dir_create(d)

# Data -------------------------------------------------------------------------
COLD_PATH        <- fs::path(run_dir, "variance", "df__variance_long_x0.rds")
COLD_ANNUAL_PATH <- fs::path(INTER3_DIR, "c3_01_annual_cold.rds")
X0_ANNUAL_PATH   <- ANNUAL_PATH # cycle 1 annual data (runs from x0)
# Exact `netsim` inputs sent to the HPC for the cold-start runs
WF_MAP_PATH <- "workflows/variance_assess_raw/SWF/steps/2/map.rds"
# Sibling clone of EpiModelHIV-p, to diff the model code between the runs
EMHIV_REPO  <- "../EpiModelHIV-p"
# Commit of this project whose `renv.lock.hpc` updated EpiModelHIV-p between
# the x0 runs (2026-09-18) and the cold-start runs (2026-09-25)
RENV_UPDATE_COMMIT <- "1ff17d2"

# Cold-start convergence (steps c3_02, c3_04) ----------------------------------
FIT_START  <- 5    # first year used in relaxation fits (brief step 05.5)
TAIL_LEVEL <- 3    # mean fits start once |offset| stays <= 3 SD_pi (C3-M3)
EPS_C3     <- c(0.05, 0.1, 0.2) # variance tolerances |v(t) / v_pi - 1|
DELTA_C3   <- c(0.1, 0.2)       # mean tolerances |o(t)| (SD_pi units)
PLANNED_N_C3 <- c(32, 128, 256, 1024) # runs: per scenario, per wave, ...
MCSE_FRAC  <- 0.2  # brief M2.6: residual bias |b| <= 0.2 MCSE
PROD_BURNIN <- 70  # production burn-in = calibration_end (years)
CALIB_T    <- c(20, 30, 50, 70, 100, 150, 200) # cold-start run lengths
PCT_TOL    <- c(1, 2, 5) # relative tolerances on calibration targets (%)
N_BOOT_FIT <- 200  # bootstrap refits (as cycles 1-2)

# Same stationary law? (step c3_03) ---------------------------------------------
N_PERM       <- 2000 # chain permutations for the two-sample tests
ED_YEAR_STEP <- 25   # years between cross-sections in the energy test

# Equilibrium analyses on the cold-start runs (step c3_06) ----------------------
# First year treated as stationary in the cold-start runs. Set from c3_04
# (`c3_04_eq_start.csv`): the slowest fitted time to 0.1 SD / 10% over key
# and state variables (190 y, variance of prep.indic.H), rounded up to 10
# years, plus a 50-year margin, as for cycle 1's EQ_START. c3_06 checks it
# against that table and stops if it is too early.
EQ_START_C3 <- 240
