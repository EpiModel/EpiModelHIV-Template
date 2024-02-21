# Netsim Scenarios

## Introduction

In this step we run the model with scenarios. We leverage the [scenario
API](https://cran.r-project.org/web/packages/EpiModel/vignettes/model-parameters.html)

## Scripts descriptions

- **1-scenarios.R**: Run simulation scenarios locally to familiarize with the
  API.
- **2-scenarios_assess.R**: Explore the output of the simulations
- **workflow-scenarios.R**: create the workflow to run all the steps on the HPC.

## What to edit

This step is meant for exploration. It is suggested that you duplicate the
script and play with the copy. Keep the original one as template.

Try to make scenarios with the parameters you intend to use in your
interventions later on. And see if the modifications reflect in the outcomes.

## On the HPC

The `workflow-scenarios.R` file create the `slurmworkflow` workflow to run the
scenarios on a larger scale on the HPC. This step requires the estimation files
to be present on the HPC. (i.e. having run the `workflow-estimation` on the HPC
before).

## Common mistakes

The simulations will always be saved in the same directory, here
`data/intermediate/scenarios/`. If you forget to clear it before running a new
set of simulation you may get weird results.

On the HPC you would clear it by running `rm -rf data/intermediate/scenarios/*`.
Beware though, this command will not ask confirmation. So make sure you do not
need any of it before removing it.
