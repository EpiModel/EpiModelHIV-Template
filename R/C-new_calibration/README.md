# New Calibration

## Walkthrough

1. bad swfcalib
    - 3 waves
    - wide priors
    - 128 runs (32x4)
2. validation set + calib report to check the result
3. make restart pool
    - just make sure STIs are live in all
    - see "./R/C-new_calibration/3-choose_restart.R"
4. pool swfcalib
    - using restart
    - look at results swfcalib to choose new priors
        - make a report of the calib tests
    - still 3 waves?


## Tests to run

- Get data from NYC and calibrate that using our ATL values as default
- Make a "bad default" parameters set to see how it behaves for the recalib
- Do calibration from a non restarted model, to evaluate the effect of burnin
- Try to add a 4th race on top of the current model and see how it goes (boston)
- Check what the effect of the restart pool are
    - also of the non restart
    - check if iterative restart we can reduced the burnin times (probably
      different for each wave)
