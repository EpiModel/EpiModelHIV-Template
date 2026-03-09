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

# TODO

1. make a restart point where all diseases are present and initial population
has departed
2. from this restart point, assess how long to reach equilibrium again on my
   targets
3. have swfcalib pick the best starting sim to improve convergence time
