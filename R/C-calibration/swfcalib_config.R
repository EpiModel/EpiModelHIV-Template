## swfcalib Configuration
##
## Set up the calibration: six waves fitted in order from the restart pool,
## each job solved with Adrien's Gaussian process (GP) stopping rules
## (`het_gp_process.R`). A one-parameter job starts from `n_points` evenly
## spaced values over its range, `n_reps` runs each; a job with three
## parameters starts from a Latin hypercube of `n_points` points, `n_reps` runs
## each. Most jobs should finish in one iteration; a job whose design does not
## reach its target moves to a wider design and is fitted again on both.
##
## Runs start from a random member of the restart pool
## (`workflow-restart_pool.R`), not from the single restart point, so the GP
## sees the variance between starting states as well as between runs.
##
## This script should not be run directly. But `sourced` from the swfcalib
## workflow
library(swfcalib)
library(dplyr)
library(tidyr)

source("R/C-calibration/swfcalib_model.R", local = TRUE)
model_fn <- make_model_fn(calib_steps = year_steps, pool = TRUE)

source("R/C-calibration/het_gp_process.R", local = TRUE)

source("R/shared_variables.R", local = TRUE)
source("R/calibration_targets.R", local = TRUE)
source("R/netsim_settings.R", local = TRUE)
targets <- project_calibration_targets()

n_points <- 64
n_reps <- 4
n_sims <- n_points * n_reps

# Only the numeric parameters are swept, but coercing the whole table would
# silently NA the character and logical ones (prep.lai.efficacy.model,
# prep.reinit.enable and friends). Keep those out of the wide frame rather than
# turning them into NA.
params_df <- params_df |>
  filter(is.na(type) | type == "numeric") |>
  select(value, param) |>
  mutate(value = as.numeric(value)) |>
  pivot_wider(names_from = param)

# `p` percent of the pop have event in `i` steps
i2r_p <- function(i, p) 1 - (1 - p)^(1 / i)

# The range each job's first design spans, `c(min, max)`, set for Atlanta;
# revisit them for another city. A race-specific parameter without its own
# entry uses the entry of its name without the suffix. A job whose target lies
# outside its range moves to `extended` (one-parameter jobs) or to a box
# widened on the side the solution reached (three-parameter jobs).
priors <- list(
  # 50% of elig start prep in 3 months -> 4 years
  prep.start.rate = range(i2r_p(c(0.25, 4) * year_steps, 0.5)),
  # Mean waiting time to an HIV test, in timesteps: roughly 8 to 38 years.
  # This is hiv.test.int, not a rate, so it is not built with i2r_p().
  hiv.test.int = c(400, 2000),
  # 50% of ART users stop treatment within 5 years -> 15 years
  tx.halt.rate = range(i2r_p(c(5, 15) * year_steps, 0.5)),
  # HIV transmission scaler: B needs to be high, H & W needs to be low
  hiv.trans.scale_1 = c(1.5, 5),
  hiv.trans.scale_2 = c(0.2, 0.9),
  hiv.trans.scale_3 = c(0.2, 0.9),
  # STI transmission probability per condomless act. The ranges reach well
  # below the engine defaults (0.21 for gonorrhea, 0.14 for chlamydia and
  # syphilis), which the earlier ranges of 0.17 to 0.23 and 0.10 to 0.13 left
  # out for chlamydia and syphilis. Each incidence rises steeply above the
  # value at which its epidemic dies out, and that value moves with PrEP and
  # screening: in a four-city calibration (November 2026), the values that
  # reached the targets were 0.12 to 0.19 for gonorrhea, 0.08 to 0.14 for
  # chlamydia and 0.07 to 0.12 for syphilis.
  gono.uret.prob = c(0.07, 0.23),
  chla.uret.prob = c(0.05, 0.17),
  syph.prob = c(0.04, 0.15),
  # Arrival per 1000 nodes in the model per week: 0.2 -> 0.6
  a.rate = c(0.0002, 0.0006)
)

# Fallback range of a one-parameter job: half the lower bound to twice the
# upper
extended <- lapply(priors, \(x) c(x[1] / 2, x[2] * 2))

