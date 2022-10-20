# working on HPC

step1_n_cores <- 10
step2_n_cores <- 30
# pkgload::load_all("../../swfcalib")

library(EpiModelHPC)
source("R/auto_cal_fns.R")
source("R/auto_cal_sim.R")

n_sims <- 300

calib_object <- list(
  waves = list(
    wave1 = list(
      job1 = list(
        targets = paste0("cc.dx.", c("B", "H", "W")),
        targets_val = c(0.847, 0.818, 0.873),
        params = paste0("hiv.test.rate_", 1:3),
        initial_proposals = dplyr::tibble(
          hiv.test.rate_1 = sample(seq(0.001, 0.01, length.out = n_sims)),
          hiv.test.rate_2 = sample(hiv.test.rate_1),
          hiv.test.rate_3 = sample(hiv.test.rate_1)
        ),
        make_next_proposals = make_ind_shrink_proposer(n_sims),
        get_result = determ_ind_poly_end(0.001)
      ),
      job2 = list(
        targets = paste0("cc.linked1m.", c("B", "H", "W")),
        targets_val = c(0.829, 0.898, 0.89),
        params = paste0("tx.init.rate_", 1:3),
        initial_proposals = dplyr::tibble(
          tx.init.rate_1 = sample(seq(0.1, 0.5, length.out = n_sims)),
          tx.init.rate_2 = sample(tx.init.rate_1),
          tx.init.rate_3 = sample(tx.init.rate_1),
        ),
        make_next_proposals = make_ind_shrink_proposer(n_sims),
        get_result = determ_ind_poly_end(0.001)
      )
    ),
    wave2 = list(
      job1 = list(
        targets = paste0("cc.vsupp.", c("B", "H", "W")),
        targets_val = c(0.605, 0.62, 0.71),
        params = paste0("tx.halt.partial.rate_", 1:3),
        initial_proposals = dplyr::tibble(
          tx.halt.partial.rate_1 = sample(seq(0.001, 0.01, length.out = n_sims)),
          tx.halt.partial.rate_2 = sample(tx.halt.partial.rate_1),
          tx.halt.partial.rate_3 = sample(tx.halt.partial.rate_1)
        ),
        make_next_proposals = make_ind_shrink_proposer(n_sims),
        get_result = determ_ind_poly_end(0.001)
      )
    ),
    wave3 = list(
      job1 = list(
        targets = paste0("i.prev.dx.", c("B", "H", "W")),
        targets_val = c(0.33, 0.127, 0.084),
        params = paste0("hiv.trans.scale_", 1:3),
        initial_proposals = dplyr::tibble(
          hiv.trans.scale_1 = sample(seq(1, 10, length.out = n_sims)),
          hiv.trans.scale_2 = sample(seq(0.1, 1, length.out = n_sims)),
          hiv.trans.scale_3 = sample(seq(0.1, 1, length.out = n_sims))
        ),
        make_next_proposals = make_ind_shrink_proposer(n_sims),
        get_result = determ_lin_poly_end(c(0.01, 0.01, 0.01))
      )
    )
  ),
  config = list(
    simulator = model_fun,
    default_proposal = dplyr::tibble(
      hiv.test.rate_1 = 0.001,
      hiv.test.rate_2 = hiv.test.rate_1,
      hiv.test.rate_3 = hiv.test.rate_1,
      tx.init.rate_1 = 0.1,
      tx.init.rate_2 = tx.init.rate_1,
      tx.init.rate_3 = tx.init.rate_1,
      tx.halt.partial.rate_1 = 0.001,
      tx.halt.partial.rate_2 = tx.halt.partial.rate_1,
      tx.halt.partial.rate_3 = tx.halt.partial.rate_1,
      hiv.trans.scale_1 = 3,
      hiv.trans.scale_2 = 0.5,
      hiv.trans.scale_3 = 0.3
    ),
    root_directory = "data/calib",
    max_iteration = 100,
    n_sims = n_sims
  )
  # state = list() # managed internally
)

library(slurmworkflow)
library(EpiModelHPC)

hpc_configs <- swf_configs_rsph(
  partition = "preemptable",
  mail_user = "aleguil@emory.edu"
)

# Workflow creation ------------------------------------------------------------
wf <- create_workflow(
  wf_name = "auto_calib",
  default_sbatch_opts = hpc_configs$default_sbatch_opts
)

# Update RENV on the HPC -------------------------------------------------------
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_renv_restore(
    git_branch = "auto_calib",
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = hpc_configs$renv_sbatch_opts
)

# Calibration step 1 -----------------------------------------------------------
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/wf_step1.R",
    args = list(
      n_cores = step1_n_cores,
      calib_object = calib_object
    ),
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "cpus-per-task" = step1_n_cores,
    "time" = "00:20:00",
    "mem-per-cpu" = "4G",
    "mail-type" = "FAIL"
  )
)

# Calibration step 2 -----------------------------------------------------------
batch_numbers <- swfcalib:::get_batch_numbers(calib_object, step2_n_cores)
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_map_script(
    r_script = "R/wf_step2.R",
    batch_num = batch_numbers,
    setup_lines = hpc_configs$r_loader,
    max_array_size = 400,
    MoreArgs = list(
      n_cores = step2_n_cores,
      n_batches = max(batch_numbers),
      calib_object = calib_object
    )
  ),
  sbatch_opts = list(
    "cpus-per-task" = step2_n_cores,
    "time" = "02:00:00",
    "mem" = "0",
    "mail-type" = "FAIL"
  )
)

# Calibration step 3 -----------------------------------------------------------
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call(
    what = swfcalib::calibration_step3,
    args = list(
      calib_object = calib_object
    ),
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "cpus-per-task" = 1,
    "time" = "00:20:00",
    "mem-per-cpu" = "8G",
    "mail-type" = "END"
  )
)
