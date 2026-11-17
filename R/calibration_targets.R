## Project calibration targets
##
## This script should not be run directly. It is `sourced` from any script that
## needs the calibration targets by value. Requires `R/shared_variables.R`.
##
## The targets are the engine's defaults, which are Atlanta's
## (`EpiModelHIV::get_calibration_targets()`), unless the project has its own
## `data/input/targets.csv`. A project that models another city provides that
## file: one row per target with its value, a plausible interval where one
## exists, and its source. See "Modeling another city" in the README for the
## format. A target the file does not have is not filled in from the engine:
## `swfcalib_config.R` stops if a calibration job has no value for its target.
##
## THIS IS THE ONE PLACE TO OVERRIDE A TARGET. Overriding here and not at each
## call site keeps the optimizer, the restart chooser, the post-processing and
## the plots reading the same numbers. They have drifted apart before.

targets_file <- paste0(input_dir, "targets.csv")
targets_table <- if (file.exists(targets_file)) read.csv(targets_file)

project_calibration_targets <- function() {
  targets <- if (is.null(targets_table)) {
    EpiModelHIV::get_calibration_targets()
  } else {
    # Only the rows marked `fitted`. The others stay in the file for the
    # record (a retired target, or one derived for comparison) and are not
    # targets.
    if (!"fitted" %in% names(targets_table)) {
      stop("`", targets_file, "` has no `fitted` column. See \"Modeling ",
           "another city\" in the README for the format.")
    }
    fitted <- targets_table[as.logical(targets_table$fitted), ]
    setNames(fitted$value, fitted$target)
  }

  # ---- project overrides go here ----------------------------------------
  # To override, uncomment and edit, and record WHY in a comment, with the
  # source. A target without provenance is a number nobody can defend later.
  #
  #   targets["ir100.syph"] <- 2.5

  targets
}

## Plausible intervals, for reporting and for judging whether a calibrated model
## is acceptable and not merely closest. Not used by the optimizer. With a
## `targets.csv` they are its `lower` and `upper` columns.
##
## These are also what a bracket check uses to set prior width: map the interval
## endpoints back through the response curve to get a parameter range. A job
## whose root falls outside its prior widens its design toward it, up to the
## extended range in `swfcalib_config.R`, and spends iterations doing so.
project_calibration_intervals <- list(
  # ir100.syph = c(2.0, 3.2)
)
if (!is.null(targets_table)) {
  with_interval <- !is.na(targets_table$lower)
  project_calibration_intervals <- setNames(
    Map(c, targets_table$lower[with_interval],
        targets_table$upper[with_interval]),
    targets_table$target[with_interval]
  )
}

#' Tolerance of each target, in the target's units.
#'
#' The rule for stopping a calibration after its confirmation run (Adrien's,
#' with a relative one for the rates): 1 percentage point for the care-cascade
#' proportions (`cc.*`) and 10 percent of the target for every other target
#' (HIV prevalence and diagnosis rates by race, the STI incidence rates,
#' population size). The one-parameter GP rule in `het_gp_process.R` uses it
#' too, so a job accepts what the confirmation would.
#'
#' The rates get a relative tolerance because an absolute one does not travel
#' between targets of different sizes: 1 per 100 person-years is 9 percent of
#' the engine's gonorrhea target and 40 percent of its syphilis one.
#'
#' @param targets Named numeric vector of targets.
#'
#' @return Named numeric vector of tolerances.
target_tolerance <- function(targets) {
  nms <- names(targets)
  tol <- 0.1 * abs(targets)
  tol[startsWith(nms, "cc.")] <- 0.01
  tol
}

#' The target of each bacterial STI.
#'
#' For gonorrhea, chlamydia and syphilis, the first target whose name is
#' `ir100.<sti>` or starts with `ir100.<sti>.`: the engine's true incidence
#' (`ir100.gono`) with the default targets, or a reported case rate
#' (`ir100.gono.rep`) in a project whose `targets.csv` fits one. The restart
#' chooser and the restart pool keep a simulation only if each STI is alive by
#' this measure, so neither names a target.
#'
#' @param targets Named numeric vector of targets.
#'
#' @return Named character vector (`gono`, `chla`, `syph`), without the STIs
#'   that have no target.
sti_target_names <- function(targets) {
  stis <- c(gono = "gono", chla = "chla", syph = "syph")
  nms <- vapply(stis, function(s) {
    hit <- grep(paste0("^ir100\\.", s, "(\\.|$)"), names(targets), value = TRUE)
    if (length(hit) == 0) NA_character_ else hit[1]
  }, character(1))
  nms[!is.na(nms)]
}

#' The true-incidence range a calibrated model should not leave, by STI.
#'
#' Optional. A project that fits reported STI case rates can derive the true
#' incidence they imply and give it as the `guard` rows of
#' `data/input/sti-ranges.csv` (columns `target`, `kind`, `lower`, `upper`).
#' A fit that reproduces a reported rate while leaving that range has almost
#' certainly done so by distorting screening. `process_calibs.R` reports each
#' STI's true incidence against it. Without the file there is no guard.
#'
#' @return Named list of two-element ranges, empty without the file.
project_calibration_incidence_guard <- function() {
  ranges_file <- paste0(input_dir, "sti-ranges.csv")
  if (!file.exists(ranges_file)) return(list())
  ranges <- read.csv(ranges_file)
  ranges <- ranges[ranges$kind == "guard", ]
  setNames(Map(c, ranges$lower, ranges$upper), ranges$target)
}
