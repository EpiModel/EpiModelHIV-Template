##
## 00. Shared variables setup
##

# Networks size for the analysis on HPC
networks_size   <- 100 * 1e3

# Information for the HPC workflows
current_git_branch <- "main"
mail_user <- "user@emory.edu"

# Relevant time steps for the simulation
calibration_end    <- 52 * 60
restart_time       <- calibration_end + 1
prep_start         <- restart_time + 52 * 5
intervention_start <- prep_start + 52 * 5
intervention_end   <- intervention_start + 52 * 10

