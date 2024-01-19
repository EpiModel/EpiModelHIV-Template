##
## 00. Network Model Estimation, HPC setup
##

# Libraries --------------------------------------------------------------------
library("slurmworkflow")
library("EpiModelHPC")

# Settings ---------------------------------------------------------------------
source("./R/utils-0_project_settings.R")

max_cores <- 10
source("./R/utils-hpc_configs.R") # creates `hpc_configs`

# Workflow creation ------------------------------------------------------------
wf <- create_workflow(
  wf_name = "networks_estimation",
  default_sbatch_opts = hpc_configs$default_sbatch_opts
)

# Update RENV on the HPC -------------------------------------------------------
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_renv_restore(
    git_branch = current_git_branch,
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = hpc_configs$renv_sbatch_opts
)

# Estimate the networks --------------------------------------------------------
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "./R/01-networks_estimation.R",
    args = list(
      context = "hpc",
      estimation_method = "MCMLE",
      estimation_ncores = max_cores
   ),
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "cpus-per-task" = max_cores,
    "time" = "24:00:00",
    "mem" = "0"
  )
)

# Generate the diagnostics data ------------------------------------------------
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "./R/02-networks_diagnostics.R",
    args = list(
      context = "hpc",
      ncores = max_cores,
      nsims = 50
    ),
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "cpus-per-task" = max_cores,
    "time" = "04:00:00",
    "mem-per-cpu" = "4G",
    "mail-type" = "FAIL,END"
  )
)

# Send the workflow folder to the <HPC> and run it
#
# $ scp -r ./workflows/networks_estimation <HPC>:<project_dir>/workflows/
#
# or on windows
# $ set DISPLAY=
# $ scp -r workflows\networks_estimation <HPC>:<project_dir>/workflows/
#
# on the HPC:
# $ ./workflows/networks_estimation/start_workflow.sh
#
# if the file is not executable:
# $ chmod +x workflows/networks_estimation/start_workflow.sh

# Once the worfklow is finished download the data from the HPC
#
# $ scp -r <HPC>:<project_dir>/data/intermediate/estimates ./data/intermediate/
# $ scp -r <HPC>:<project_dir>/data/intermediate/diagnostics ./data/intermediate/
#
# or on windows:
# $ set DISPLAY=
# $ scp -r <HPC>:<project_dir>/data/intermediate/estimates data\intermediate\
# $ scp -r <HPC>:<project_dir>/data/intermediate/diagnostics data\intermediate\
#
# and analyse them locally using: "./R/03-networks_diagnostics_explore.R"
