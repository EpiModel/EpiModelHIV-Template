# working on HPC
#
# if works correctly:
#   - step1 should provide better logs
#   - how to simplify the whole process
#   - how to get message on finish?
#
#  PROBABLE ERROR ON determ_noisy_end IN CALCULATING THE LOSS
#   not in loss apparently
#   need log when a calib is done (to see where we at)
#     store in calib object and log at the end of each step1

step1_n_cores <- 10
step2_n_cores <- 30

library(EpiModelHPC)
source("R/auto_cal_fns.R")
source("R/auto_cal_sim.R")

n_sims <- 900

calib_object <- list(
  waves = list(
    wave1 = list(
      job1 = list(
        targets = "cc.dx.B",
        targets_val = 0.804,
        params = c("hiv.test.rate_1"), # target: 0.00385
        initial_proposals = dplyr::tibble(
          hiv.test.rate_1 = seq(0.001, 0.01, length.out = n_sims),
        ),
        make_next_proposals = make_noisy_proposer(n_sims, n_sims / 2),
        get_result = determ_noisy_end(0.01, 50)
      ),
      job2 = list(
        targets = "cc.dx.H",
        targets_val = 0.799,
        params = c("hiv.test.rate_2"), # target: 0.0038
        initial_proposals = dplyr::tibble(
          hiv.test.rate_2 = seq(0.001, 0.01, length.out = n_sims),
        ),
        make_next_proposals = make_noisy_proposer(n_sims, n_sims / 2),
        get_result = determ_noisy_end(0.01, 50)
      ),
      job3 = list(
        targets = "cc.dx.W",
        targets_val = 0.88,
        params = c("hiv.test.rate_3"), # target: 0.0069
        initial_proposals = dplyr::tibble(
          hiv.test.rate_3 = seq(0.001, 0.01, length.out = n_sims),
        ),
        make_next_proposals = make_noisy_proposer(n_sims, n_sims / 2),
        get_result = determ_noisy_end(0.01, 50)
      ),
      job4 = list(
        targets = "cc.linked1m.B",
        targets_val = 0.62,
        params = c("tx.init.rate_1"), # target: 0.1775
        initial_proposals = dplyr::tibble(
          tx.init.rate_1 = seq(0.1, 0.5, length.out = n_sims),
        ),
        make_next_proposals = make_noisy_proposer(n_sims, n_sims / 2),
        get_result = determ_noisy_end(0.01, 50)
      ),
      job5 = list(
        targets = "cc.linked1m.H",
        targets_val = 0.65,
        params = c("tx.init.rate_2"), # target: 0.19
        initial_proposals = dplyr::tibble(
          tx.init.rate_2 = seq(0.1, 0.5, length.out = n_sims),
        ),
        make_next_proposals = make_noisy_proposer(n_sims, n_sims / 2),
        get_result = determ_noisy_end(0.01, 50)
      ),
      job6 = list(
        targets = "cc.linked1m.W",
        targets_val = 0.76,
        params = c("tx.init.rate_3"), # target: 0.2521
        initial_proposals = dplyr::tibble(
          tx.init.rate_3 = seq(0.1, 0.5, length.out = n_sims),
        ),
        make_next_proposals = make_noisy_proposer(n_sims, n_sims / 2),
        get_result = determ_noisy_end(0.01, 50)
      )
    ),
    wave2 = list(
      job1 = list(
        targets = "cc.vsupp.B",
        targets_val = 0.55,
        params = c("tx.halt.partial.rate_1"), # target: 0.00385
        initial_proposals = dplyr::tibble(
          tx.halt.partial.rate_1 = seq(0.001, 0.01, length.out = n_sims),
        ),
        make_next_proposals = make_noisy_proposer(n_sims, n_sims / 2),
        get_result = determ_noisy_end(0.01, 50)
      ),
      job2 = list(
        targets = "cc.vsupp.H",
        targets_val = 0.60,
        params = c("tx.halt.partial.rate_2"), # target: 0.0038
        initial_proposals = dplyr::tibble(
          tx.halt.partial.rate_2 = seq(0.001, 0.01, length.out = n_sims),
        ),
        make_next_proposals = make_noisy_proposer(n_sims, n_sims / 2),
        get_result = determ_noisy_end(0.01, 50)
      ),
      job3 = list(
        targets = "cc.vsupp.W",
        targets_val = 0.72,
        params = c("tx.halt.partial.rate_3"), # target: 0.0069
        initial_proposals = dplyr::tibble(
          tx.halt.partial.rate_3 = seq(0.001, 0.01, length.out = n_sims),
        ),
        make_next_proposals = make_noisy_proposer(n_sims, n_sims / 2),
        get_result = determ_noisy_end(0.01, 50)
      )
    )
  ),
  config = list(
    simulator = model_fun,
    default_proposal = dplyr::tibble(
      hiv.test.rate_1 = 0.001,
      hiv.test.rate_2 = 0.001,
      hiv.test.rate_3 = 0.001,
      tx.init.rate_1 = 0.1,
      tx.init.rate_2 = 0.1,
      tx.init.rate_3 = 0.1,
      tx.halt.partial.rate_1 = 0.001,
      tx.halt.partial.rate_2 = 0.001,
      tx.halt.partial.rate_3 = 0.001
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

# Step 1 -----------------------------------------------------------------------
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

# Step 2 -----------------------------------------------------------------------
batch_numbers <- EpiModelHPC:::get_batch_numbers(calib_object, step2_n_cores)
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

# Step 3 -----------------------------------------------------------------------
wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call(
    r_script = EpiModelHPC::calibration_step3,
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
