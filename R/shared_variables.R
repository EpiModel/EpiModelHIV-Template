## Variables required all over the project
##
## This script should not be run directly. But `sourced` from other scripts

# EpiModelHIV-p local directory
EMHIVp_branch <- "v4.0.x"    # <- USER: your EpiModelHIV-p branch name

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

# The modeled city -------------------------------------------------------------
#
# What the city is comes from `data/input/city.csv`: its MSM population, race
# composition, ARTnet geography and initial HIV prevalence. The template ships
# Atlanta's. To model another city, replace it and add the city's calibration
# targets as `data/input/targets.csv`: see "Modeling another city" in the
# README for the two formats.
city_table <- read.csv(paste0(input_dir, "city.csv"), colClasses = "character")
city_values <- setNames(city_table$value, city_table$param)
city_spec <- list(
  label = city_values[["label"]],
  msm.pop = as.numeric(city_values[["msm.pop"]]),
  race.prop = as.numeric(city_values[paste0("race.prop_", 1:3)]),
  geog.lvl = city_values[["geog.lvl"]],
  geog.cat = city_values[["geog.cat"]],
  init.hiv.prev = as.numeric(city_values[paste0("init.hiv.prev_", 1:3)])
)

# Size of the modeled population. On the HPC the networks are estimated at this
# size, so the model's `num` is the denominator of the rate targets. It is also
# the `num` calibration target. Local runs use 10,000 nodes.
msm_pop <- city_spec$msm.pop
