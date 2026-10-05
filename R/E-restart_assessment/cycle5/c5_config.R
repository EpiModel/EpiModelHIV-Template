## Configuration for cycle 5 of the restart-variance assessment
##
## This script should not be run directly. But `sourced` from the scripts in
## `R/E-restart_assessment/cycle5/`.
##
## Cycle 5 analyses the scenario runs of
## `R/C-new_calibration/workflow-variance_scenarios.R` (2026-09-28), all
## restarted from the 32-point pool (`restart_pool.rds`, the same states as
## cycle 4), with 4 runs per point and scenario (recycling, batches of 32):
##
## - short runs, 15 years, change at step 262 (start of year 6):
##   baseline, S1 HIV testing odds x 2, S2 PrEP initiation odds x 2,
##   S3 STI screening odds x 3;
## - long runs, 150 years, change from the restart: S4 acts.scale = 0.9.
##   Its baseline is the cycle 4 pool runs (same points, same parameters).
##
## Earlier cycles are read READ-ONLY; cycle 5 writes only to its own folders.
## Time convention (as cycle 4): step 2 is the copied restart state; year k
## covers steps (k - 1) * 52 + 2 ... k * 52 + 1.

# Cycle 1-4 settings -------------------------------------------------------------
source("R/E-restart_assessment/cycle4/c4_config.R")
source("R/E-restart_assessment/cycle4/c4_utils.R")

# Output locations (override the cycle 4 ones used by write_tab / save_fig)
C5_DIR     <- "R/E-restart_assessment/cycle5/"
RES_DIR    <- fs::path(C5_DIR, "results")
TAB_DIR    <- fs::path(RES_DIR, "tables")
FIG_DIR    <- fs::path(RES_DIR, "figures")
LOG_DIR    <- fs::path(RES_DIR, "logs")
INTER5_DIR <- fs::path(INTER_DIR, "cycle5")
for (d in c(TAB_DIR, FIG_DIR, LOG_DIR, INTER5_DIR)) fs::dir_create(d)

# Data -------------------------------------------------------------------------------
SC_DIR      <- fs::path(run_dir, "variance_scenarios")
SHORT_FILES <- c(
  baseline = "df__baseline.rds",
  s1_test  = "df__s1_test_or2.rds",
  s2_prep  = "df__s2_prep_or2.rds",
  s3_sti   = "df__s3_stiscreen_or3.rds"
)
LONG_FILE   <- "df__s4_acts090.rds"
SHORT_ANNUAL_PATH <- fs::path(INTER5_DIR, "c5_01_annual_short.rds")
LONG_ANNUAL_PATH  <- fs::path(INTER5_DIR, "c5_01_annual_long.rds")
WF_SC_SCRIPT <- "R/C-new_calibration/workflow-variance_scenarios.R"

# Design -----------------------------------------------------------------------------
N_POINTS_C5  <- 32
N_PER_ARM    <- 4        # runs per point and scenario
SHORT_YEARS  <- 15
LONG_YEARS   <- 150
AT_STEP      <- 262      # intervention_start: first step of year 6
SC_LABELS <- c(
  s1_test = "S1: HIV testing odds x 2",
  s2_prep = "S2: PrEP initiation odds x 2",
  s3_sti  = "S3: STI screening odds x 3",
  s4_acts = "S4: 10% fewer acts from the restart"
)

# Effects and heterogeneity (C5-M2, C5-M3) ----------------------------------------------
N_BOOT_C5   <- 2000      # bootstraps over restart points
N_SYN_C5    <- 1000      # synthetic replications for validation (c5_02)
SIGMA_E_THRESH <- c(current_ok = 0.6, random_better = 1.3) # pp, SCENARIOS.md 4.2

# Relaxation of S4 (C5-M5) ---------------------------------------------------------------
S4_EQ_YEARS <- 101:150   # years used for the S4 end level (checked for drift)
