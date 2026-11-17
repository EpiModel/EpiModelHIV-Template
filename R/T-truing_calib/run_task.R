## One array task of a `truing` batch: runs `truing_runs_per_task` simulations
##
## Called from the project root by the batch's array job script:
##   Rscript R/T-truing_calib/run_task.R <batch_dir> <task>
## or sourced with `batch_dir` and `task` defined (local test).
## Each run: its parameters (a one-row scenario), its seed, a cold start from
## the network estimate (`.pool` NA) or a restart from its pool element, 70
## years; the outputs are the means over the last `truing_score_years` (5;
## less noise per run than the last year, as Template PR #82). Runs
## with `.keep` also save their restart point in `<batch_dir>/states/`.
## Writes `<batch_dir>/out_<task>.rds` (`.run` + outputs); a run the model
## fails on is a row with its `.error` message (failures are data: the engine
## does not rerun it).

if (!exists("batch_dir")) {
  args <- commandArgs(trailingOnly = TRUE)
  batch_dir <- args[1]
  task <- as.integer(args[2])
}

suppressMessages({
  library(EpiModelHIV)
  library(dplyr)
})
hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/T-truing_calib/z-context.R", local = TRUE)
source("R/netsim_settings.R", local = TRUE)

prop <- readRDS(fs::path(batch_dir, "proposals.rds"))
rows <- which((seq_len(nrow(prop)) - 1) %/% truing_runs_per_task + 1 == task)
pn <- setdiff(names(prop), grep("^\\.", names(prop), value = TRUE))
targets <- EpiModelHIV::get_calibration_targets()
out_cols <- c("num", names(targets))
nsteps_run <- if (truing_tiny) year_steps else calibration_end

# attributes holding time steps, reset by `make_restart_point`
# (as R/Z-calibration/make_restart_pool.R)
attrs_names <- names(EpiModelHIV::get_default_attrs())
time_attrs <- grep("\\.last$|\\.time$", attrs_names, value = TRUE)

pools_dir <- fs::path(truing_calib_dir, "pools")
fs::dir_create(fs::path(batch_dir, "states"))

run_one <- function(i) {
  r <- prop[i, ]
  set.seed(r$.seed)
  sc <- EpiModel::create_scenario_list(
    dplyr::bind_cols(
      tibble::tibble(.scenario.id = "run", .at = 1),
      tibble::as_tibble(r[pn])
    )
  )[[1]]
  param_r <- EpiModel::use_scenario(param, sc)
  if (is.na(r$.pool)) {
    orig <- readRDS(path_to_est)
    control <- control_msm(
      nsteps = nsteps_run,
      initialize.FUN = initialize_msm_ergmkit,
      resim_nets.FUN = resim_nets_ergmkit,
      ergmkit.control = ergmkit_control,
      verbose = FALSE
    )
  } else {
    orig <- readRDS(fs::path(pools_dir, r$.pool, paste0(r$.start, ".rds")))
    control <- control_msm(
      nsteps = restart_time - 1 + nsteps_run,
      start = restart_time,
      initialize.FUN = initialize_msm_ergmkit,
      resim_nets.FUN = resim_nets_ergmkit,
      ergmkit.control = ergmkit_control,
      verbose = FALSE
    )
  }
  sim <- netsim(orig, param_r, init, control)
  out <- as_tibble(sim) |>
    mutate_calibration_targets(year_steps = year_steps) |>
    filter(time > max(time) - truing_score_years * year_steps) |>
    summarise(across(any_of(out_cols), \(x) mean(x, na.rm = TRUE)))
  if (isTRUE(r$.keep)) {
    rp <- EpiModel::make_restart_point(sim, time_attrs = time_attrs, sim_num = 1)
    saveRDS(rp, fs::path(batch_dir, "states", paste0(r$.run, ".rds")))
  }
  data.frame(.run = r$.run, out, check.names = FALSE)
}

## a failed run: its error message, prefixed by netsim's "An error occurred in
## module ..." line when there is one
run_safe <- function(i) {
  where <- ""
  tryCatch(
    withCallingHandlers(run_one(i), message = function(m) {
      if (grepl("error occurred in module", conditionMessage(m))) {
        where <<- trimws(conditionMessage(m))
      }
    }),
    error = function(e) {
      msg <- paste0(if (nzchar(where)) paste0(where, ": ") else "", conditionMessage(e))
      message("run ", prop$.run[i], " failed: ", msg)
      data.frame(.run = prop$.run[i], .error = msg)
    })
}

res <- if (length(rows) == 0) list() else parallel::mclapply(
  rows, run_safe,
  mc.cores = max(1, min(length(rows), truing_runs_per_task)), mc.preschedule = FALSE
)
res <- dplyr::bind_rows(res[vapply(res, is.data.frame, TRUE)])
if (NROW(res) > 0) {
  saveRDS(res, fs::path(batch_dir, sprintf("out_%04d.rds", task)))
}
n_err <- if (is.null(res$.error)) 0 else sum(!is.na(res$.error))
message(NROW(res) - n_err, " / ", length(rows), " runs done, ", n_err, " failed")
