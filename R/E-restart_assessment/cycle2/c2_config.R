## Configuration for cycle 2 of the restart-variance assessment
##
## This script should not be run directly. But `sourced` from the scripts in
## `R/E-restart_assessment/cycle2/`.
##
## Cycle 2 re-uses the cycle 1 configuration, functions and annual dataset
## READ-ONLY, and writes everything to its own folders so that the cycle 1
## results stay untouched for comparison.

source("R/E-restart_assessment/00_config.R")
source("R/E-restart_assessment/utils.R")

# Output locations (override the cycle 1 ones used by write_tab / save_fig)
C2_DIR    <- "R/E-restart_assessment/cycle2/"
RES_DIR   <- fs::path(C2_DIR, "results")
TAB_DIR   <- fs::path(RES_DIR, "tables")
FIG_DIR   <- fs::path(RES_DIR, "figures")
LOG_DIR   <- fs::path(RES_DIR, "logs")
INTER2_DIR <- fs::path(INTER_DIR, "cycle2")
C1_TAB_DIR <- "R/E-restart_assessment/results/tables" # cycle 1, read-only
for (d in c(TAB_DIR, FIG_DIR, LOG_DIR, INTER2_DIR)) fs::dir_create(d)

# Project design, read from the project code (see REVIEW.md) -----------------
# D-interventions/workflow-intervention.R and shared_variables.R:
#   runs start at the restart point, intervention_start = restart + 5 years,
#   intervention_end = intervention_start + 10 years, 32 runs per scenario in
#   batches of 8 (`n_cores`), default `randomize.restart = FALSE`.
# D-interventions/outcomes.R: cumulative HIV incidence over the intervention
#   period (years 6-15 after restart) and last-year incidence (year 15).
# C-new_calibration/swfcalib_model.R: calibration runs from the restart last
#   `calibration_end` = 70 years; targets are averaged over the last year.
INT_B      <- 5    # years between restart and intervention start
INT_L      <- 10   # intervention period (years)
INT_END    <- INT_B + INT_L # 15: year of the "last-year" outcomes
CALIB_H    <- 70   # year after restart at which calibration targets are read
N_REP_INT  <- 32   # runs per scenario in the intervention workflow
N_CORES_INT <- 8   # runs per batch = points actually used with recycling

# Extended horizons for the same-parameter lower bounds -----------------------
H_LONG   <- c(5, 10, 15, 20, 30, 40, 50, 60, 70, 80)
B_LONG   <- c(0, 5, 10, 20, 30, 40, 50, 60, 70)

# Robustness / replication ------------------------------------------------------
N_REP_SIM   <- 30   # replicated synthetic datasets per series
N_BOOT_REP  <- 100  # bootstrap refits inside each replicate

# Selection experiment ------------------------------------------------------------
SEL_Q    <- c(1, 0.75, 0.5, 0.25, 0.125) # fraction of candidates kept
SEL_F    <- c(0.5, 1, 2, 5, 10)          # data-error SD in units of SD_pi
