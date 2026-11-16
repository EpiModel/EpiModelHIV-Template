## The calibration: parameters, targets, waves (a `truing_config`)
##
## This script should not be run directly. But `sourced` from the other scripts
## of `R/T-truing_calib/`. Requires the `truing` engine sourced, EpiModelHIV
## loaded, `params_df` (R/netsim_settings.R) and the context.

targets_val <- EpiModelHIV::get_calibration_targets()
targets_val[["num"]] <- 10000 # the 10k-node population keeps its size

# Guesses: the default parameters (package defaults + project overrides,
# `params_df`); every parameter has one
guess <- params_df |>
  dplyr::mutate(value = suppressWarnings(as.numeric(.data$value))) |>
  dplyr::filter(!is.na(.data$value)) |>
  (\(d) stats::setNames(d$value, d$param))()

# Allowed ranges (hard), wide: probabilities and per-week rates 0-1, scales
# 0-100; `a.rate` 0-0.002 (x5 its default: a higher arrival rate grows the
# population, and the runtime, without bound). No search range: pass 1 covers
# the whole allowed range, log-spaced from the end nearer the guess.
allowed_of <- function(p) {
  if (p == "a.rate") c(0, 0.002) else if (grepl("scale", p)) c(0, 100) else c(0, 1)
}
par_of <- function(p) {
  if (!p %in% names(guess)) stop("No default value for `", p, "`")
  truing_par(p, guess[[p]], allowed_of(p))
}

# Targets: value, tolerance, the parameter that solves it, its direction
tgt <- function(t, tol, p, inc) truing_target(t, targets_val[[t]], tol, p, inc)
races <- c("B", "H", "W")
targets <- c(
  lapply(1:3, \(i) tgt(paste0("cc.prep.", races[i]), 0.01,
                       paste0("prep.start.rate_", i), TRUE)),
  lapply(1:3, \(i) tgt(paste0("cc.dx.", races[i]), 0.01,
                       paste0("hiv.test.rate_", i), TRUE)),
  lapply(1:3, \(i) tgt(paste0("cc.vsupp.", races[i]), 0.01,
                       paste0("tx.halt.rate_", i), FALSE)),
  list(tgt("ir100.gono", 0.5, "gono.uret.prob", TRUE),
       tgt("ir100.chla", 0.5, "chla.uret.prob", TRUE),
       tgt("ir100.syph", 0.25, "syph.prob", TRUE)),
  lapply(1:3, \(i) tgt(paste0("i.prev.dx.", races[i]),
                       c(0.01, 0.005, 0.005)[i],
                       paste0("hiv.trans.scale_", i), TRUE)),
  list(tgt("disease.mr100", 0.01, "aids.off.tx.mort.rate", TRUE),
       tgt("num", 50, "a.rate", TRUE))
)
params <- lapply(vapply(targets, `[[`, "", "param"), par_of)

tn <- vapply(targets, `[[`, "", "name")
waves <- list(
  truing_wave(grep("^cc.prep", tn, value = TRUE), n_rows = 64, reps = 4),
  truing_wave(grep("^cc.(dx|vsupp)", tn, value = TRUE), n_rows = 64, reps = 8),
  truing_wave(grep("^ir100", tn, value = TRUE), n_rows = 128, reps = 8),
  truing_wave(c(paste0("i.prev.dx.", races), "disease.mr100", "num"),
              joint = list(paste0("i.prev.dx.", races)),
              n_rows = 128, reps = 8)
)

# Restart pools: every STI epidemic at least half its target
pool_keep <- function(Y) {
  Y$ir100.gono >= targets_val[["ir100.gono"]] / 2 &
    Y$ir100.chla >= targets_val[["ir100.chla"]] / 2 &
    Y$ir100.syph >= targets_val[["ir100.syph"]] / 2
}

truing_cfg <- truing_config(
  name = truing_calib_name, params = params, targets = targets, waves = waves,
  pool0_runs = 128, pool_size = 32, pool_keep = pool_keep,
  conf_min = 128, conf_max = 1024, max_passes = 3, max_wave_batches = 2,
  seed = 20261116L
)

if (truing_tiny) {
  for (k in seq_along(truing_cfg$waves)) {
    truing_cfg$waves[[k]]$n_rows <- 4L
    truing_cfg$waves[[k]]$reps <- 1L
  }
  truing_cfg$pool0_runs <- 4L
  truing_cfg$pool_size <- 2L
  truing_cfg$conf_min <- 2L
  truing_cfg$conf_max <- 2L
  truing_cfg$max_passes <- 1L
  truing_cfg$max_wave_batches <- 1L
  truing_cfg$pool_keep <- function(Y) rep(TRUE, nrow(Y)) # 1-year runs
}
