## Workflow: start a `truing` calibration on the HPC
##
## Two steps: the renv restore (`make_em_workflow()`), then the first
## controller (`controller.R`). From there the controller submits every batch
## itself (one Slurm array per batch, all its runs at once) and the next
## controller after it, until the calibration ends.
##
## Before starting: push this branch, sync the engine
## (`rsync -a calibration_work/truing/ <hpc project>/truing/`), upload
## `data/run/estimates/*-local.rds` to the HPC clone once.
## Then on the HPC, from the project root: `./workflows/<name>/start_workflow.sh`.
## Follow it in `data/run/truing_calib/<name>/status.txt` and `log.txt`.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(slurmworkflow)
library(EpiModelHPC)

source("R/shared_variables.R", local = TRUE)
source("R/T-truing_calib/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

wf_name <- paste0(Sys.getenv("HPC_WF_PREFIX"), "truing_calib_", truing_calib_name)
wf <- make_em_workflow(wf_name, override = TRUE)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_bash_lines(c(
    hpc_node_setup,
    "Rscript R/T-truing_calib/controller.R"
  )),
  sbatch_opts = list(
    "cpus-per-task" = 2,
    "time" = "04:00:00",
    "mem" = "16G"
  )
)

# Agents (`HPC_WF_PREFIX` set) send no mail
if (nzchar(Sys.getenv("HPC_WF_PREFIX"))) {
  for (job in fs::dir_ls(fs::path("workflows", wf_name, "SWF", "steps"),
                         recurse = TRUE, regexp = "/job\\.sh$")) {
    lines <- readLines(job)
    writeLines(lines[!grepl("^#SBATCH --mail-", lines)], job)
  }
}

message(
  "\nWorkflow \"", wf_name, "\" for the calibration in \"", truing_calib_dir,
  "\".\nSend `workflows/", wf_name, "` to the HPC and run its ",
  "`start_workflow.sh` from the project root."
)
