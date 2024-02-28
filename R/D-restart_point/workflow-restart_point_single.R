## HPC Workflow: Epidemic Restart Point
##
## Define a workflow to generate an uncalibrated restart point on the HPC to
## test the next part of the models before the calibration is finished

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Settings ---------------------------------------------------------------------
library(slurmworkflow)

hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/C-netsim_scenarios/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

# Process ----------------------------------------------------------------------
wf <- make_em_workflow("restart_point_single", override = TRUE)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/D-restart_point/1-restart_point_single.R",
    args = list(hpc_context = TRUE),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "04:00:00",
    "mem-per-cpu" = "5G"
  )
)
