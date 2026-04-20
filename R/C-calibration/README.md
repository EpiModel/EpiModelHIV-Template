# Calibration

## Introduction

In this chapter we calibrate the model. This is a technical step and most users
will not perform the calibration themselves. The rest of this document is aimed
at the person in charge of calibration.

The calibration aims to make the model fit a set of *targets* (defined in the
`EpiModelHIV` package via `get_calibration_targets()`) by modifying input
parameters. The core loop is always the same:

1. Run the model with a set of parameters
2. Assess how close the model is to the targets
3. Propose a new set of parameters
4. Repeat until calibrated

The calibration proceeds in three phases described below.

## Phase 1: Ballpark Calibration (manual)

**Goal:** Get all STI epidemics present and all targets in the right order of
magnitude.

**Workflow:** `workflow-ballpark_calib.R` (HPC) or `1-ballpark_calib.R` (local)

The model is run from scratch (step 1 to `calibration_end`) with a grid of
parameter multipliers across several scenarios. After the run:

- `process_calibs.R` produces `calib_assess.csv` — mean percent deviation from
  each target, scaled by target value.
- Download this file and use `2-manual_calib_assess.R` to visually inspect
  calibration target trajectories.
- Manually adjust the multipliers and re-run until the model is roughly
  calibrated.

## Phase 2: Restart Point

**Goal:** Create a checkpoint so that subsequent calibration and intervention
runs skip the burn-in period. At this stage we don't need the "best" restart
point — just one where no STI epidemic has gone extinct and the population has
moved past its initial synthetic state.

**Workflow:** `3-choose_restart.R` (reuses existing simulations)

No new simulations are needed — the restart point is picked from the results
of the best Phase 1 calibration scenario. `3-choose_restart.R` lets you choose
which scenario's merged tibble to work from, then:

1. Evaluates each simulation against targets (sum of squared errors),
   disqualifying any sim where an STI incidence drops below 25% of its target.
2. A suitable simulation's end-state is saved as the restart point to
   `path_to_restart` (i.e. `data/run/estimates/restart-{context}.rds`).

A restart point is needed for **both** contexts (local and HPC) so that
Chapters B and D scripts can start from it.

All subsequent runs use `reinit_msm` to start from this checkpoint.

## Phase 3: Fine-Tuning

Starting from the restart point, two approaches are available and are used in
sequence: first manual calibration to verify the restart point works and improve
it (re-creating a restart point is cheap), then swfcalib to precisely converge
on the targets.

### Manual (`workflow-restart_calib.R`)

Same manual loop as Phase 1 but starting from the restart point (step 2 to
`calibration_end`). The runtime is similar but the results are more stable
because the population is "simulation-born" rather than completely synthetic.
Use `2-manual_calib_assess.R` and `calib_assess.csv` to evaluate. When better
parameters are found, re-run Phase 2 to produce an updated restart point
before moving to swfcalib.

### Automated via swfcalib (`workflow-swfcalib.R`)

Uses `swfcalib_config.R` to define a wave-based sequential optimization. Waves
run in order (later parameters depend on earlier ones being correct); jobs
within a wave run in parallel.

| Wave | Targets | Parameters | Rationale |
|------|---------|------------|-----------|
| 1 | `cc.prep.{B,H,W}` | `prep.start.rate_{1,2,3}` | PrEP coverage by race |
| 2 | `cc.dx.{B,H,W}` | `hiv.test.rate_{1,2,3}` | HIV diagnosis rates |
| 3 | `cc.vsupp.{B,H,W}` | `tx.halt.rate_{1,2,3}` | Viral suppression (joint) |
| 4 | `ir100.{gono,chla,syph}` | `{gono,chla,syph}.*prob` | STI incidence rates |
| 5 | `i.prev.dx.{B,H,W}` | `hiv.trans.scale_{1,2,3}` | HIV prevalence (joint) |
| 6 | `disease.mr100` | `aids.off.tx.mort.rate` | Disease mortality |
| 7 | `num` | `a.rate` | Population size (~100k) |

The wave ordering encodes causal dependencies: the care cascade (PrEP →
testing → suppression) must be correct before tuning transmission outcomes.

Care-cascade targets use a **shrink proposer** (halving the range each
iteration) with polynomial convergence checks. Noisier epidemiological targets
(STIs, HIV prevalence) use a **SE-range proposer** (retaining top 30%) with
absolute threshold convergence.

After convergence, `update_param.R` writes calibrated values to `params.csv`.

See [the swfcalib vignette](https://epimodel.github.io/swfcalib/articles/swfcalib.html)
for details on the package.

### Final restart point (`workflow-3-restart_point.R`)

After swfcalib converges, `workflow-3-restart_point.R` runs many reps (256)
with the calibrated parameters, picks the definitive restart point via
`3-choose_restart.R`, and produces the calibration plots. This is the restart
point used by Chapter D for intervention runs.

## Outputs

This chapter produces two artifacts consumed by the rest of the project:

- **`data/run/estimates/restart-{context}.rds`** — The restart point checkpoint.
  Used by Chapter D (`D-interventions`) as the starting state for intervention
  runs, and by `B-model_dev/2-debug_modules.R` for post-calibration module
  development. Both local and HPC versions are needed.
- **`data/input/model_parameters.csv`** (updated) — When using swfcalib,
  `update_param.R` writes the calibrated parameter values back to this file so
  they become the new defaults for all subsequent runs.

## Post-Calibration

- `4-swfcalib_assess.R` — Interactive assessment of swfcalib results.
- `5-calibration_report.R` — Renders a calibration report from `Rmd/calibration_values.Rmd`.

## File Reference

| File | Role |
|------|------|
| `1-ballpark_calib.R` | Run ballpark calibration scenarios locally |
| `2-manual_calib_assess.R` | Visual assessment of calibration results |
| `3-choose_restart.R` | Pick best simulation for restart point |
| `4-swfcalib_assess.R` | Assess swfcalib results interactively |
| `5-calibration_report.R` | Render calibration report |
| `process_calibs.R` | Generate `calib_assess.csv` summary |
| `swfcalib_config.R` | Wave definitions and priors for swfcalib |
| `swfcalib_model.R` | Model function passed to swfcalib |
| `update_param.R` | Write calibrated params back to CSV |
| `utils-calib_plots.R` | Plotting helpers for calibration targets |
| `utils-restart.R` | Helper to create restart point from a sim |
| `workflow-ballpark_calib.R` | HPC workflow: ballpark calibration (Phase 1) |
| `workflow-restart_calib.R` | HPC workflow: manual fine-tuning from restart (Phase 3) |
| `workflow-3-restart_point.R` | HPC workflow: create restart checkpoint |
| `workflow-swfcalib.R` | HPC workflow: automated swfcalib calibration |
| `z-context.R` | Local/HPC context switch |