# NOT FITTED: the AIDS death rate off treatment (`aids.off.tx.mort.rate`).
# Fitted to `disease.mr100`, it stops being a survival estimate. It becomes the
# odds that a man in untreated AIDS dies there rather than leaves it another
# way, and absorbs whatever the care cascade and the target's count of deaths
# get wrong: in a four-city calibration (November 2026), the fitted rate gave
# untreated survival from infection of 13 to 39 years. It is to be fixed from
# the pre-ART literature, with AIDS-triggered diagnosis and return to ART, and
# those values set in `data/input/model_parameters.csv` once the engine
# supports them (EpiModelHIV-p#378). Until then it stays at the engine default.
# `disease.mr100` is a check, reported with the other targets after the
# confirmation run.

#' The prior, or the extended range, of a parameter: its own entry if it has
#' one, otherwise the entry of its name without the race suffix.
param_range <- function(param, ranges) {
  if (param %in% names(ranges)) ranges[[param]] else
    ranges[[sub("_\\d$", "", param)]]
}

# Job constructors, so every job of a kind is set up the same way. A
# one-parameter job accepts the closest value within the target's tolerance
# when the GP mean does not cross it; an STI job (`positive_only`) fits its GP
# on the design points at which the epidemic survived in every run.
gp_job_single <- function(target, param, target_val = targets[target],
                          positive_only = FALSE) {
  list(
    targets = target,
    targets_val = target_val,
    params = param,
    initial_proposals = make_grid_design(
      param, param_range(param, priors), n_points, n_reps
    ),
    make_next_proposals = proposer_load_sideload,
    get_result = determ_gp_end_single(
      param_range(param, extended), n_points, n_reps,
      tol = unname(target_tolerance(target_val)),
      positive_only = positive_only
    )
  )
}
gp_job_joint <- function(target_names, params) {
  list(
    targets = target_names,
    targets_val = targets[target_names],
    params = params,
    initial_proposals = make_lhs_design(
      params, lapply(params, param_range, ranges = priors), n_points, n_reps
    ),
    make_next_proposals = proposer_load_sideload,
    get_result = determ_gp_end_joint(n_points, n_reps)
  )
}

