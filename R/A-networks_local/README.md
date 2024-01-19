# Networks Estimation

## Goal

In this step we estimate and diagnose the ERGMs used by the epidemic model.

## The scripts

1-estimations.R: Run the estimation process for the 3 networks
2-diagnostics.R: Run the diagnostics on all 3 networks
3-assess.R: Examine the output of the diagnostics

The models themselves are defined in the `main_model.R`, `casl_model.R` and
`ooff_model.R` files for the main, casual and one-off models respectively. The
diagnostics are similarly defined with the `_diag.R` files.

## On the HPC

The `workflow_networks.R` file create the `slurmworkflow` workflow to estimate
the full sized networks on the HPC and run the diagnostics associated with them.

## What to edit

- `_model.R` scripts
- `_diag.R` scripts accordingly
