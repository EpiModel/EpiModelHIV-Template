# Scratchpad for interactive testing before integration in a script
library(EpiModelHIV)
library(dplyr)

source("R/shared_variables.R", local = TRUE)
source("R/C-netsim_scenarios/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

# Necessary files
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  nsteps = year_steps * 3,
  .tracker.list = EpiModelHIV::make_calibration_trackers()
)


est <- readRDS(path_to_est)
nnodes <- est[[1]]$newnetwork$attr |> nrow()
no_hiv_init <- dplyr::tibble(
  status = rep(0, nnodes),
  diag.status = 0,
  inf.time = NA,
  stage = NA,
  stage.time = NA,
  aids.time = NA,
  diag.stage = NA,
  vl = NA,
  vl.last.usupp = NA,
  vl.last.supp = NA,
  diag.time = NA,
  last.neg.test = NA,
  tx.status = NA,
  cuml.time.on.tx = NA,
  cuml.time.off.tx = NA,
  tx.init.time = NA,
  part.tx.init.time = NA,
  part.tx.reinit.time = NA
)


init <- init_msm(
  init_attr = no_hiv_init,
  prev.ugc = 0,
  prev.rgc = 0,
  prev.uct = 0,
  prev.rct = 0,
  prev.syph = 0.1
)

# Here 2 scenarios will be used "scenario_1" and "scenario_2".
# This will generate 6 files (3 per scenarios)
EpiModelHPC::netsim_scenarios(
  path_to_est, param, init, control,
  scenarios_list = NULL,
  n_rep = 1,
  n_cores = 1,
  output_dir = scenarios_dir,
  save_pattern = "all"
)
fs::dir_ls(scenarios_dir)

# merge the simulations. Keeping one `tibble` per scenario
EpiModelHPC::merge_netsim_scenarios_tibble(
  sim_dir = scenarios_dir,
  output_dir = fs::path(scenarios_dir, "merged_tibbles"),
  steps_to_keep = year_steps * 1
)

d_sim <- readRDS(fs::path(scenarios_dir, "merged_tibbles", "df__empty_scenario.rds"))

d_sim |>
  tail(15) |>
  select(starts_with(c("syph", "gc", "ct", "ir100"))) |>
  glimpse()


control.icm(nsteps =  10)
control.dcm(nsteps =  10)



