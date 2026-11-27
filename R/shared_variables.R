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
calib_plot_dir <- paste0(run_dir, "calibration_plots/")
scenarios_dir  <- paste0(run_dir, "scenarios/")

# swfcalib calibration pass. Pass 1 writes to `calibration/` and `swfcalib/`.
# Pass n starts every wave from pass n - 1's fitted values (see "Later passes"
# in `R/C-calibration/swfcalib_config.R`) and writes to `calibration-pass<n>/`
# and `swfcalib-pass<n>/`, so every pass's results stay on disk and a later
# pass never reads an earlier one's leftovers. Set `calib_pass` before
# sourcing; the swfcalib workflow passes it to the steps that run on the HPC.
if (!exists("calib_pass")) calib_pass <- 1L
calib_pass_suffix <- function(pass) if (pass == 1) "" else paste0("-pass", pass)
calib_dir <- paste0(run_dir, "calibration", calib_pass_suffix(calib_pass), "/")
swfcalib_dir <- paste0(run_dir, "swfcalib", calib_pass_suffix(calib_pass), "/")

# Each calibration run is scored on its mean over the final `calib_years`
# years (the swfcalib model function and `process_calibs.R`), not one. A rate
# built on small counts has a one-year mean that is mostly Poisson noise, which
# the GP then spends its replicates averaging out: in a city of about 60,000
# MSM with a small Black population, the model makes about 27 HIV diagnoses a
# year among Black MSM. At the drift the stop rule allows (0.25 tolerances per
# decade), the two-year shift of the window's midpoint biases a target by
# about 0.05 tolerances.
calib_years <- 5

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
message("Modeled city: ", city_spec$label)

# Size of the modeled population. On the HPC the networks are estimated at this
# size, so the model's `num` is the denominator of the rate targets. It is also
# the `num` calibration target. Local runs use 10,000 nodes.
msm_pop <- city_spec$msm.pop

# NETWORK SIMULATION SAMPLING: how many MCMC proposals tergm makes per time step
# when it moves the main and casual networks forward. One setting for every
# dynamic simulation, the network diagnostics (chapter A) and every netsim run
# (chapters B to D, passed to `control_msm()` as
# `set.control.tergm = control_tergm_sim()`), so the diagnostics test what the
# simulations run. Add it to any new `control_msm()` call.
#
# The engine default is adaptive, from 5,000 proposals up to 100,000, and its
# stopping rule does not keep up with the network: it took about 12,000
# proposals a step at 10,000 nodes and 40,000 at 250,000 nodes, while the
# partnerships that must form each step grow in proportion to the population.
# Total partnerships, degree and durations hold, but the pairs that form
# fastest for the dyads they have fall short. At 250,000 nodes, main
# partnerships within the youngest age group ran 8% under their target and
# casual partnerships within the smallest race group 17% under. A fixed
# 200,000 brought both within 2%, for about a tenth more run time at that size.
#
# The minimum and maximum are set equal because tergm silently caps a minimum
# above its default maximum of 100,000. A network much larger than 250,000
# nodes may need more: the network check (`R/A-networks/3-check.R`) tests the
# setting against each fit's targets and fails if it under-samples.
tergm_proposals <- 2e5
control_tergm_sim <- function() {
  tergm::control.simulate.formula.tergm(
    MCMC.burnin.min = tergm_proposals,
    MCMC.burnin.max = tergm_proposals,
    # The change log must hold every formation and dissolution of a long
    # diagnostic run, which passes tergm's default of 1e6 in a large casual
    # network (about 1.1 million over 500 steps at 250,000 nodes).
    MCMC.maxchanges = 1e7
  )
}
