# Calibration

## Introduction

In this step we calibrate the model. It is the most complex step. Most users will
not calibrate the model themselves. The rest of this document is aimed as the
person in charge of calibration.

The calibration aims to make the model fit a set of *targets* by modifying the
input parameters. The steps are always the same:

1. run the model with a set of parameters
2. assess how close the model is to the targets
3. propose a new set of parameters
4. repeat until calibrated

This step showcases two approaches for calibration, a "manual" one where each
of this step is planned by the user. And an automated one leveraging
[swfcalib](https://github.com/EpiModel/swfcalib).

## General consideration

Our models are calibrated in two part. The first one before PrEP is initialized
and a second one after. In between, the `workflow-restart_point.R` script is
used to select a good restart point. This approach allow us not to re-simulate
the 60 year burn-in period for each simulation.

## Manual calibration

For this one we use the *manual_calib_* workflows. The idea is to:
- pick some parameters to test
- download the `calib_assess.csv` file
- look at the results
- guestimate a new set

Until we are happy with the results.

## Automated calibration

Here we define how the calibration should happen in the `swfcalib_config_x.R`
scripts. See [the `swfcalib`
vignette](https://epimodel.github.io/swfcalib/articles/swfcalib.html) for
details.

