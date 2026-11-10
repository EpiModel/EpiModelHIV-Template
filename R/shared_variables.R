## Variables required all over the project
##
## This script should not be run directly. But `sourced` from other scripts

# EpiModelHIV-p local directory
EMHIVp_branch <- "v4.0.x"    # <- USER: your EpiModelHIV-p branch name

# Modeled city -----------------------------------------------------------------
#
# Everything specific to a city comes from the city registry in EpiModelHIV:
# the counties that define it, the size of its MSM population, its race
# composition, its ARTnet geography and its initial HIV prevalence
# (`EpiModelHIV::get_city_spec()`), and its calibration targets
# (`EpiModelHIV::get_calibration_targets()`). `EpiModelHIV::list_cities()`
# shows the cities the registry holds. None of those numbers is written in this
# project; to model a city the registry does not have, add it there.
#
# `city` works like `hpc_context`: assign it before sourcing a top-level script
# (`city <- "sf"`), or set the EPIMODELHIV_CITY environment variable, or take
# the default below. Estimates, simulations, outputs and HPC workflows are kept
# per city, so a project can model several cities without one overwriting
# another. HPC jobs get the city from the workflow that created them (see
# `R/hpc_configs.R`).
default_city <- "atl"        # <- USER: the city your project models
city <- if (exists("city", mode = "character")) {
  city
} else if (nzchar(Sys.getenv("EPIMODELHIV_CITY"))) {
  Sys.getenv("EPIMODELHIV_CITY")
} else {
  default_city
}
# Parallel workers started from this session source this file again without
# the `city` variable; they find the city here instead of the default. To
# change city within a session, assign `city` again.
Sys.setenv(EPIMODELHIV_CITY = city)

# The city's specification. `city_spec$msm.pop` is the size of the HPC networks
# and the `num` calibration target, `city_spec$race.prop` and
# `city_spec$init.hiv.prev` go to ARTnet in `R/A-networks/initialize.R`. An
# unknown city stops here: another city's values are never used in its place.
if (requireNamespace("EpiModelHIV", quietly = TRUE) &&
      exists("get_city_spec", envir = asNamespace("EpiModelHIV"))) {
  city_spec <- EpiModelHIV::get_city_spec(city)
} else {
  # Expected only in `R/00-setup.R`, before it installs your EpiModelHIV-p
  # branch
  message(
    "The installed EpiModelHIV has no city registry (version 4.5.0 or later),\n",
    "so `city_spec` is not set and the scripts that need it will stop.\n",
    "Install your EpiModelHIV-p branch: step 2 of `R/00-setup.R`."
  )
}

# Relevant time steps for the simulation
time_unit  <- 7               # number of days in a time step
year_steps <- 364 / time_unit # number of time steps in a year

prep_start         <- 0
calibration_end    <- 70 * year_steps
restart_time       <- 2 # Uses `EpiModel::make_restart_point`
intervention_start <- restart_time + 5 * year_steps
intervention_end   <- intervention_start + 10 * year_steps

# Paths to files and directories. Everything a run produces is kept per city.
# `data/input/` is shared: parameter overrides and scenario definitions apply to
# every city of the project.
input_dir      <- "data/input/"
run_dir        <- paste0("data/run/", city, "/")
output_dir     <- paste0("data/output/", city, "/")
est_dir        <- paste0(run_dir, "estimates/")
diag_dir       <- paste0(run_dir, "diagnostics/")
calib_dir      <- paste0(run_dir, "calibration/")
calib_plot_dir <- paste0(run_dir, "calibration_plots/")
scenarios_dir  <- paste0(run_dir, "scenarios/")
swfcalib_dir   <- paste0(run_dir, "swfcalib/")

for (.dir in c(est_dir, diag_dir, calib_dir, scenarios_dir, output_dir)) {
  if (!dir.exists(.dir)) dir.create(.dir, recursive = TRUE)
}
rm(.dir)

# Name of an HPC workflow for this city, so that the job trees of several
# cities sit side by side in `workflows/`: `wf_name("networks")` is
# "networks-atl" for Atlanta.
wf_name <- function(stem) paste0(stem, "-", city)
