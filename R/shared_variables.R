## Variables required all over the project
##
## This script should not be run directly. But `sourced` from other scripts

# EpiModelHIV-p local directory
EMHIVp_branch <- "v3.1.x"
EMHIVp_dir    <- "~/../Desktop/GitHub/EpiModelHIV-p"

# Relevant time steps for the simulation
time_unit  <- 7               # number of days in a time step
year_steps <- 364 / time_unit # number of time steps in a year

prep_start         <- 0
calibration_end    <- 70 * year_steps
restart_time       <- calibration_end + 1
intervention_start <- restart_time + 5 * year_steps
intervention_end   <- intervention_start + 10 * year_steps

# Paths to files and directories
input_dir      <- "data/input/"
run_dir        <- "data/run/"
output_dir     <- "data/output/"

est_dir        <- paste0(run_dir, "estimates/")
diag_dir       <- paste0(run_dir, "diagnostics/")
calib_dir      <- paste0(run_dir, "calibration/")
calib_plot_dir <- paste0(run_dir, "calibration_plots/")
scenarios_dir  <- paste0(run_dir, "scenarios/")
swfcalib_dir   <- paste0(run_dir, "swfcalib/")
