# Networks Estimation

## Goal

In this step we estimate and diagnose the ERGMs used by the epidemic model.

## The scripts

- **1-estimations.R**: Run the estimation process for the 3 networks
- **2-diagnostics.R**: Run the diagnostics on all 3 networks
- **3-assess.R**: Examine the output of the diagnostics
- `initialize.R`: scripts setup the networks and `ARTnet` objects.
- `model_*.R`: defines and fit the main, casual and one-off models.
- `diag_*.R`: diagnostics are similarly defined with the  scripts.

## What to edit

The `initialize.R`, `model_*.R` and `diag_*.R` scripts should be modified if
different parameterizations are required. The network sizes are set in the
`z-context.R` scripts. Avoid going above 10k nodes for the local networks.

## On the HPC

The `workflow-networks.R` file create the `slurmworkflow` workflow to estimate
the full sized networks on the HPC and run the diagnostics associated with them.

