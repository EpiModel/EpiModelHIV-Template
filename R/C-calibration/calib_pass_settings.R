## Calibration Pass Settings
##
## What each later pass changes from the defaults in `swfcalib_config.R`
## ("Later passes"). Pass 1 reads nothing from here. Each entry may set:
##
## - `window`: the factor w around the starting value a job searches first,
##   from start / w to start * w, by parameter name (a race-specific parameter
##   falls back to its name without the suffix). Merged over `default_window`.
## - `reset`: parameters whose job has changed since the previous pass (a new
##   target, or a new mechanism behind it), so the previous fit says little
##   about where the root is. A named list of search ranges, `c(min, max)`.
##   The parameter still starts the waves before its own at its start value.
## - `preposition`: factors applied to the previous fit before the pass
##   starts, by parameter name, where the model has changed in a known
##   direction since. The probe run (`workflow-pass_probe.R`) and the pass
##   both start from the moved values.
## - `waves`: the waves to run, by name. Defaults to every wave but the
##   arrival wave (wave6).
## - `start_file`: the previous pass's fitted values, when that pass stopped
##   before writing `calibrated.csv`, in the same format (`param`, `value`).
##   Relative to the project root.
## - `probe_source`: where the probe's runs start, "confirmation" (the end
##   states of the previous pass's confirmation runs) or "pool" (the previous
##   pass's restart pool); and `probe_years`, how long it runs.
##
## Entries are keyed by pass, so the settings of every pass stay on record
## next to the results they produced.
##
## This script should not be run directly. But `sourced` from
## `swfcalib_config.R` and `workflow-pass_probe.R`.

# STI per-act probabilities get a narrow window: each incidence is zero below
# the value at which its epidemic dies out and rises steeply above it, and a
# design that spans that kink biases the GP (see `determ_gp_end_single()`).
# PrEP start rates get a wide one: in a four-city calibration (November 2026),
# the largest corrections the first pass's misses needed were to the PrEP
# start rates (the largest in each of three cities measured was 28 to 57
# percent), and later waves move PrEP coverage again.
default_window <- c(
  default = 1.5,
  prep.start.rate = 2,
  gono.uret.prob = 1.08,
  chla.uret.prob = 1.08,
  syph.prob = 1.08
)

default_waves <- paste0("wave", 1:5)

# Parameters an earlier pass may have fitted that are now fixed, so the next
# pass does not start them from that fit. The AIDS death rate off treatment
# was fitted by earlier versions of `swfcalib_config.R` (see the note there).
retired_params <- "aids.off.tx.mort.rate"

calib_pass_settings <- list(
  # An example entry for a pass 2 that follows a model change raising
  # treatment halting, run warm from pass 1's confirmation (the factors are
  # placeholders):
  #
  # `2` = list(
  #   window = c(tx.halt.rate = 2),
  #   preposition = c(tx.halt.rate_1 = 1.4, tx.halt.rate_2 = 1.3,
  #                   tx.halt.rate_3 = 1.2),
  #   probe_source = "confirmation", probe_years = 30
  # )
)

#' One pass's settings, with the defaults filled in.
pass_settings <- function(pass) {
  s <- calib_pass_settings[[as.character(pass)]]
  if (is.null(s)) {
    stop(
      "No pass ", pass, " settings in ",
      "`R/C-calibration/calib_pass_settings.R`.\n",
      "  Add an entry, even an empty one, so the pass is on record."
    )
  }
  window <- default_window
  window[names(s$window)] <- s$window
  list(
    window = window,
    reset = s$reset %||% list(),
    preposition = s$preposition %||% numeric(0),
    waves = s$waves %||% default_waves,
    start_file = s$start_file,
    probe_source = s$probe_source %||% "confirmation",
    probe_years = s$probe_years %||% 30
  )
}

#' The values a later pass starts from.
#'
#' The previous pass's fitted values (its swfcalib `calibrated.csv`), without
#' the parameters no longer fitted (`retired`), moved by the pass's
#' `preposition` factors.
#'
#' @param pass The pass.
#' @param retired Parameters the previous pass fitted that are now fixed.
#'
#' @return Named numeric vector.
pass_start_values <- function(pass, retired = retired_params) {
  s <- pass_settings(pass)
  prev_file <- s$start_file %||% paste0(
    run_dir, "swfcalib", calib_pass_suffix(pass - 1), "/calibrated.csv"
  )
  if (!file.exists(prev_file)) {
    stop(
      "Pass ", pass, " starts from pass ", pass - 1, "'s fitted values, and `",
      prev_file, "` does not exist.\n",
      "  Download it from the HPC before building this workflow."
    )
  }
  prev <- read.csv(prev_file)
  prev <- stats::setNames(prev$value, prev$param)
  prev <- prev[setdiff(names(prev), retired)]
  unknown <- setdiff(names(s$preposition), names(prev))
  if (length(unknown) > 0) {
    stop("Preposition factors for parameters the previous pass did not fit: ",
         paste(unknown, collapse = ", "))
  }
  prev[names(s$preposition)] <- prev[names(s$preposition)] * s$preposition
  prev
}
