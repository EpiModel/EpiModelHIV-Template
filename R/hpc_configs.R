## HPC related configuration
##
## This script should not be run directly. But `sourced` the from scripts that
## interact with the HPC (usually the `workflow-***.R` ones)

current_git_branch <- "main"
mail_user <- "user@emory.edu"

hpc_node_setup <- c(
  ". /projects/epimodel/spack/share/spack/setup-env.sh",
  "spack unload -a",
  "spack load r@4.2.1",
  "spack load git@2.35.1"
)


make_em_workflow <- function(wf_name, override = FALSE) {
  wf_path <- paste0("workflows/", wf_name)
  if (override && fs::dir_exists(wf_path)) fs::dir_delete(wf_path)

  wf <- slurmworkflow::create_workflow(
    wf_name = wf_name,
    default_sbatch_opts = list(
      "partition" = "epimodel", #"preemptable",
      # "account" = "csde",
      "mail-type" = "FAIL",
      "mail-user" = mail_user
    )
  )

  # Update RENV on the HPC
  wf <- slurmworkflow::add_workflow_step(
    wf_summary = wf,
    step_tmpl = EpiModelHPC::step_tmpl_renv_restore(
      git_branch = current_git_branch,
      setup_lines = hpc_node_setup
    ),
    sbatch_opts = list(
      "mem" = "16G",
      "cpus-per-task" = 4,
      "time" = 180
    )
  )

  return(wf)
}
