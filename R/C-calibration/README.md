# Calibration

## Introduction

In this chapter we calibrate the model.
It is a very technical step an most users will not calibrate the model
themselves. The rest of this document is aimed as the person in charge of calibration.

The calibration aims to make the model fit a set of *targets* by modifying the
input parameters. The steps are always the same:

1. run the model with a set of parameters
2. assess how close the model is to the targets
3. propose a new set of parameters
4. repeat until calibrated

This step showcases two approaches for calibration, a "manual" one where each
of this step is planned by the user. And an automated one leveraging
[swfcalib](https://github.com/EpiModel/swfcalib).

## Manual calibration

For this one we use the *manual_calib_* workflows. The idea is to:
- pick some parameters to test
- download the `calib_assess.csv` file
- look at the results
- guestimate a new set

Until we are happy with the results.

## Automated calibration

Here we define how the calibration should happen in the `swfcalib_config.R`
scripts. See [the `swfcalib`
vignette](https://epimodel.github.io/swfcalib/articles/swfcalib.html) for
details.

## Restart point

After calibration is complete, use `workflow-restart_point.R` to create a
checkpoint simulation. This restart point is used by Chapter D as the starting
state for intervention runs — it saves time by not re-simulating the burn-in
period.
