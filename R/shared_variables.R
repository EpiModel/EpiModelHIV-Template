## Variables required all over the project
##
## This script should not be run directly. But `sourced` from other scripts

# EpiModelHIV-p local directory
EMHIVp_branch <- "v4.0.x"    # <- USER: your EpiModelHIV-p branch name

# Size of the modeled population: MSM in the four EHE-priority counties of
# metropolitan Atlanta (Fulton 30,169, DeKalb 20,302, Cobb 11,388, Gwinnett
# 13,378), from Grey et al. 2016 (JMIR Public Health Surveill 2(1):e14),
# past-five-year definition, men 18 and over. The HIV diagnosis rate targets in
# `EpiModelHIV::get_calibration_targets()` are per 100 person-years over this
# population, and `race_prop` in `R/A-networks/initialize.R` is the race
# composition of the same four counties.
#
# On the HPC the networks are estimated at this size, so the model's `num` is
# the denominator of the rate targets and model counts read as counts in that
# population. It is also the `num` calibration target. Local runs use 10,000
# nodes whatever this value is (`R/A-networks/z-context.R`).
msm_pop <- 75237             # <- USER: MSM population of the area you model

# Relevant time steps for the simulation
time_unit  <- 7               # number of days in a time step
year_steps <- 364 / time_unit # number of time steps in a year

prep_start         <- 0
calibration_end    <- 70 * year_steps
restart_time       <- 2 # Uses `EpiModel::make_restart_point`
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