calib_object <- list(
  config = list(
    simulator = model_fn,
    root_directory = swfcalib_dir,
    # With GP stopping rules most waves end in one or two iterations. A wave
    # still open after four stops the campaign for a look instead of running
    # `n_sims` simulations at a time until it gives up.
    max_iteration = 4,
    n_sims = n_sims,
    # Every parameter a wave fits must be here: swfcalib keeps a fitted value
    # only for the columns of this table, and drops any other without a word.
    default_proposal = select(
      params_df,
      prep.start.rate_1, prep.start.rate_2, prep.start.rate_3,
      hiv.test.int_1, hiv.test.int_2, hiv.test.int_3,
      tx.halt.rate_1, tx.halt.rate_2, tx.halt.rate_3,
      hiv.trans.scale_1, hiv.trans.scale_2, hiv.trans.scale_3,
      gono.uret.prob, chla.uret.prob, syph.prob,
      a.rate
    )
  ),
  waves = list(
    # PrEP coverage by race
    wave1 = list(
      job1 = gp_job_single("cc.prep.B", "prep.start.rate_1"),
      job2 = gp_job_single("cc.prep.H", "prep.start.rate_2"),
      job3 = gp_job_single("cc.prep.W", "prep.start.rate_3")
    ),
    # Diagnosed fraction by race
    wave2 = list(
      job1 = gp_job_single("cc.dx.B", "hiv.test.int_1"),
      job2 = gp_job_single("cc.dx.H", "hiv.test.int_2"),
      job3 = gp_job_single("cc.dx.W", "hiv.test.int_3")
    ),
    # Viral suppression by race, fitted jointly.
    #
    # A project that fits reported STI case rates rather than true incidence
    # adds a screening job here, `rate.sti.screen` to `sti.screen.hivneg.int`,
    # BEFORE the STI wave and not alongside it. Tests per person-year is driven
    # by the screening interval and is close to independent of how much disease
    # there is, whereas a reported case rate depends on both, so fitting
    # screening first identifies the pair; within one wave each job is fitted
    # as if its target responded to its own parameter only.
    wave3 = list(
      job1 = gp_job_joint(
        paste0("cc.vsupp.", c("B", "H", "W")),
        paste0("tx.halt.rate_", 1:3)
      )
    ),
    # HIV transmission, fitted to the HIV diagnosis rates by race
    # (`ir100.hiv.dx`), not to diagnosed prevalence (`i.prev.dx`), by the
    # ruling on EpiModelHIV-p#230. Surveillance diagnosed prevalence is a
    # stock built up over decades of epidemic history, migration and
    # incomplete death ascertainment, which a stationary model equilibrium
    # cannot be matched to; the annual diagnoses are counted directly.
    # Diagnosed prevalence is still reported as a check. The three targets
    # differ severalfold, which is why the joint rule solves on residuals
    # relative to each target.
    #
    # HIV goes before the STIs. The coupling runs both ways at similar
    # strength, so neither order is free (`RECALIBRATION.md`, "The wave
    # structure"). HIV goes first because its parameters move more between
    # calibration passes, and the STI fits, which sit just above the values at
    # which their epidemics die out, are best fitted last, against an HIV
    # epidemic near its final level.
    wave4 = list(
      job1 = gp_job_joint(
        paste0("ir100.hiv.dx.", c("B", "H", "W")),
        paste0("hiv.trans.scale_", 1:3)
      )
    ),
    # STI incidence. Below the value at which an epidemic dies out, its
    # incidence is flat at zero, so the response has a kink inside the range.
    # Each job fits its GP on the design points at which the epidemic survived
    # in every run.
    wave5 = list(
      job1 = gp_job_single("ir100.gono", "gono.uret.prob",
                           positive_only = TRUE),
      job2 = gp_job_single("ir100.chla", "chla.uret.prob",
                           positive_only = TRUE),
      job3 = gp_job_single("ir100.syph", "syph.prob",
                           positive_only = TRUE)
    ),
    # The population stays at the size the networks were estimated at,
    # `msm_pop` in `R/shared_variables.R`, which is also the denominator of
    # every rate target.
    wave6 = list(
      job1 = gp_job_single("num", "a.rate", target_val = c(num = msm_pop))
    )
  )
)

# Uncomment to run a single wave for testing
# calib_object$waves <- calib_object$waves[-c(1, 2, 3)]

## No job may be fitted to an NA target --------------------------------------
##
## `targets[nm]` on an absent name returns NA, and a job fitted to an NA target
## would not fit anything. That is how a renamed target silently stops being
## fitted.
##
## The test is on the VALUE and not on the name, because one job legitimately
## supplies its own: wave 6 fits the arrival rate to `msm_pop`, which comes from
## `city.csv` rather than from `project_calibration_targets()`.
bad_jobs <- unlist(lapply(names(calib_object$waves), function(w) {
  unlist(lapply(names(calib_object$waves[[w]]), function(j) {
    job <- calib_object$waves[[w]][[j]]
    if (any(is.na(job$targets_val))) {
      paste0(w, "/", j, " (", paste(job$targets[is.na(job$targets_val)],
                                    collapse = ", "), ")")
    } else {
      NULL
    }
  }))
}), use.names = FALSE)
if (length(bad_jobs)) {
  stop(
    "\n  ", length(bad_jobs), " calibration job(s) would be fitted to an NA ",
    "target:\n    ", paste(bad_jobs, collapse = "\n    "), "\n\n",
    "  Check the target names against `project_calibration_targets()` and\n",
    "  the project's `data/input/targets.csv`, if it has one."
  )
}

## Every fitted parameter must be in the default proposal ---------------------
##
## swfcalib carries a wave's result forward only for the columns of
## `default_proposal`, so a parameter left out would be fitted by its wave and
## then dropped, and every later wave would run at its old value.
wave_params <- unlist(lapply(calib_object$waves, function(wave) {
  lapply(wave, function(job) job$params)
}))
dropped_params <- setdiff(wave_params,
                          names(calib_object$config$default_proposal))
if (length(dropped_params) > 0) {
  stop(
    "swfcalib would fit and then drop: ",
    paste(dropped_params, collapse = ", "),
    ".\n  Add them to `default_proposal`."
  )
}
