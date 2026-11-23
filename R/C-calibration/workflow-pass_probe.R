## HPC Workflow: Pass Probe
##
## Before a later calibration pass, run the model at the values the pass will
## start from, long enough to settle, and make the pass's restart pool from
## the end states. It answers two questions before any wave runs: where each
## target lands under the current model at those values (which sets the
## pass's windows and resets in `calib_pass_settings.R`), and whether the
## model is at rest there (`calib_drift.csv`).
##
## Why a probe, not the previous pool. A first pass's confirmation need not be
## at rest where the fit moved the HIV parameters far from the pool's (in a
## four-city calibration, one city's diagnosis rates were still rising at year
## 70, on time constants of 35 to 95 years), and the model may have changed
## since. A longer first stage at the old values would not help: it settles
## the pool at an equilibrium the fit then leaves. So the probe starts warm,
## from the end states of the previous pass's confirmation runs
## ("confirmation") or from its restart pool ("pool"), at the pass's start
## values (`pass_start_values()`).
##
## Steps: (1) the clone's `git pull` and library restore; (2) for a
## "confirmation" source, the source pool from the previous confirmation's
## simulation files; (3) `n_rep` runs of `probe_years` from it; (4) merge; (5)
## `process_calibs.R` on the probe; (6) the pass's restart pool
## (`path_to_restart_pool`) from the probe's end states.
##
## Before deploying, add the pass's entry to `calib_pass_settings.R`, and check
## on the HPC that the previous pass's `calib_dir` holds its confirmation's
## `sim__default__*.rds`, and that neither the source pool nor the pass's pool
## exists: `make_restart_pool.R` stops if its pool is there.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Settings ---------------------------------------------------------------------
library(slurmworkflow)
library(EpiModelHPC)
library(EpiModelHIV)
library(dplyr)

hpc_context <- TRUE
if (!exists("calib_pass")) stop("Set `calib_pass` (2 or more) before sourcing.")
if (calib_pass < 2) stop("The probe is for a later pass; `calib_pass` is 1.")
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)
max_cores <- 8
n_rep <- 64

source("R/netsim_settings.R", local = TRUE)
source("R/C-calibration/calib_pass_settings.R", local = TRUE)
settings <- pass_settings(calib_pass)
start <- pass_start_values(calib_pass, retired_params)

# The targets the calibration fits, for the `fitted` column of the probe's
# `calib_tolerance.csv`, from the pass's own configuration, built apart so
# that none of its objects replace this script's
calib_config <- new.env()
source("R/C-calibration/swfcalib_config.R", local = calib_config)
fitted_targets <- calib_config$fitted_targets

probe_dir <- paste0(run_dir, "probe", calib_pass_suffix(calib_pass), "/")
prev_calib_dir <- paste0(run_dir, "calibration",
                         calib_pass_suffix(calib_pass - 1), "/")
source_pool <- if (settings$probe_source == "confirmation") {
  fs::path(est_dir, paste0("restart_pool-", context,
                           calib_pass_suffix(calib_pass), "-source"))
} else {
  fs::path(est_dir, paste0("restart_pool-", context,
                           calib_pass_suffix(calib_pass - 1)))
}

# One scenario, the pass's start values. Every other parameter is `param`'s,
# which includes the fixed values in `data/input/model_parameters.csv`.
scenarios_list <- EpiModel::create_scenario_list(
  dplyr::as_tibble(c(list(.scenario.id = "probe", .at = 1L), as.list(start)))
)

# `save.run` stays at its default (TRUE): the pass's restart pool is made from
# the end states of these runs.
control <- control_msm(
  set.control.tergm = control_tergm_sim(),
  nsteps = restart_time - 1 + settings$probe_years * year_steps,
  start = restart_time,
  initialize.FUN = reinit_msm,
  verbose = FALSE
)

# Workflow creation ------------------------------------------------------------
wf_probe <- paste0("probe", calib_pass_suffix(calib_pass))
wf <- make_em_workflow(wf_probe, override = TRUE)

pool_step <- function(wf, sims_dir, scenario_name, pool_dir, mail = "FAIL") {
  add_workflow_step(
    wf_summary = wf,
    step_tmpl = step_tmpl_do_call_script(
      r_script = "R/C-calibration/make_restart_pool.R",
      args = list(
        scenario_name = scenario_name,
        sims_dir = sims_dir,
        pool_dir = pool_dir,
        max_n = 500,
        # Adrien's rule: keep every simulation whose STI rates are at least
        # half their targets. Extinction is absorbing, and an STI can die out
        # in a large share of confirmation runs (48 percent for syphilis in one
        # city of a four-city calibration), so the filter matters here.
        min_sti_frac = 0.5,
        calib_pass = calib_pass
      ),
      setup_lines = hpc_node_setup
    ),
    sbatch_opts = list(
      "cpus-per-task" = 1,
      "time" = "01:00:00",
      "mem" = "32G",
      "mail-type" = mail
    )
  )
}

if (settings$probe_source == "confirmation") {
  wf <- pool_step(wf, prev_calib_dir, "default", source_pool)
}

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    source_pool, param, init, control,
    scenarios_list = scenarios_list,
    output_dir = probe_dir,
    n_rep = n_rep,
    n_cores = max_cores,
    max_array_size = 1000,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT",
    "cpus-per-task" = max_cores,
    "time" = netsim_time,
    "mem-per-cpu" = netsim_mem_per_cpu
  )
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_merge_netsim_scenarios_tibble(
    sim_dir = probe_dir,
    output_dir = fs::path(probe_dir, "merged_tibbles"),
    steps_to_keep = Inf,
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
    args = list(hpc_context = TRUE, n_cores = max_cores,
                calib_pass = calib_pass, out_dir = probe_dir,
                cluster_pool = source_pool, fitted_targets = fitted_targets),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "cpus-per-task" = max_cores,
    "time" = "02:00:00",
    "mem-per-cpu" = "5G",
    "mail-type" = "FAIL"
  )
)

# The END email means the probe's `calib_tolerance.csv`, `calib_sti_checks.csv`
# and `calib_drift.csv` are in `probe_dir` and the pass's pool is made.
wf <- pool_step(wf, probe_dir, "probe", path_to_restart_pool, mail = "END,FAIL")
