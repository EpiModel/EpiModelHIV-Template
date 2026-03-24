# B — Model Development

## What this chapter does

This is where you develop and test your model. The work here is iterative: you
edit simulation modules in `EpiModelHIV-p@<applied_project>`, reload them here,
run a short simulation, inspect the results, and repeat until the model behaves
as expected.

This chapter does not produce any final output — it is a sandbox for
development and exploration. You will come back to it frequently throughout the
project.

For documentation on the EpiModel API (`param`, `init`, `control`, `netsim`),
see the [EpiModel documentation](https://epimodel.github.io/EpiModel/).

## Prerequisites

You must have completed **Chapter A** (network estimation) so that
`data/run/estimates/` contains the fitted network models.

## Scripts

| Script | What it does |
|---|---|
| **`1-netsim_run.R`** | Run a basic simulation with the installed package. Use this to get familiar with `netsim` and its output before making any changes. |
| **`2-debug_modules.R`** | Run a simulation with your local development version of `EpiModelHIV-p`. This is where you spend most of your time while modifying modules. |
| **`3-scenarios_run.R`** | Run parameter scenarios locally to test the scenario API. |
| **`4-scenarios_assess.R`** | Inspect scenario output (locally or downloaded from HPC). |
| **`workflow-scenarios.R`** | Generate the HPC workflow to run scenarios at full scale. |

## Workflow

### Getting familiar (once)

Start with **`1-netsim_run.R`**. It runs a short simulation using the installed
package and walks through the output formats (base R and tidyverse). Run it
section by section and make sure you understand the output before moving on.

### Developing modules (iterative)

Once you start editing modules in `EpiModelHIV-p`, switch to
**`2-debug_modules.R`**. The typical loop is:

1. Edit a module file in your `EpiModelHIV-p` clone (e.g., `R/mod.hiv.test.R`).
   The path to your clone is defined as `EMHIVp_dir` in `R/shared_variables.R`.
2. In this script, run `pkgload::load_all(EMHIVp_dir)` to reload your changes
3. Run `netsim()` and inspect the output
4. Repeat from step 1

**Important:** always use `ncores = 1` when working with `load_all()`. Parallel
workers load the *installed* package version, not your development code — so
with `ncores > 1`, only the main process would run your changes while workers
run the old code.

To step through a module line by line, use `debugonce(module_name)` before
calling `netsim()`. If you are new to debugging in R, see
[Hands-On Programming with R — Debugging](https://rstudio-education.github.io/hopr/debug.html).

### Testing scenarios (when the model is ready)

When your module changes are working, use **`3-scenarios_run.R`** to test
parameter scenarios — the same mechanism used for intervention runs in
Chapter D. This validates that the scenario API works with your changes before
scaling to the HPC.

Then use **`4-scenarios_assess.R`** to inspect the results.

### Scaling to HPC

Once satisfied locally, run **`workflow-scenarios.R`** to generate HPC jobs.
This runs more simulations with more replications for stable estimates.

See the [wiki](https://github.com/EpiModel/EpiModeling/wiki#slurmworkflow)
for how to submit and monitor workflows.

## What to edit

These scripts are templates — you can duplicate them and experiment with your
copies while keeping the originals as reference.

In particular, adapt the scenario definitions in `3-scenarios_run.R` and
`workflow-scenarios.R` to use the parameters relevant to your project.

## Common mistakes

| Mistake | Fix |
|---|---|
| Using `ncores > 1` with `load_all()` | Always `ncores = 1` during development |
| Old simulations mixed with new results | Delete `data/run/scenarios/` contents before a new run |
| Forgetting to reload after editing a module | Re-run `pkgload::load_all(EMHIVp_dir)` |
| Running scripts without restarting R | Always `Ctrl+Shift+F10` before a numbered script |
