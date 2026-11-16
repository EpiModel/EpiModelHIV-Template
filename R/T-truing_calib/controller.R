## The `truing` controller step on the HPC
##
## One call: gather the pending batch, decide the next one (the engine's
## `truing_step()`), build the restart pool it needs, then submit it as one
## Slurm array (every run of the batch at once) and the next controller job
## with `--dependency=afterany:<array>` (it waits for every task). It stops
## when the calibration is done or a rule declares an error.
##
## Run from the project root, by the first workflow step
## (`workflow-calib.R`), then by the job scripts it writes:
##   Rscript R/T-truing_calib/controller.R
## Locally with `TRUING_LOCAL_TEST=1` it runs the batches itself (no Slurm).

suppressMessages(library(dplyr))
hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/T-truing_calib/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE) # `hpc_node_setup`

for (f in list.files(fs::path(truing_engine_dir, "R"), "\\.R$", full.names = TRUE)) {
  source(f, local = TRUE)
}

tc_dir <- truing_calib_dir
fs::dir_create(fs::path(tc_dir, "jobs"))
fs::dir_create(fs::path(tc_dir, "logs"))
fs::dir_create(fs::path(tc_dir, "pools"))

# A new calibration: build the config, keep a copy of the script that made it
if (!fs::file_exists(fs::path(tc_dir, "state.rds"))) {
  suppressMessages(library(EpiModelHIV))
  source("R/netsim_settings.R", local = TRUE)
  source("R/T-truing_calib/config.R", local = TRUE)
  truing_init(tc_dir, truing_cfg)
  fs::file_copy("R/T-truing_calib/config.R", fs::path(tc_dir, "config_script.R"),
                overwrite = TRUE)
} else if (!identical(
  unname(tools::md5sum("R/T-truing_calib/config.R")),
  unname(tools::md5sum(fs::path(tc_dir, "config_script.R")))
)) {
  warning("R/T-truing_calib/config.R changed since this calibration started: ",
          "the stored config (", fs::path(tc_dir, "config.rds"), ") is used")
}

## a restart pool from kept states: `<pools>/<id>/<k>.rds` + `pool_index.csv`
## (the EpiModelHPC layout, so `validate_restart_pool()` accepts it)
build_pool <- function(pb) {
  pdir <- fs::path(tc_dir, "pools", pb$id)
  if (fs::dir_exists(pdir)) fs::dir_delete(pdir)
  tmp <- fs::path(tc_dir, "pools", paste0(".", pb$id, ".partial"))
  if (fs::dir_exists(tmp)) fs::dir_delete(tmp)
  fs::dir_create(tmp)
  src <- vapply(pb$runs, function(r) {
    f <- fs::path(tc_dir, "batches", pb$batches, "states", paste0(r, ".rds"))
    f <- f[fs::file_exists(f)]
    if (!length(f)) stop("No kept state for run ", r)
    as.character(f[1])
  }, "")
  ver <- character(length(src))
  for (k in seq_along(src)) {
    ver[k] <- as.character(attr(readRDS(src[k]), "version") %||% NA)
    fs::file_copy(src[k], fs::path(tmp, paste0(k, ".rds")))
  }
  utils::write.csv(data.frame(pool_num = seq_along(src), run = pb$runs,
                              file_path = src, epimodel_version = ver),
                   fs::path(tmp, "pool_index.csv"), row.names = FALSE)
  fs::file_move(tmp, pdir)
  # the kept states of those batches are no longer needed
  for (b in pb$batches) {
    sd <- fs::path(tc_dir, "batches", b, "states")
    if (fs::dir_exists(sd)) fs::dir_delete(sd)
  }
}

# the TRUING_* settings of this calibration, written into every job script
# (whatever Slurm's `--export` default)
truing_env <- local({
  e <- Sys.getenv()
  e <- e[grepl("^TRUING_", names(e))]
  if (length(e)) paste0("export ", names(e), "=", shQuote(e)) else character(0)
})

write_job <- function(path, name, sbatch, body) {
  lines <- c(
    "#!/bin/bash",
    paste0("#SBATCH --job-name=", name),
    paste0("#SBATCH --partition=", truing_partition),
    paste0("#SBATCH --", names(sbatch), "=", unlist(sbatch)),
    paste0("cd ", normalizePath(".")),
    hpc_node_setup,
    truing_env,
    body
  )
  writeLines(lines, path)
  fs::file_chmod(path, "u+x")
  path
}
sbatch <- function(args) {
  out <- system2("sbatch", c("--parsable", args), stdout = TRUE, stderr = TRUE)
  id <- sub(";.*$", "", out[length(out)])
  if (!grepl("^[0-9]+$", id)) stop("sbatch failed: ", paste(out, collapse = "\n"))
  id
}

repeat {
  act <- truing_step(tc_dir)
  if (act$type != "batch") {
    message("Calibration ", act$type, ": ", act$msg)
    break
  }
  if (!is.null(act$pool_build)) build_pool(act$pool_build)
  n_task <- ceiling(nrow(act$proposals) / truing_runs_per_task)
  message(act$batch_id, ": ", nrow(act$proposals), " runs in ", n_task, " tasks")

  if (truing_local_test) {
    batch_dir <- act$batch_dir
    for (task in seq_len(n_task)) source("R/T-truing_calib/run_task.R", local = TRUE)
    next
  }

  tag <- paste0(truing_job_prefix, "truing_", truing_calib_name)
  arr <- write_job(
    fs::path(tc_dir, "jobs", paste0(act$batch_id, "_sims.sh")),
    paste0(tag, "_", act$batch_id),
    list("array" = paste0("1-", n_task),
         "cpus-per-task" = truing_runs_per_task,
         "mem-per-cpu" = "5G", "time" = "06:00:00",
         "output" = fs::path(normalizePath(tc_dir), "logs",
                             paste0(act$batch_id, "_%a.out"))),
    paste("Rscript R/T-truing_calib/run_task.R",
          normalizePath(act$batch_dir), "$SLURM_ARRAY_TASK_ID")
  )
  ctl <- write_job(
    fs::path(tc_dir, "jobs", paste0(act$batch_id, "_controller.sh")),
    paste0(tag, "_ctl"),
    list("cpus-per-task" = 2, "mem" = "16G", "time" = "04:00:00",
         "output" = fs::path(normalizePath(tc_dir), "logs",
                             paste0(act$batch_id, "_controller.out"))),
    "Rscript R/T-truing_calib/controller.R"
  )
  arr_id <- sbatch(arr)
  ctl_id <- sbatch(c(paste0("--dependency=afterany:", arr_id), ctl))
  log_line(tc_dir, "submitted ", act$batch_id, ": array ", arr_id, " (",
           n_task, " tasks), next controller ", ctl_id)
  break
}
