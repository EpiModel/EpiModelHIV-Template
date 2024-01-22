## Example interactive epidemic simulation run script with basic
## parameterization and all parameters defined in `param_msm`, with example of
## writing/debugging modules

# Libraries  -------------------------------------------------------------------
library("EpiModelHIV")

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("R/B-netsim_local/z-context.R", local = TRUE)

# set prep start to a low value to test the full model in a few steps
prep_start <- 2 * year_steps
source("R/netsim_settings.R", local = TRUE)

# See full listing of parameters
# See ?param_msm for definitions
print(param)

# See the initialization object
print(init)

# See listing of modules and other control settings
# Module function defaults defined in ?control_msm
print(control)

# Reduce the length of the simulation and make it verbose
control$nsteps <- prep_start + year_steps * 3
control$verbose <- TRUE

# Read in the previously estimated networks and inspect their content
est <- readRDS(path_to_est)

print(est$fit_main)
print(est$fit_casl)
print(est$fit_ooff)

# Epidemic simulation
sim <- netsim(est, param, init, control)

# Examine the model object output
print(sim)

# Plot outcomes
par(mar = c(3, 3, 2, 2), mgp = c(2, 1, 0))
plot(sim, y = "i.num", main = "Prevalence")
plot(sim, y = "ir100", main = "Incidence")

# Convert to data frame
df <- as.data.frame(sim)
head(df)
tail(df)

## Run 2 simulations on 2 cores
## Note: this will not run generate a progress tracker in the console
control$nsims <- 2
control$ncores <- 2

sim <- netsim(est, param, init, control)

par(mfrow = c(2, 1))
plot(sim, y = "i.num", main = "Prevalence")
plot(sim, y = "ir100", main = "Incidence")
