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
    setNames(targets_table$value, targets_table$target)
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
## endpoints back through the response curve to get a parameter range. A target
## whose root falls outside its prior will pin at a boundary and report the
## boundary as converged, burning the full iteration budget without any error.
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
