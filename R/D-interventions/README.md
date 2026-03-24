# D — Intervention Scenarios

## What this chapter does

This is where the research question is answered. The model has been calibrated
(Chapter C) and we now run it under different intervention scenarios to measure
their impact on HIV/STI outcomes.

The pipeline is:

```
Define scenarios → Run simulations → Extract outcomes → Format tables & plots
```

Unlike Chapter B (which is a sandbox), this chapter produces the **final
results** for publication.

## Prerequisites

- **Chapter A** completed — network estimates in `data/run/estimates/`
- **Chapter B** completed — model development finalized (no more changes to
  pre-intervention simulation logic)
- **Chapter C** completed — calibrated restart point in
  `data/run/estimates/restart-{context}.rds`

The restart point is a saved simulation state from the end of the calibration
period. Intervention runs start from this point instead of re-simulating the
entire burn-in, which saves significant compute time.

## Scripts

| Script | What it does |
|---|---|
| **`1-debug_modules.R`** | Test modules post-calibration using the restart point. Same as Chapter B's debug script but with calibrated parameters. |
| **`2-scenarios_run.R`** | Run intervention scenarios locally. |
| **`3-process_tables.R`** | Compute outcome summaries and format as a publication table. |
| **`4-process_plots.R`** | Generate plots from scenario outcomes. |
| **`workflow-intervention.R`** | Generate the HPC workflow for full-scale runs. |

Utility scripts (sourced, never run directly):

| Script | Role |
|---|---|
| `make_scenarios.R` | Define the intervention scenario grid and write `data/input/scenarios.csv` |
| `outcomes.R` | Extract and compute outcomes (incidence, NIA, PIA) from raw simulations |
| `labels.R` | Map variable names to publication labels and number formats |
| `z-context.R` | Local vs. HPC context switch |

## Workflow

### 1. Define scenarios

Run **`make_scenarios.R`** to generate `data/input/scenarios.csv`. This file
defines a grid of intervention levels (e.g., testing rate x treatment rate at
different odds ratios). Edit the script to define the interventions relevant to
your research question.

### 2. Test locally

Run **`2-scenarios_run.R`** to execute a small number of replications locally.
This validates that scenarios run correctly and produces enough output to
develop the processing pipeline.

### 3. Build the output pipeline

This is where most of the customization happens. Edit:

- **`outcomes.R`** — define which outcomes to extract from raw simulations and
  how to compute derived measures (NIA, PIA). The provided code is an example;
  adapt it to your research question.
- **`labels.R`** — map outcome variable names to publication-ready labels and
  number formats (percentages, decimal places, etc.).
- **`3-process_tables.R`** and **`4-process_plots.R`** — use the outcomes and
  labels to produce final outputs. These scripts are scaffolds to be adapted.

### 4. Run on HPC

Once the pipeline works locally, run **`workflow-intervention.R`** to generate
HPC jobs with more replications for stable estimates. The HPC workflow runs all
four steps (simulate → merge → tables → plots) in sequence.

See the [wiki](https://github.com/EpiModel/EpiModeling/wiki#slurmworkflow)
for how to submit and monitor workflows.

## What to edit

This chapter is the heart of your project — most scripts are meant to be
modified. In particular:

- `make_scenarios.R` — your intervention design
- `outcomes.R` — your outcome measures
- `labels.R` — your publication formatting
- `3-process_tables.R` / `4-process_plots.R` — your table/plot specifications

Use the existing code as a scaffold and adapt it to your analysis.

## Common mistakes

| Mistake | Fix |
|---|---|
| Old simulations mixed with new results | Delete `data/run/scenarios/` contents before re-running |
| Baseline scenario name doesn't match `outcomes.R` | Update the `make_d_ref()` call in processing scripts |
| Restart point missing | Complete Chapter C first |
| Using `ncores > 1` with `load_all()` in debug script | Always `ncores = 1` during development |
