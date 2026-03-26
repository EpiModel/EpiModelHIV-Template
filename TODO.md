# TODO

- add a set of instruction for when I hand the calibration results
    - where do files go
    - what to do with alg_calib
    - hpc + local files
    - update hpc configs
- validate email in hpc_config and warning if not correct?
    - make a validator that forces the user to interact?
    - usethis style? ask questions?

## Huge analysis of all processes

- make many (many) outcomes
-

## New acts list:

Do I have parity?
- check in with claude?
- run many tests on HPC - many outcomes idea

## Reorganising Template

1. network Estimation
    - don't touch
2. EpiModel Construction
    - Back and forth of running and updating the model
3. ModelCalibration
4. Intervention runs
    - Model is defined and Calibrated
        - no changes in HIVp at this point
    - Define Intervention and Run them
5. Results Analysis
    - Process the outcomes
    - Make tables and plots

## Difficulties

In practice, we often overlook what outcomes we need. So we often have to go
back to HIVp to add them.
If done well, this should not impeed calibration

## Workflow

1. Network Estimation is usually autonomous. Or at least we know that it needs
   to change early on.
2. Model Construction
    1. Define when the changes occur. Before or after calibration
    2. First implement the processes without "clean" `epis` use `dbg_` for
       example
    3. Test locally, purely to eval the process happenning
    4. Large Scales On HPC
2. In parallel: Interventions Construction
    - good scientific question
    - define useful outcomes (minimal set for later processing)
    - have skeleton tables and mock plots
    - processing function etc
3. Calibration
    - pre-requisit:
        - the "pre-intervention" model will not change
        - good targets
4. Actual runs
    - At this point everything would ideally be done
        - just run
        - get results
        - run processing
    - In practice: back & forth with previous steps
