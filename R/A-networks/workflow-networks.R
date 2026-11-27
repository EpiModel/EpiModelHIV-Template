## HPC Workflow: Networks
##
## Define a workflow to run the estimation, the diagnostics and the check of the
## network models on the HPC

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(slurmworkflow)

hpc_context <- TRUE
source("R/shared_variables.R", local = TRUE)
source("R/A-networks/z-context.R", local = TRUE)
source("R/hpc_configs.R", local = TRUE)

# Process ----------------------------------------------------------------------
wf <- make_em_workflow("networks", override = TRUE)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/A-networks/1-estimation.R",
    args = list(hpc_context = TRUE),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "cpus-per-task" = est_cores,
    "time" = "24:00:00",
    "mem" = "0"
  )
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/A-networks/2-diagnostics.R",
    args = list(hpc_context = TRUE),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL",
    "cpus-per-task" = est_cores,
    "time" = "24:00:00",
    "mem" = "0"
  )
)

# The network check: every target statistic of the fits against what the
# diagnostics simulated. The job fails if anything is outside tolerance, so
# the END mail means the fits passed and a FAIL mail means they did not.
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/A-networks/3-check.R",
    args = list(hpc_context = TRUE),
    setup_lines = hpc_node_setup
  ),
  sbatch_opts = list(
    "mail-type" = "END,FAIL",
    "cpus-per-task" = 1,
    "time" = "00:30:00",
    "mem" = "16G"
  )
)
