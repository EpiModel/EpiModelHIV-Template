# Intervention Scenarios

## Introduction

In this step we run the model locally from the restart point with scenarios. We
leverage the [scenario API](https://cran.r-project.org/web/packages/EpiModel/vignettes/model-parameters.html)
and then process the simulations to make tables and plots.

## Scripts descriptions


- **0-make_scenarios.R**: Create a `scenarios.csv` files from code.
- **1-scenarios.R**: Run simulation scenarios locally .
- **2-process_tables.R**: Create a formatted table out of the simulations.
- **3-process_plots.R**: Create plots out of the simulations.
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

The `workflow-scenarios.R` file create the `slurmworkflow` workflow to run the scenarios on a larger scale on the HPC. This step requires the estimation files to be present on the HPC. (i.e. having run the `workflow-estimation` on the HPC before).

## Common mistakes

The simulations will always be saved in the same directory, here
`data/intermediate/scenarios/`. If you forget to clear it before running a new
set of simulation you may get weird results.

On the HPC you would clear it by running `rm -rf data/intermediate/scenarios/*`.
Beware though, this command will not ask confirmation. So make sure you do not
need any of it before removing it.
