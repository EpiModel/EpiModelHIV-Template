##
## 00. Shared variables setup
##

est_dir <- "./data/intermediate/estimates/"
diag_dir <- "./data/intermediate/diagnostics/"
calib_dir <- "./data/intermediate/calibration/"
scenarios_dir <- "./data/intermediate/scenarios/"

# Information for the HPC workflows
current_git_branch <- "main"
mail_user <- "USER@emory.edu" # or any other mail provider

# Relevant time steps for the simulation
calibration_end    <- 52 * 60
restart_time       <- calibration_end + 1
prep_start         <- restart_time + 52 * 5
intervention_start <- prep_start + 52 * 10
intervention_end   <- intervention_start + 52 * 10
