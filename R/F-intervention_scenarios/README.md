# Intervention Scenarios

## Goal

In this step we restar the model with scenarios. We leverage the [scenario API](https://cran.r-project.org/web/packages/EpiModel/vignettes/model-parameters.html)

## The scripts

- **1-scenarios.R**: Run simulation scenarios locally to familiarize with the API.

## What to edit

This step is meant for exploration. It is suggested that you duplicate the script and play with the copy. Keep the original one as template.

## On the HPC

The `workflow-scenarios.R` file create the `slurmworkflow` workflow to run the scenarios on a larger scale on the HPC. This step requires the estimation files to be present on the HPC. (i.e. having run the `workflow-estimation` on the HPC before).
