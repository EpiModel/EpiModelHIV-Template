## HPC Workflow: scenarios for the variance assessment (cycle 5)
##
## Four scenarios branched from the 32-point restart pool
## (R/E-restart_assessment/SCENARIOS.md):
##
## - Short runs, 15 years (5-year lead-in + 10 years), change at
##   `intervention_start`: baseline, S1 HIV testing odds x 2, S2 PrEP
##   initiation odds x 2, S3 STI screening odds x 3.
## - Long runs, 150 years, change from the restart: S4 acts.scale = 0.9. The
##   baseline for S4 is the cycle 4 pool runs (same parameters, same points).
##
## Every batch has 32 runs on 32 cores, so recycling uses each pool point once
## per batch, in every scenario: 4 batches = 4 runs per point and scenario.
## Outputs go to their own directory, `data/run/variance_scenarios/`.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Settings ---------------------------------------------------------------------
library(slurmworkflow)
library(EpiModelHPC)
library(EpiModelHIV)
library(dplyr)

hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

max_cores <- 32
n_points  <- 32
n_rep     <- 4 * n_points
sc_dir    <- paste0(run_dir, "variance_scenarios/")
short_dir <- paste0(sc_dir, "short/")
long_dir  <- paste0(sc_dir, "long/")

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

# Recycling must see the whole pool in each batch
stopifnot(length(readRDS(path_to_restart)$run) == n_points)

# Shift a probability by an odds ratio (as in `make_scenarios.R`)
apply_or <- function(p, or) plogis(qlogis(p) + log(or))

# One scenario from a named list of full parameter vectors
one_scenario <- function(id, at, values) {
  flat <- unlist(lapply(names(values), function(nm) {
    v <- values[[nm]]
    if (length(v) == 1) setNames(v, nm) else setNames(v, paste0(nm, "_", seq_along(v)))
  }))
  df <- tibble(.scenario.id = id, .at = at, !!!as.list(flat))
  EpiModel::create_scenario_list(df)
}

# Short scenarios: change at `intervention_start`
short_scenarios <- c(
  # no-op updater, so that the baseline goes through the same code path
  one_scenario("baseline", intervention_start,
    list(hiv.test.rate = param$hiv.test.rate)),
  one_scenario("s1_test_or2", intervention_start,
    list(hiv.test.rate = apply_or(param$hiv.test.rate, 2))),
  one_scenario("s2_prep_or2", intervention_start,
    list(prep.start.rate = apply_or(param$prep.start.rate, 2))),
  one_scenario("s3_stiscreen_or3", intervention_start,
    list(
      sti.screen.hivneg.rate = apply_or(param$sti.screen.hivneg.rate, 3),
      sti.screen.hivpos.rate = apply_or(param$sti.screen.hivpos.rate, 3)
    ))
)

# Long scenario: `.at` < 2 is applied from the restart by `use_scenario()`
long_scenarios <- one_scenario("s4_acts090", 1, list(acts.scale = 0.9))

control_short <- control_msm(
  start          = restart_time,
  nsteps         = intervention_end,
  initialize.FUN = initialize.net,
  verbose        = FALSE
)

control_long <- control_msm(
  start          = restart_time,
  nsteps         = restart_time + 150 * year_steps,
  initialize.FUN = initialize.net,
  verbose        = FALSE
)

# Workflow creation ------------------------------------------------------------
wf <- make_em_workflow("variance_scenarios", override = TRUE)

# Step 2: short runs, 4 scenarios x 4 batches of 32
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_restart, param, init, control_short,
    scenarios_list = short_scenarios,
    output_dir = short_dir,
    n_rep = n_rep,
    n_cores = max_cores,
    max_array_size = 500,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT",
    "cpus-per-task" = max_cores,
    "time" = "03:00:00",
    "mem-per-cpu" = "5G"
  )
)

# Step 3: long runs, 1 scenario x 4 batches of 32
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_scenarios(
    path_to_restart, param, init, control_long,
    scenarios_list = long_scenarios,
    output_dir = long_dir,
    n_rep = n_rep,
    n_cores = max_cores,
    max_array_size = 500,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT",
    "cpus-per-task" = max_cores,
    "time" = "12:00:00",
    "mem-per-cpu" = "5G"
  )
)

# Steps 4-5: merge each set
for (d in c(short_dir, long_dir)) {
  wf <- add_workflow_step(
    wf_summary = wf,
    step_tmpl = step_tmpl_merge_netsim_scenarios_tibble(
      sim_dir = d,
      output_dir = fs::path(d, "merged_tibbles"),
      steps_to_keep = Inf,
      cols = dplyr::everything(),
      n_cores = 8,
      setup_lines = hpc_node_setup
    ),
    sbatch_opts = list(
      "mail-type" = "FAIL,TIME_LIMIT,END",
      "cpus-per-task" = 8,
      "time" = "02:00:00",
      "mem-per-cpu" = "8G"
    )
  )
}
