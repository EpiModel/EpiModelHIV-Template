library(slurmworkflow)
library(EpiModelHPC)

hpc_configs <- swf_configs_hyak(
  hpc = "mox",
  partition = "ckpt",
  r_version = "4.1.2",
  mail_user = "aleguil@emory.edu"
)

max_cores <- 28

wf <- create_workflow(
  wf_name = "test_swf_map",
  default_sbatch_opts = hpc_configs$default_sbatch_opts
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_renv_restore(
    git_branch = "auto_calib",
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = hpc_configs$renv_sbatch_opts
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_map(
    FUN = function(batch_num) {
      print(paste0("array_id = ", Sys.getenv("SLURM_ARRAY_TASK_ID")))
      print(paste0("array_offset = ", Sys.getenv("SWF__ARRAY_OFFSET")))
      print(paste0("batch_num = ", batch_num))
    },
    batch_num = 1:22,
    setup_lines = hpc_configs$r_loader,
    max_array_size = 10,
    MoreArgs = list()
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "00:15:00",
    "mem" = "1G",
    "mail-type" = "FAIL"
  )
)


