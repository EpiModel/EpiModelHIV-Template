# Model Development

## Introduction

In this chapter we run the model to get familiar with `netsim` and the APIs it
exposes. It is also here that the work on new *EpiModelHIV* modules will be
carried out.

## Scripts descriptions

- **1-netsim_run.R**: Run the simulation with the installed `EpiModelHIV`
  package and explore the output.
- **2-debug_modules.R**: Run the model with your custom
  `EpiModeHIV-p@applied_proj` (i.e. the files on your computer not yet pushed to
  GitHub). This file will be where you spend most of you time while modifying
  `EpiModeHIV` modules.
- **3-scenarios_run.R**: Run simulation scenarios locally to familiarize with the
  [scenario API](https://cran.r-project.org/web/packages/EpiModel/vignettes/model-parameters.html)
- **4-scenarios_assess.R**: Interact with the outputs of the scenarios in the
  same format they will be on the HPC.
- **workflow-scenarios.R**: Once your modules are updated, this workflow will
  help you get familiar with running simulations on the HPC.

## What to edit

This step is meant for exploration. It is suggested that you duplicate the
script and play with the copy. Keep the original ones as templates.

Try to make scenarios with the parameters you intend to use in your
interventions later on. And see if the modifications reflect in the outcomes.

## On the HPC

The `workflow-scenarios.R` file create the `slurmworkflow` workflow to run the
scenarios on a larger scale on the HPC. This step requires the estimation files
to be present on the HPC. (i.e. having run the `workflow-estimation` on the HPC
before).

Once the scenarios are finished on the HPC, you can download the content of
`data/run/scenarios/merged_tibbles/` from the HPC and use the script
`4-scenarios_assess.R` to interact with them.

## Common mistakes

The simulations will always be saved in the same directory, here
`data/run/scenarios/`. If you forget to clear it before running a new
set of simulation you may get weird results.

On the HPC you would clear it by running `rm -rf data/run/scenarios/*`.
Beware though, this command will not ask confirmation. So make sure you do not
need any of it before removing it.
