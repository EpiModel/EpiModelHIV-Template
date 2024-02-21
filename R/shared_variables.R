## Variables required all over the project
##
## This script should not be run directly. But `sourced` from other scripts

# EpiModelHIV-p local directory
EMHIVp_branch <- "applied_proj"
EMHIVp_dir    <- "Desktop\\git\\EpiModelHIV-p"

# Relevant time steps for the simulation
time_unit  <- 7               # number of days in a time step
year_steps <- 364 / time_unit # number of time steps in a year

calibration_end    <- 60 * year_steps
restart_time       <- calibration_end + 1
prep_start         <- restart_time + 5 * year_steps
intervention_start <- prep_start + 10 * year_steps
intervention_end   <- intervention_start + 10 * year_steps

# Paths to files and directories
est_dir        <- "data/intermediate/estimates/"
diag_dir       <- "data/intermediate/diagnostics/"
calib_dir      <- "data/intermediate/calibration/"
calib_plot_dir <- "data/intermediate/calibration_plots/"
scenarios_dir  <- "data/intermediate/scenarios/"
