##
## 00. Shared variables setup
##

# Information for the HPC workflows
current_git_branch <- "main"
mail_user <- "USER@emory.edu" # or any other mail provider

# Relevant time steps for the simulation
time_unit <- 7                # number of days in a time step
year_steps <- 364 / time_unit # number of time steps in a year

calibration_end    <- 60 * year_steps
restart_time       <- calibration_end    + 1
prep_start         <- restart_time       + 5 * year_steps
intervention_start <- prep_start         + 10 * year_steps
intervention_end   <- intervention_start + 10 * year_steps

# Paths to files and directories
est_dir <- "data/intermediate/estimates/"
diag_dir <- "data/intermediate/diagnostics/"
calib_dir <- "data/intermediate/calibration/"
scenarios_dir <- "data/intermediate/scenarios/"
