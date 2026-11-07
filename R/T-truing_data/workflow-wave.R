## Workflow: one iteration of one wave of a `truing` data campaign
##
## Builds the proposals (two crossed designs side by side), runs them with the
## EpiModelHPC scenario API, merges the batches, and gathers the results into
## `<truing_dir>/results/w<k>_i<j>.rds` + `<truing_dir>/full_results.rds`
## (swfcalib `full_results` layout), deleting the intermediates.
##
## Before the first workflow, upload `data/run/estimates/*-local.rds` to the HPC
## clone. Between waves, write the values to carry forward in
## `<truing_dir>/carry.csv` (`param,value`).

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Settings ---------------------------------------------------------------------
library(slurmworkflow)
library(EpiModelHPC)
library(EpiModelHIV)
library(dplyr)

source("R/shared_variables.R", local = TRUE)
source("R/T-truing_data/z-context.R", local = TRUE)
source("R/T-truing_data/design.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

wave      <- as.integer(Sys.getenv("TRUING_WAVE", "1"))
iteration <- as.integer(Sys.getenv("TRUING_ITER", "1"))

# `TRUING_LOCAL_TEST=1`: tiny designs, 1 year, run here (no workflow) into
# `data/run/truing/TEST`, to check the whole chain before sending it
local_test <- nzchar(Sys.getenv("TRUING_LOCAL_TEST"))

# Two designs per iteration, compared afterwards by subsampling:
# `n_cores` cores per array task; `truing_max_cores` at once in total
designs_root <- tibble::tribble(
  ~design, ~n_points, ~n_rep, ~n_cores,
  "grid",  128,       8,      8,
  "lhs",   1024,      1,      1
)

# Carry variants (from wave 2, first iteration): how a wrong result of the
# previous wave propagates. The previous wave's parameters are run at their
# carried root ("root", `designs_root`) and scaled jointly by each factor
# (`designs_variant`, smaller); the earlier waves stay at their roots.
carry_factors <- c(0.1, 0.25, 0.5, 0.8, 1.25, 2, 4, 10)
designs_variant <- tibble::tribble(
  ~design, ~n_points, ~n_rep, ~n_cores,
  "grid",  64,        4,      4,
  "lhs",   256,       1,      1
)

if (local_test) {
  designs_root <- tibble::tribble(~design, ~n_points, ~n_rep, ~n_cores,
                                  "grid", 2, 2, 2, "lhs", 2, 1, 1)
  designs_variant <- tibble::tribble(~design, ~n_points, ~n_rep, ~n_cores,
                                     "grid", 1, 2, 2, "lhs", 1, 1, 1)
  carry_factors <- c(0.1, 10)
  truing_dir <- fs::path(run_dir, "truing", "TEST")
  truing_sim_dir <- fs::path(calib_dir, "truing_sims_TEST")
  truing_df_dir <- fs::path(calib_dir, "truing_df_TEST")
}

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

control <- control_msm(
  nsteps = if (local_test) year_steps else calibration_end,
  initialize.FUN = initialize_msm_ergmkit,
  resim_nets.FUN = resim_nets_ergmkit,
  ergmkit.control = ergmkit_control,
  verbose = FALSE
)

carry_file <- fs::path(truing_dir, "carry.csv")
current <- truing_current_values(params_df, carry_file)

prev_params <- if (wave > 1) truing_waves[[wave - 1]]$params else character()
if (wave > 1) {
  carried <- if (fs::file_exists(carry_file)) {
    utils::read.csv(carry_file)$param
  } else {
    character()
  }
  if (!all(prev_params %in% carried)) {
    stop("Wave ", wave, " needs the roots of wave ", wave - 1, " in `",
         carry_file, "`: ", paste0(setdiff(prev_params, carried),
                                   collapse = ", "))
  }
}

variants <- tibble::tibble(carry = "root", carry_factor = 1)
if (wave > 1 && iteration == 1) {
  variants <- bind_rows(variants, tibble::tibble(
    carry = paste0("x", carry_factors),
    carry_factor = carry_factors
  ))
}
variants$variant_index <- seq_len(nrow(variants))

# One row per (variant, design). The seeds of the root variant do not depend
# on the variants (task index < 1e4 per design)
designs <- variants |>
  rowwise() |>
  mutate(d = list(
    if (carry == "root") designs_root else designs_variant
  )) |>
  tidyr::unnest(d) |>
  group_by(carry) |>
  mutate(design_index = row_number()) |>
  ungroup() |>
  mutate(
    seed_base = truing_seed + 1e7 * (variant_index - 1) +
      1e6 * design_index + 1e4 * (10 * wave + iteration)
  )

design_tbl <- designs |>
  rowwise() |>
  mutate(tbl = list(make_truing_design(
    wave, iteration, design, n_points, n_rep,
    current = truing_scale_carry(current, prev_params, carry_factor),
    seed = seed_base, carry = carry, carry_factor = carry_factor
  ))) |>
  pull(tbl) |>
  bind_rows()

# Keep a local copy of what is sent
fs::dir_create(fs::path(truing_dir, "designs"))
utils::write.csv(
  design_tbl,
  fs::path(truing_dir, "designs", sprintf("w%d_i%d.csv", wave, iteration)),
  row.names = FALSE
)

if (local_test) {
  for (i in seq_len(nrow(designs))) {
    d <- designs[i, ]
    EpiModelHPC::netsim_scenarios(
      path_to_est, param, init, control,
      scenarios_list = truing_design_to_scenarios(
        filter(design_tbl, .carry == d$carry, .design == d$design)
      ),
      n_rep = d$n_rep, n_cores = d$n_cores, output_dir = truing_sim_dir,
      libraries = "EpiModelHIV"
    )
  }
  EpiModelHPC::merge_netsim_scenarios_tibble(
    truing_sim_dir, truing_df_dir, steps_to_keep = year_steps
  )
  with(
    list(design = design_tbl,
         step_info = select(designs, "carry", "design", "n_cores",
                            "seed_base"),
         truing_params = truing_params, df_dir = truing_df_dir,
         sim_dir = truing_sim_dir, truing_dir = truing_dir,
         year_steps = year_steps),
    source("R/T-truing_data/gather.R", local = TRUE)
  )
  message("Local test done: ", fs::path(truing_dir, "full_results.rds"))
} else {

# Workflow creation ------------------------------------------------------------
wf_name <- paste0(
  Sys.getenv("HPC_WF_PREFIX"),
  sprintf("truing_%s_w%d_i%d", truing_campaign, wave, iteration)
)
wf <- make_em_workflow(wf_name, override = TRUE)
n_steps <- 1 # the renv restore

# slurmworkflow chains an array to the next step through the job ID of its
# *last task* only (`afterany:$SLURM_JOB_ID`): the next step can start while
# other tasks still run. Hence: one array per design, throttled to
# `truing_max_cores` (`%k`, set on the job script below), and a step after it
# that waits for every batch file, or for the array to leave the queue.
truing_wait_for_sims <- function(sim_dir, pattern, expected, job_name,
                                 poll_s = 60, timeout_h = 24) {
  t0 <- Sys.time()
  repeat {
    n <- if (fs::dir_exists(sim_dir)) {
      length(fs::dir_ls(sim_dir, regexp = pattern))
    } else {
      0
    }
    queued <- system2(
      "squeue", c("-h", "-u", Sys.getenv("USER"), "-n", job_name),
      stdout = TRUE
    )
    message(format(Sys.time()), ": ", n, " / ", expected, " batch files, ",
            length(queued), " tasks still queued")
    if (n >= expected) break
    if (length(queued) == 0) {
      warning(expected - n, " batch files missing and no task left: ",
              "check the array logs")
      break
    }
    if (difftime(Sys.time(), t0, units = "hours") > timeout_h) {
      warning("Timeout after ", timeout_h, " h with ", n, " / ", expected)
      break
    }
    Sys.sleep(poll_s)
  }
}

# RSPH caps job arrays at 1001 tasks (`MaxArraySize`): a design runs as chunks
# of at most `truing_max_array` tasks, one array each. The seed stays keyed on
# the task's index in the whole design: chunk starting after `offset` tasks
# exports `TRUING_SEED = seed_base + offset`.
truing_max_array <- 512
throttle <- c()
for (i in seq_len(nrow(designs))) {
  d <- designs[i, ]
  n_batch <- ceiling(d$n_rep / d$n_cores)
  per_chunk <- max(1, truing_max_array %/% n_batch)
  chunks <- split(seq_len(d$n_points),
                  ceiling(seq_len(d$n_points) / per_chunk))
  for (pts in chunks) {
    wf <- add_workflow_step(
      wf_summary = wf,
      step_tmpl = step_tmpl_netsim_scenarios(
        path_to_est, param, init, control,
        scenarios_list = truing_design_to_scenarios(
          filter(design_tbl, .carry == d$carry, .design == d$design,
                 .point %in% pts)
        ),
        n_rep = d$n_rep,
        n_cores = d$n_cores,
        output_dir = truing_sim_dir,
        libraries = "EpiModelHIV",
        setup_lines = c(
          hpc_node_setup,
          paste0("export TRUING_SEED=", d$seed_base + (min(pts) - 1) * n_batch)
        ),
        max_array_size = Inf
      ),
      sbatch_opts = list(
        "mail-type" = "FAIL,TIME_LIMIT",
        "cpus-per-task" = d$n_cores,
        "time" = "04:00:00",
        "mem-per-cpu" = "5G"
      )
    )
    n_steps <- n_steps + 1
    throttle[as.character(n_steps)] <- truing_max_cores %/% d$n_cores

    wf <- add_workflow_step(
      wf_summary = wf,
      step_tmpl = step_tmpl_do_call(
        what = truing_wait_for_sims,
        args = list(
          sim_dir = truing_sim_dir,
          pattern = sprintf("/sim__w%d_i%d_%s%s_p[0-9]+__[0-9]+\\.rds$",
                            wave, iteration,
                            gsub(".", "\\.", truing_carry_tag(d$carry),
                                 fixed = TRUE),
                            d$design),
          # every batch of this design up to the end of the chunk
          expected = max(pts) * n_batch,
          job_name = paste0(wf_name, "_step", n_steps)
        ),
        setup_lines = hpc_node_setup
      ),
      sbatch_opts = list(
        "cpus-per-task" = 1,
        "time" = "1-00:00:00",
        "mem" = "2G"
      )
    )
    n_steps <- n_steps + 1
  }
}

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_merge_netsim_scenarios_tibble(
    sim_dir = truing_sim_dir,
    output_dir = truing_df_dir,
    steps_to_keep = year_steps,
    n_cores = 8,
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "cpus-per-task" = 8,
    "time" = "02:00:00",
    "mem-per-cpu" = "4G"
  )
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/T-truing_data/gather.R",
    args = list(
      design = design_tbl,
      step_info = select(designs, "carry", "design", "n_cores", "seed_base"),
      truing_params = truing_params,
      df_dir = truing_df_dir,
      sim_dir = truing_sim_dir,
      truing_dir = truing_dir,
      year_steps = year_steps
    ),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "END,FAIL",
    "cpus-per-task" = 1,
    "time" = "01:00:00",
    "mem" = "16G"
  )
)

