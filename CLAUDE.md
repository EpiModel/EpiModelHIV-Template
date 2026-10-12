# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is an **EpiModelHIV applied project** (from the EpiModelHIV-Template). It contains R scripts for network estimation, model development, calibration, and intervention analysis using the `EpiModelHIV` package. The simulation modules live in the project's branch of EpiModelHIV-p, cloned locally at the path set by `EPIMODELHIV_DIR` in the project `.Renviron` (see the `CLAUDE.md` in that clone for the package architecture).

## Environment and Setup

Uses `renv` for R package management. `R/00-setup.R` sets up the project library from `renv.lock`; `renv.lock.hpc` is the smaller lockfile restored on the HPC (R 4.5 via spack, see `R/hpc_configs.R`). The project `.Renviron` sets `EPIMODELHIV_DIR`, `HPC_MAIL_USER`, and `GITHUB_PAT`.

```bash
# Restore R packages (from the project root)
Rscript -e 'renv::restore()'

# Install/update EpiModelHIV-p from GitHub (branch: `EMHIVp_branch` in R/shared_variables.R)
Rscript -e 'renv::install("EpiModel/EpiModelHIV-p@v4.0.x")'
```

```r
# Quick-reload the local EpiModelHIV-p clone during development (defined in .Rprofile)
load_local_EpiModelHIV()
```

**Important:** When using `load_local_EpiModelHIV()` (a wrapper around `pkgload::load_all()`), always run with `ncores = 1` in `control_msm()`. Parallel workers load the installed package version, not the dev version.

## Code Conventions

- Do not use `call. = FALSE` in `stop()` or `warning()` calls. Keep the call context in error messages so the originating function stays visible in traces.

## Script Conventions

### Script types
- **Numbered scripts** (`1-estimation.R`, `2-diagnostics.R`): Top-level scripts meant to be run in a fresh R session (`Ctrl+Shift+F10` in RStudio). Run in order within each chapter.
- **`workflow-*.R`**: Run locally to generate SLURM HPC job pipelines via `slurmworkflow`; the jobs themselves run on the HPC.
- **`z-context.R`**: Per-chapter context switch — sets `context` to `"local"` or `"hpc"` and adjusts sizes/cores accordingly. Set `hpc_context <- TRUE` before sourcing to use HPC settings.
- **`z-test.R`**: Scratch file for ad-hoc testing.
- **All other scripts** (no number prefix): Utilities sourced by numbered scripts. Never run directly.

### Shared configuration
Every top-level script starts by sourcing `R/shared_variables.R` which defines:
- `EMHIVp_branch`: EpiModelHIV-p branch (the local clone path is `EPIMODELHIV_DIR` in `.Renviron`)
- `time_unit`, `year_steps`: Time step duration (7 days) and steps per year (52)
- Key time points: `prep_start`, `calibration_end`, `restart_time`, `intervention_start`, `intervention_end`
- All data paths: `input_dir`, `run_dir`, `output_dir`, and subdirectories

Modify shared values only in `shared_variables.R` — never redefine them in individual scripts.

## Project Chapters (R/ subdirectories)

### A-networks — Network Estimation
Estimate 3 TERGM network models (main, casual, one-off) from ARTnet data. Outputs saved to `data/run/estimates/`.
- `initialize.R` → `model_main.R` → `model_casl.R` → `model_ooff.R` (sourced by `1-estimation.R`)
- `diag_main.R`, `diag_casl.R`, `diag_ooff.R` (sourced by `2-diagnostics.R`)
- Local: 10k nodes; HPC: 100k nodes

### B-model_dev — Model Development
Run `netsim` simulations and debug EpiModelHIV modules interactively.
- `1-netsim_run.R`: Run with installed package, explore output
- `2-debug_modules.R`: Run with `load_local_EpiModelHIV()` for active module development
- `3-scenarios_run.R` / `4-scenarios_assess.R`: Test the scenario API locally

### C-calibration — Model Calibration
Fit model parameters to epidemiological targets. Two approaches:
- **Manual**: Run scenarios, download `calib_assess.csv`, adjust parameters, repeat
- **Automated**: `swfcalib` package for systematic calibration
- `3-choose_restart.R`: Picks a simulation and saves it as the restart point (checkpoint) for later calibration and intervention runs
- `workflow-restart_point.R`: HPC workflow that runs 500 replications with the current parameters and saves the best as the restart point; rerun it after calibration and whenever attributes or parameters change

### D-interventions — Intervention Scenarios
Run calibrated model with intervention scenarios and process results.
- `make_scenarios.R`: Define scenario tibbles
- `outcomes.R`: Extract outcomes from raw simulations
- `labels.R`: Rename/format for publication
- `3-process_tables.R` / `4-process_plots.R`: Generate tables and plots

## Data Directories

- `data/input/`: `model_parameters.csv` (project overrides of the EpiModelHIV parameter defaults, merged by `read_model_params()` in `R/netsim_settings.R`; a row for a parameter the package does not have is an error), scenarios (git-tracked)
- `data/run/` — Estimates, diagnostics, calibration, scenario outputs (NOT git-tracked)
- `data/output/` — Final tables/plots for publication (NOT git-tracked)

The `.Rprofile` auto-creates the directory structure on session start.

## Common Workflow: Developing a New Module

1. Edit module code in `R/mod.*.R` of the EpiModelHIV-p clone (`EPIMODELHIV_DIR`)
2. Open `R/B-model_dev/2-debug_modules.R` (or `R/D-interventions/1-debug_modules.R` post-calibration)
3. `load_local_EpiModelHIV()` to reload
4. Run `netsim()` with `ncores = 1`
5. Use `debugonce(module_name)` or `browser()` in module code for debugging

## HPC Workflow

1. Push changes to GitHub (both this repo and EpiModelHIV-p)
2. Run the appropriate `workflow-*.R` script to generate SLURM jobs in `workflows/`
3. Delete old workflow dirs locally AND on HPC before recreating with the same name
4. `hpc_configs.R` defines `make_em_workflow()` which handles renv snapshot and SLURM setup. It reads the local git branch, and the HPC clone must be on the same branch
5. `renv.lock.hpc` is a minimal lockfile for HPC (only simulation packages, no analysis packages)
