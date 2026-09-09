## HPC Workflow: Restart Calibration - LHS design (Phase 3 - manual)
##
## Test parameter adjustments starting from the restart point. More stable than
## ballpark calibration since the population is simulation-born rather than
## completely synthetic. When better parameters are found, re-create the restart
## point before moving to swfcalib.
##
## This is a copy of `workflow-restart_calib.R` that replaces the single
## hand-picked scenario with a 256-point Latin Hypercube Sample covering the
## full prior ranges explored in `C-calibration/swfcalib_config.R`.
##
## NOTE: scenario outputs are written to the same `calib_dir` as
## `workflow-restart_calib.R` (matching this project's manual-calibration
## convention). Back up or clear `data/run/calibration/` first if you don't
## want to mix this LHS sweep with a previous manual run.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Settings ---------------------------------------------------------------------
library(slurmworkflow)
library(EpiModelHPC)
library(EpiModelHIV)
library(dplyr)
library(tibble)
library(lhs)

hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

max_cores <- 4

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

# Control settings
control <- control_msm(
  nsteps = calibration_end,
  start = restart_time,
  initialize.FUN = reinit_msm,
  verbose = FALSE
)

# Workflow creation ------------------------------------------------------------
wf <- make_em_workflow("restart_calib_lhs", override = TRUE)

# Using scenarios --------------------------------------------------------------

# Define calibration scenarios: 256-point Latin Hypercube Sample covering the
# full prior ranges from `C-calibration/swfcalib_config.R` wave priors.
n_scenarios <- 64

# param -> c(min, max), taken from swfcalib_config.R's `priors` ranges
param_ranges <- list(
  # prep.start.rate_1 = c(0.00333, 0.05191),
  # prep.start.rate_2 = c(0.00333, 0.05191),
  # prep.start.rate_3 = c(0.00333, 0.05191),
  # hiv.test.rate_1 = c(0.000444, 0.001332),
  # hiv.test.rate_2 = c(0.000444, 0.001332),
  # hiv.test.rate_3 = c(0.000444, 0.001332),
  # tx.halt.rate_1 = c(0.000888, 0.002664),
  # tx.halt.rate_2 = c(0.000888, 0.002664),
  # tx.halt.rate_3 = c(0.000888, 0.002664),
  #
  # gono.uret.prob = c(0.17, 0.23),
  # chla.uret.prob = c(0.17, 0.23),
  # syph.prob = c(0.10, 0.13),
  # aids.off.tx.mort.rate = c(0.000333, 0.000888),
  # a.rate = c(0.0002, 0.0006)
  #
  hiv.trans.scale_1 = c(1.5, 5),
  hiv.trans.scale_2 = c(0.2, 0.9),
  hiv.trans.scale_3 = c(0.2, 0.9)
)

# set.seed(12345)
lhs_unit <- lhs::maximinLHS(n_scenarios, length(param_ranges))
colnames(lhs_unit) <- names(param_ranges)

scenarios_df <- as_tibble(lhs_unit) |>
  mutate(across(everything(), \(x) {
    rng <- param_ranges[[cur_column()]]
    rng[1] + x * (rng[2] - rng[1])
  })) |>
  mutate(
    .scenario.id = as.character(seq_len(n_scenarios)),
    .at = 1,
    .before = 1
  )
saveRDS(scenarios_df, "./data/run/lhs_scs2.rds")

scenarios_list <- EpiModel::create_scenario_list(scenarios_df)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_restart,
    param,
    init,
    control,
    # scenarios_list = NULL,
    scenarios_list = scenarios_list,
    output_dir = calib_dir,
    n_rep = 4,
    n_cores = max_cores,
    max_array_size = 500,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT",
    "cpus-per-task" = max_cores,
    "time" = "04:00:00",
    "mem-per-cpu" = "5G"
  )
)

# Process calibrations
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_merge_netsim_scenarios_tibble(
    sim_dir = calib_dir,
    output_dir = fs::path(calib_dir, "merged_tibbles"),
    steps_to_keep = Inf, # keep everything
    cols = dplyr::everything(),
    n_cores = max_cores,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "cpus-per-task" = max_cores,
    "time" = "02:00:00",
    "mem-per-cpu" = "5G"
  )
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/C-calibration/process_calibs.R",
    args = list(hpc_context = TRUE, n_cores = max_cores),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "END",
    "cpus-per-task" = max_cores,
    "time" = "02:00:00",
    "mem-per-cpu" = "5G"
  )
)
