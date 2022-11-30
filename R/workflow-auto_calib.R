# working on HPC

step1_n_cores <- 10
step2_n_cores <- 20

library(EpiModelHPC)
source("R/auto_cal_fns.R")
source("R/auto_cal_sim.R")

n_sims <- 300

calib_object <- list(
  waves = list(
    wave1 = list(
      job1 = list(
        targets = "cc.dx.B",
        targets_val = 0.847,
        params = c("hiv.test.rate_1"), # target: 0.00385
        initial_proposals = dplyr::tibble(
          hiv.test.rate_1 = seq(0.001, 0.01, length.out = n_sims),
          ),
        make_next_proposals = make_shrink_proposer(n_sims),
        get_result = determ_poly_end(0.001, poly_n = 5)
        ),
      job2 = list(
        targets = "cc.dx.H",
        targets_val = 0.818,
        params = c("hiv.test.rate_2"), # target: 0.0038
        initial_proposals = dplyr::tibble(
          hiv.test.rate_2 = seq(0.001, 0.01, length.out = n_sims),
          ),
        make_next_proposals = make_shrink_proposer(n_sims),
        get_result = determ_poly_end(0.001, poly_n = 5)
        ),
      job3 = list(
        targets = "cc.dx.W",
        targets_val = 0.873,
        params = c("hiv.test.rate_3"), # target: 0.0069
        initial_proposals = dplyr::tibble(
          hiv.test.rate_3 = seq(0.001, 0.01, length.out = n_sims),
          ),
        make_next_proposals = make_shrink_proposer(n_sims),
        get_result = determ_poly_end(0.001, poly_n = 5)
        ),
      job4 = list(
        targets = paste0("cc.linked1m.", c("B", "H", "W")),
        targets_val = c(0.829, 0.898, 0.89),
        params = paste0("tx.init.rate_", 1:3),
        initial_proposals = dplyr::tibble(
          tx.init.rate_1 = sample(seq(0.1, 0.5, length.out = n_sims)),
          tx.init.rate_2 = sample(tx.init.rate_1),
          tx.init.rate_3 = sample(tx.init.rate_1),
        ),
        make_next_proposals = make_ind_shrink_proposer(n_sims),
        get_result = determ_ind_poly_end(0.001, poly_n = 3)
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
        get_result = determ_ind_poly_end(0.001, poly_n = 3)
      )
    ) ,
    wave3 = list(
      job1 = list(
        targets = paste0("i.prev.dx.", c("B", "H", "W")),
        targets_val = c(0.33, 0.127, 0.084),
        params = paste0("hiv.trans.scale_", 1:3),
        initial_proposals = dplyr::tibble(
          hiv.trans.scale_1 = sample(seq(3, 6, length.out = n_sims)),
          hiv.trans.scale_2 = sample(seq(0.3, 0.6, length.out = n_sims)),
          hiv.trans.scale_3 = sample(seq(0.2, 0.5, length.out = n_sims))
        ),
        make_next_proposals = make_dumb_proposer(n_sims),
        get_result = make_dumb_end(iter = 5)
        # get_result = determ_lin_poly_end(c(0.005, 0.01, 0.01), poly_n = 1)
      )
    )
  ),
  config = list(
    simulator = model_fun,
    default_proposal = dplyr::tibble(
      hiv.test.rate_1 = 0.004,
      hiv.test.rate_2 = hiv.test.rate_1,
      hiv.test.rate_3 = hiv.test.rate_1,
      tx.init.rate_1 = 0.3,
      tx.init.rate_2 = tx.init.rate_1,
      tx.init.rate_3 = tx.init.rate_1,
      tx.halt.partial.rate_1 = 0.003,
      tx.halt.partial.rate_2 = tx.halt.partial.rate_1,
      tx.halt.partial.rate_3 = tx.halt.partial.rate_1,
      hiv.trans.scale_1 = 4,
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

hpc_configs <- swf_configs_hyak(
  hpc = "mox",
  partition = "ckpt",
  r_version = "4.1.2",
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
    "time" = "05:00:00",
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
    "mail-type" = "FAIL"
  )
)

# Calibration test -------------------------------------------------------------
library(EpiModelHIV)
source("R/00-project_settings.R")
max_cores <- 20

epistats <- readRDS("data/intermediate/estimates/epistats.rds")
netstats <- readRDS("data/intermediate/estimates/netstats.rds")
est      <- readRDS("data/intermediate/estimates/netest.rds")

param <- param.net(
  data.frame.params = readr::read_csv("data/input/params.csv"),
  netstats          = netstats,
  epistats          = epistats,
  prep.start        = prep_start,
  riskh.start       = prep_start - 53,
  .param.updater.list = list(
    # High PrEP intake for the first year; go back to normal to get to 15%
    list(at = prep_start, param = list(prep.start.prob = function(x) x * 2)),
    list(at = prep_start + 52, param = list(prep.start.prob = function(x) x / 2))
  )
)

init <- init_msm(
  prev.ugc = 0.1,
  prev.rct = 0.1,
  prev.rgc = 0.1,
  prev.uct = 0.1
)

# Controls
source("R/utils-targets.R")
control <- control_msm(
  nsteps              = calibration_end,
  nsims               = 1,
  ncores              = 1,
  cumulative.edgelist = TRUE,
  truncate.el.cuml    = 0,
  .tracker.list       = calibration_trackers,
  # .checkpoint.dir     = "temp/cp_calib",
  # .checkpoint.clear   = TRUE,
  # .checkpoint.steps   = 15 * 52,
  verbose             = FALSE
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_netsim_swfcalib_output(
    est, param, init, control,
    calib_object = calib_object,
    output_dir = "data/intermediate/calibration",
    libraries = "EpiModelHIV",
    n_rep = 500,
    n_cores = 20,
    max_array_size = 999,
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "mail-type" = "FAIL,TIME_LIMIT",
    "cpus-per-task" = max_cores,
    "time" = "04:00:00",
    "mem" = "0" # special: all mem on node
  )
)

wf <- add_workflow_step(
  wf_summary = wf,
  step_tmpl = step_tmpl_do_call_script(
    r_script = "R/wscript-calibration_process.R",
    args = list(
      ncores = 15,
      nsteps = 52
    ),
    setup_lines = hpc_configs$r_loader
  ),
  sbatch_opts = list(
    "cpus-per-task" = max_cores,
    "time" = "04:00:00",
    "mem-per-cpu" = "4G",
    "mail-type" = "END"
  )
)
