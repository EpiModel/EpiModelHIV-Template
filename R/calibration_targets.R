## Project calibration targets
##
## This script should not be run directly. It is `sourced` from any script that
## needs the calibration targets by value.
##
## THIS IS THE ONE PLACE TO OVERRIDE A TARGET. `EpiModelHIV::get_calibration_targets()`
## ships the engine's targets for the project's city (`city`, set in
## `R/shared_variables.R`), and the engine branch is shared across projects that
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
##
## THE TARGETS ARE THE CITY'S OWN. The engine has every target for Atlanta. For
## a city that lacks some, `get_calibration_targets()` stops and names them, and
## it never fills them with Atlanta's. Network estimation and model development
## do not need the targets; calibration does. To calibrate such a city, add the
## missing targets to the engine's registry, or, for a target this project
## supplies itself, call it with `allow.missing = TRUE` and set every `NA` in
## the overrides below.

project_calibration_targets <- function() {
  targets <- EpiModelHIV::get_calibration_targets(city = city)

  # ---- project overrides go here ----------------------------------------
  # (none: this template ships the engine targets unmodified)

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
