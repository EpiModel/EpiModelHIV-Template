# Intervention Scenarios

## Introduction

In this chapter the model has been calibrated and we focus on defining the
actual research scenarios and then process the simulations to make tables and
plots.

## Scripts descriptions


- **1-debug_modules.R**: Similarly to chapter B, run the model with your custom
  `EpiModeHIV-p@applied_proj`. But this time with the calibrated parameters.
- **2-scenarios_run.R**: Run simulation scenarios locally to get a few results
  to start implementing the output pipeline.
- **3-process_tables.R**: Create a formatted table out of the simulations.
- **4-process_plots.R**: Create plots out of the simulations.
- `labels.R`: Utilities to rename and format the outcomes.
- `outcomes.R`: Utilities to create the outcomes of interest out of the raw
simulations.
- **workflow-intervention.R**: Create the workflow to run the simulations and
process the outcomes.

## What to edit

Most of the scripts in this step are to be modified as they are the heart of
your project. The scenarios and processing are unique to your analysis. Use the
code already there as a scaffold for your own.

## On the HPC

The `workflow-intervention.R` file creates the `slurmworkflow` workflow to run
the intervention scenarios on the HPC. This requires the estimation files and a
calibrated restart point to be present on the HPC (i.e. having completed
chapters A and C first).

## Common mistakes

The simulations will always be saved in the same directory, here
`data/run/scenarios/`. If you forget to clear it before running a new
set of simulation you may get weird results.

On the HPC you would clear it by running `rm -rf data/run/scenarios/*`.
Beware though, this command will not ask confirmation. So make sure you do not
need any of it before removing it.
