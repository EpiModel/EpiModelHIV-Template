## Configuration for the restart-variance assessment
##
## This script should not be run directly. But `sourced` from the numbered
## scripts in `R/E-restart_assessment/`. Every path and tunable lives here.
##
## Time convention: the restart happens at year 0 (the common state x0 shared
## by all chains). Year k after restart covers weekly steps
## (k - 1) * 52 + 2 ... k * 52 + 1 of the raw data (`time == 2` is x0).
## A research window of L years started from a state at the end of year t0
## covers years t0 + 1 ... t0 + L.

source("R/shared_variables.R")

# Paths ------------------------------------------------------------------------
RA_DIR       <- "R/E-restart_assessment/"
RES_DIR      <- fs::path(RA_DIR, "results")
TAB_DIR      <- fs::path(RES_DIR, "tables")
FIG_DIR      <- fs::path(RES_DIR, "figures")
LOG_DIR      <- fs::path(RES_DIR, "logs")
DATA_PATH    <- fs::path(run_dir, "variance", "df__variance_long.rds")
INTER_DIR    <- fs::path(run_dir, "restart_assessment")
ANNUAL_PATH  <- fs::path(INTER_DIR, "01_annual.rds")

for (d in c(TAB_DIR, FIG_DIR, LOG_DIR, INTER_DIR)) fs::dir_create(d)

# General ----------------------------------------------------------------------
SEED       <- 20260925
N_YEARS    <- 600
N_BOOT     <- 500         # chain-bootstrap replicates
N_CORES    <- max(1, min(8, parallel::detectCores() - 2)) # forked workers
# Parallel-safe RNG streams: with mclapply each worker gets its own stream,
# reproducible given SEED and N_CORES
RNGkind("L'Ecuyer-CMRG")
# Chains where syphilis went extinct (absorbing). Excluded from every analysis
# so all variables use the same chains (see 01_prepare_annual.md).
DROP_SIMS  <- c(75, 88)

# Stationarity (step 03) -------------------------------------------------------
LATE_START     <- 300     # years >= LATE_START are the reference for pi
DRIFT_PERIODS  <- list(c(300, 600), c(150, 600))
VAR_DRIFT_TOL  <- 0.05    # flag if variance changes > 5% per century
MEAN_DRIFT_TOL <- 0.05    # flag if mean drifts > 0.05 SD_pi per century

# Relaxation from the restart point (step 04) ----------------------------------
REF_YEARS     <- seq(300, 550, 50)  # reference cross-sections (energy dist.)
N_SPLITS      <- 20                 # random half-splits of chains
PCA_VAR       <- 0.95               # variance kept when whitening
T_Q           <- 0.95               # brief's rule (validation only)
T_MAX_RUN     <- 3                  # brief's rule (validation only)
SMOOTH_W      <- 5                  # running-mean width for T_full (years)
T_THRESH      <- c("max", "0.99", "0.95") # null thresholds for T_full
VAR_EPS       <- c(0.05, 0.10, 0.20) # "full variance" tolerances
BURNIN_GRID   <- c(0:30, seq(35, 100, 5), seq(120, 250, 10))

# Equilibrium structure (step 05) ----------------------------------------------
EQ_START       <- 150     # first year treated as stationary (set from 04)
WINDOW_L       <- 20      # research-run length (years)
ACF_MAX_LAG    <- 150
VT_L_GRID      <- c(1, 2, 3, 5, 10, 15, 20, 30, 50, 75, 100, 150)

# Restart memory (step 06) -----------------------------------------------------
HORIZONS            <- 0:40
H_SUBSET            <- c(0, 1, 2, 3, 5, 7, 10, 15, 20, 25, 30, 40)
PSEUDO_RESTART_STEP <- 5
FEATURE_LAGS        <- c(1, 2, 5)
CV_FOLDS            <- 8
RIDGE_LAMBDAS       <- 10^seq(-3, 3, length.out = 25)

# Pool design (step 07) --------------------------------------------------------
POOL_K         <- c(1, 2, 4, 8, 16, 32, 64, 128, 256)
PLANNED_N      <- c(64, 256, 1024)   # candidate research run counts
ICC_THRESHOLD  <- 0.05
SEL_K          <- 32                 # pool size in the selection experiment
SEL_REPS       <- 2000               # random pools per selection strategy
