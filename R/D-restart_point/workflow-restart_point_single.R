##
## Epidemic Model Parameter Calibration, HPC setup
##

# Settings ---------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
source("./R/hpc_configs.R")

# Necessary files --------------------------------------------------------------

library("slurmworkflow")

wf <- make_em_workflow("restart_point_single", override = TRUE)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "./R/D-restart_point/1-restart_point_single.R",
    args = list(hpc_context = TRUE),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "04:00:00",
    "mem-per-cpu" = "5G"
  )
)
