# Networks Estimation

## Introduction

In this section we estimate and diagnose the [ERGMs](link?) used by the
epidemic model.

## Scripts description

- **1-estimations.R**: Initialize and run the estimation process for the
  3 networks
- **2-diagnostics.R**: Run the diagnostics on all 3 networks and save the
  results for later assessments
- **3-assess.R**: Examine the output of the diagnostics.
- `initialize.R`: scripts setup the networks and `ARTnet` objects.
- `model_*.R`: defines and fit the main, casual and one-off models.
- `diag_*.R`: diagnostics are similarly defined within theses  scripts.
- `z-context.R`: sets the size of the networks as well as the estimation
  methods differentially for HPC and local context.
- **workflow-networks.R**: create the workflow to run all the steps on the HPC.

## What to edit

The `initialize.R`, `model_*.R` and `diag_*.R` scripts should be modified if
different parameterizations are required.

The network sizes are set in the `z-context.R` scripts. Avoid going above 10k
nodes for the local networks as the estimation and run of the models get very
long.

## On the HPC

The **workflow-networks.R** file create the `slurmworkflow` workflow to estimate
the full sized networks on the HPC and run the diagnostics associated with them.
