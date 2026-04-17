## HPC related configuration
##
## This script should not be run directly. But `sourced` from the
## scripts that interact with the HPC (the `workflow-*.R` ones)

current_git_branch <- "dev_v3.3"          # <- USER: your git branch

hpc_node_setup <- c(
  ". /projects/epimodel/spack/share/spack/setup-env.sh",
  "spack unload -a",
  "spack load r@4.5.1"
)

# `update_renv = TRUE` makes a lighter "renv.lock.hpc" file to be
# used on the HPC. This simplifies the setup by only installing
# what's required to run the model itself and not the packages used
# for analysis. Make sure to `push` this "renv.lock.hpc" file to
# your `git` repo before running the HPC workflows.
make_em_workflow <- function(wf_name, override = FALSE, update_renv = TRUE) {

  # Check that `mail-user` is configured
  hpc_mail_user <- Sys.getenv("HPC_MAIL_USER", unset = "")
  if (!nzchar(hpc_mail_user)) {
    stop(
      "\n",
      "  The mail address for HPC notification is not correctly set.\n",
      "  Define the `HPC_MAIL_USER` variable in '.Renviron'.\n\n",
      "  Open '.Renviron' with: \n",
      "    `usethis::edit_r_environ(\"project\")`.\n\n",
      "  Write in it: \n",
      "    HPC_MAIL_USER=\"user@emoy.edu\"\n\n",
      "  then save the file and restart R."
    )
  }
  message("HPC notifications will be mailed to:\n    \"", hpc_mail_user, "\"")

  if (update_renv) {
    renv::snapshot(
      packages = c("EpiModelHIV", "EpiModelHPC", "ARTnetData"),
      lockfile = "renv.lock.hpc",
      prompt = FALSE
    )
  }

  wf_path <- paste0("workflows/", wf_name)
  if (override && fs::dir_exists(wf_path)) fs::dir_delete(wf_path)

  wf <- slurmworkflow::create_workflow(
    wf_name = wf_name,
    default_sbatch_opts = list(
      "partition" =
        "epimodel,short-cpu,day-long-cpu,week-long-cpu,month-long-cpu",
      "mail-type" = "FAIL",
      "mail-user" = hpc_mail_user
    )
  )

  # Update RENV on the HPC
  wf <- slurmworkflow::add_workflow_step(
    wf_summary = wf,
    step_tmpl = EpiModelHPC::step_tmpl_renv_restore(
      git_branch = current_git_branch,
      setup_lines = hpc_node_setup,
      lockfile = if (update_renv) "renv.lock.hpc" else NULL
    ),
    sbatch_opts = list(
      "mem" = "16G",
      "cpus-per-task" = 4,
      "time" = 180
    )
  )

  wf
}