# Throttle the simulation arrays (the step templates set `--array=0-<n>`)
for (s in names(throttle)) {
  job <- fs::path("workflows", wf_name, "SWF", "steps", s, "job.sh")
  lines <- readLines(job)
  arr <- grepl("^#SBATCH --array=[0-9]+-[0-9]+$", lines)
  if (sum(arr) != 1) stop("No `--array` line to throttle in ", job)
  lines[arr] <- paste0(lines[arr], "%", throttle[[s]])
  writeLines(lines, job)
}

# Agents (`HPC_WF_PREFIX` set) send no mail
if (nzchar(Sys.getenv("HPC_WF_PREFIX"))) {
  for (job in fs::dir_ls(fs::path("workflows", wf_name, "SWF", "steps"),
                         recurse = TRUE, regexp = "/job\\.sh$")) {
    lines <- readLines(job)
    writeLines(lines[!grepl("^#SBATCH --mail-", lines)], job)
  }
}

message(
  "\nWorkflow \"", wf_name, "\": ", sum(design_tbl$.n_rep), " simulations (",
  paste0(designs$carry, " ", designs$design, " ", designs$n_points, "x",
         designs$n_rep, collapse = ", "),
  ").\nSend `workflows/", wf_name, "` to the HPC and run its ",
  "`start_workflow.sh` from the project root."
)

} # not a local test
