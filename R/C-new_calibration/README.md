# New Calibration

Goal of this document is to plan the format of the new Calibration process using
GPs + solver to get to the final values with few simulations

## Main Idea

- keep the wave approach to use the knowledge of how targets relate
- use GP surrogates to map inputs to outputs
- `optim` or `uniroot` to find the best value as understood by the GPs
- (ideally) fit GPs from a single batch per wave
- refine the calibration by re-running every waves (instead of multiple batches
  per wave)

## Description of a calibration from scratch

Here we assume that we have bad default values for the parameters

- do STIs first just to get the model running with non extinct STIs
- then the normal waves (prep, dx, supp, STIs, HIV prev/incid, ...)
- run a validation batch - at this point I assume an OK ballpark (need check)
- redo the waves to refine, with smaller search range?
    - for this I need a way to extrapolate the new range from:
        - the previous calibration of this target
        - the value of this output while I calibrated the previous waves
- Hopefully at this point the calibration is done and no logic for validation is
  actually needed.

## Specific problems

- not all waves require the same amount of sims
- not all waves require the same burnin period

For both I can either make it variable, or I can use the biggest value for all
waves. The former is more economical and clean but the second is easier to
implement with the current `swfcalib`

## Implementation Options

### Full bespoke approach

Code a workflow that does all the steps. At the end, evaluate it and restart it
manually.

Allow variable burnin time and reps. Make each step / wave simpler as I can tune
them directly.

A bit labor intensive, not flexible.

Can be a good first step

### `swfcalib` approach

Use the biggest number everywhere and re-run it once done.

Wasteful but probably easy to set-up

### Update the tools

Use the bespoke approach to list the new needs and update `swfcalib` (massively)
to make it able to run it

## Tests to run

- Get data from NYC and calibrate that using our ATL values as default
- Make a "bad default" parameters set to see how it behaves for the recalib
- Do calibration from a non restarted model, to evaluate the effect of burnin
- Try to add a 4th race on top of the current model and see how it goes (boston)
- Check what the effect of the restart pool are
    - also of the non restart
    - check if iterative restart we can reduced the burnin times (probably
      different for each wave)
