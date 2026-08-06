## Project calibration targets
##
## This script should not be run directly. It is `sourced` from any script that
## needs the calibration targets by value.
##
## THIS IS THE ONE PLACE TO OVERRIDE A TARGET. `EpiModelHIV::get_calibration_targets()`
## ships engine defaults, and the engine branch is shared across projects that
## sit on different response curves, so most projects will need to move at least
## one target. Overriding here rather than at each call site keeps the optimizer,
## the restart chooser, the post-processing and the plots reading the same
## numbers. They have drifted apart before.
##
## To override, uncomment and edit:
##
##   targets["ir100.syph"] <- 2.5
##
## and record WHY in a comment, with the source. A target without provenance is
## a number nobody can defend later.

project_calibration_targets <- function() {
  targets <- EpiModelHIV::get_calibration_targets()

  # ---- project overrides go here ----------------------------------------
  # (none: this template ships the engine defaults unmodified)

  targets
}

## Plausible intervals, for reporting and for judging whether a calibrated model
## is acceptable rather than merely closest. Not used by the optimizer.
##
## These are also what a bracket check uses to set prior width: map the interval
## endpoints back through the response curve to get a parameter range. A target
## whose root falls outside its prior will pin at a boundary and report the
## boundary as converged, burning the full iteration budget without any error.
project_calibration_intervals <- list(
  # ir100.syph = c(2.0, 3.2)
)
