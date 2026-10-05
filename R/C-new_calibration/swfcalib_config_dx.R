## swfcalib Configuration: HIV transmission scales to new-diagnosis incidence
##
## One job: `hiv.trans.scale_1..3` (Black, Hispanic, White MSM) fitted to
## `ir100.hiv.dx.B/H/W` (new HIV diagnoses per 100 person-years at risk). All
## other parameters stay at their `model_parameters.csv` values (commit
## f660508, the pool2 calibration). Diagnosed prevalence (`i.prev.dx`) is not
## a target here and is expected to move.
##
## Runs restart from the pool built under those values (`restart_pool.rds`,
## 2026-09-29) and are read over their last 5 years, after 70 years.
## New-diagnosis incidence is within ~0.1-0.2 SD of its new equilibrium by
## then (cycle 5, S4 runs); averaging 5 years reduces run noise (the yearly SD
## of ir100.hiv.dx.H is ~18% of its mean).
##
## Two passes (`determ_gp_two_pass()`):
##   1. a wide Latin hypercube (32 points x 4 replicates) around a first guess
##      from the pool2 responses; a Gaussian-process (GP) fit per target gives
##      a least-squares solution, and a narrower design around it is saved as
##      a sideload;
##   2. that design is run, and the GP fit on both passes gives the result.
##
## This script should not be run directly. But `sourced` from the swfcalib
## workflow.
library(swfcalib)
library(dplyr)
library(tidyr)

n_sims <- 128
n_reps <- 4
restart <- TRUE

source("R/C-new_calibration/swfcalib_model.R", local = TRUE)
model_fn <- make_model_fn(calib_steps = 5 * year_steps, nsteps = calibration_end,
  restart = restart)

source("./R/C-calibration/het_gp_process.R", local = TRUE)

source("R/shared_variables.R", local = TRUE)
source("R/netsim_settings.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()

tar_names <- paste0("ir100.hiv.dx.", c("B", "H", "W"))
par_names <- paste0("hiv.trans.scale_", 1:3)

# First-pass ranges. First guess from the pool2 responses (log-log slopes of
# i.prev.dx on the three scales) and the gaps of the new pool (B -21%,
# H -55%, W +16%): 4.4 / 1.6 / 0.30. Ranges are wide around it, because those
# slopes come from another output and a narrower range.
scale_r <- list(c(3.3, 5.8), c(0.6, 2.8), c(0.15, 0.55))
# NOTE: functions stored in `calib_object` run on the HPC without this
# script's objects (only their own frames travel with them), so they must
# get everything as arguments.
make_lhs <- function(ranges, n_points, n_reps, names) {
  u <- lhs::maximinLHS(n_points, length(ranges))
  p <- lapply(seq_along(ranges), function(i) {
    rep(u[, i] * diff(ranges[[i]]) + ranges[[i]][1], times = n_reps)
  })
  stats::setNames(dplyr::as_tibble(p, .name_repair = "minimal"), names)
}
initial_proposals <- make_lhs(scale_r, n_sims / n_reps, n_reps, par_names)

# Result function: GP per target on all runs of the wave, least-squares
# solution over the tested box. Pass 1 saves a narrower design (+-20% of the
# solution, kept inside the first-pass box) and returns NULL; pass 2 returns
# the solution.
determ_gp_two_pass <- function(half_width = 0.2, first_box = scale_r,
                               n_points = n_sims / n_reps, n_rep = n_reps,
                               lhs_fn = make_lhs) {
  force(half_width); force(first_box); force(n_points); force(n_rep); force(lhs_fn)
  function(calib_object, job, results) {
    library(hetGP)
    source("./R/C-calibration/z-gp_utils.R", local = TRUE)
    results <- results[stats::complete.cases(results[c(job$params, job$targets)]), ]
    par_ranges <- lapply(results[job$params], range)
    X <- mapply(mscale, results[job$params], par_ranges)
    mods <- lapply(job$targets, function(tn) {
      hetGP::mleHetGP(X, results[[tn]], covtype = "Matern5_2", eps = 1e-6)
    })
    resid <- function(u) {
      xm <- matrix(pmin(pmax(u, 0), 1), nrow = 1)
      vapply(seq_along(mods), function(k) {
        (predict(mods[[k]], xm)$mean - job$targets_val[k]) / job$targets_val[k]
      }, numeric(1))
    }
    fit <- minpack.lm::nls.lm(par = rep(0.5, length(job$params)), fn = resid,
      lower = rep(0, length(job$params)), upper = rep(1, length(job$params)))
    par_star <- stats::setNames(mapply(munscale, fit$par, par_ranges), job$params)
    message("GP solution: ", paste(names(par_star), signif(par_star, 4), collapse = ", "),
      " | relative residuals: ", paste(signif(resid(fit$par), 3), collapse = ", "))

    if (max(results$.iteration) < 2) {
      box <- lapply(seq_along(par_star), function(i) {
        c(max(first_box[[i]][1], par_star[[i]] * (1 - half_width)),
          min(first_box[[i]][2], par_star[[i]] * (1 + half_width)))
      })
      swfcalib::save_sideload(calib_object, job,
        list(proposals = lhs_fn(box, n_points, n_rep, job$params),
          pass1_solution = par_star))
      return(NULL)
    }
    dplyr::as_tibble(as.list(par_star))
  }
}

# The current values of every parameter calibrated so far (model_parameters.csv)
cal_params <- c("prep.start.rate_1", "prep.start.rate_2", "prep.start.rate_3",
  "hiv.test.rate_1", "hiv.test.rate_2", "hiv.test.rate_3",
  "tx.halt.rate_1", "tx.halt.rate_2", "tx.halt.rate_3",
  "hiv.trans.scale_1", "hiv.trans.scale_2", "hiv.trans.scale_3",
  "gono.uret.prob", "chla.uret.prob", "syph.prob", "aids.off.tx.mort.rate", "a.rate")
default_proposal <- params_df |>
  filter(param %in% cal_params) |>
  select(param, value) |>
  mutate(value = as.numeric(value)) |>
  pivot_wider(names_from = param) |>
  select(all_of(cal_params))

calib_object <- list(
  config = list(
    simulator = model_fn,
    root_directory = paste0(run_dir, "swfcalib_dx/"),
    max_iteration = 3,
    n_sims = n_sims,
    default_proposal = default_proposal
  ),
  waves = list(
    wave1 = list(
      job1 = list(
        targets = tar_names,
        targets_val = targets[tar_names],
        params = par_names,
        initial_proposals = initial_proposals,
        make_next_proposals = proposer_load_sideload,
        get_result = determ_gp_two_pass()
      )
    )
  )
)
