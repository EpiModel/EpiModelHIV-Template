# Cycle 3: the cold-start runs

Cycles 1 and 2 (`../`, `../cycle2/`) analysed 256 × 600-year runs
restarted from one state x0. Cycle 3 analyses the matching experiment from
a **cold start**: `data/run/variance/df__variance_long_x0.rds`, made by
`R/C-new_calibration/workflow-variance.R` from `path_to_est`. This is the
cold-start → equilibrium question that the original brief
(`restart_assessment_phaseA_brief.md`, Q2) asked for and cycle 1 could not
answer.

Cycles 1–2 are read **read-only**. Cycle 3 writes only here and to
`data/run/restart_assessment/cycle3/`.

**Start with:** [`results/SUMMARY_cycle3.md`](results/SUMMARY_cycle3.md).

## Questions

1. Where do the runs come from? Are they the same model as the x0 runs?
2. Do they reach a stationary law, and is it the law of the x0 runs?
3. How long after a cold start are the mean and the variance stationary
   ($T_{\text{cold}}$)? Is the 70-year burn-in enough, and how large is the
   residual bias at year 70 against the Monte Carlo error?
4. What does that mean for the workflow? That is, for the ballpark
   calibration (targets read after 70 years from a cold start), for restart
   pools taken at year 70 of cold-start runs, and for the research outcomes
   of runs started from them. How does it compare with a restart from x0?
5. Do the independent cold-start runs reproduce the equilibrium time
   structure and the restart-memory bounds of cycles 1–2?

## Steps

| Script | Question | Report |
|---|---|---|
| `c3_01_prepare.R` | Provenance (netsim inputs, parameters, code, network coefficients), the cold-start state, annual data | [c3_01](results/c3_01_prepare.md) |
| `c3_02_validate.R` | Estimators on synthetic cold starts (overshoot, over-dispersion) and the same-law tests | [c3_02](results/c3_02_validate.md) |
| `c3_03_same_law.R` | Stationarity; π_cold vs π_x0; calibration targets | [c3_03](results/c3_03_same_law.md) |
| `c3_04_cold_start.R` | $T_{\text{cold}}$, residual bias at year 70, comparison with x0 | [c3_04](results/c3_04_cold_start.md) |
| `c3_05_workflow.R` | Ballpark calibration; research outcomes from states of age B; cold start vs x0 | [c3_05](results/c3_05_workflow.md) |
| `c3_06_replication.R` | τ_int, variance split and ICC lower bounds, both experiments on the same years | [c3_06](results/c3_06_replication.md) |

**Supporting files:**

- `c3_config.R`: cycle 3 settings. It sources the cycle 1 and 2
  configurations.
- `c3_utils.R`: new functions: annualisation with the initialisation step,
  cold-start relaxation fits with a tail window, permutation and energy
  tests with chain blocks, window functionals.
- [`results/c3_METHODS.md`](results/c3_METHODS.md): definitions C3-M0 to
  C3-M4.

## How to run

From the project root, after cycle 1 (it needs `01_annual.rds` and the
cycle 1 tables):

```bash
Rscript R/E-restart_assessment/cycle3/run_all_c3.R   # ~25 min on 12 cores, < 6 GB RAM
```

- `c3_01` reads the weekly cold-start data (2 GB in memory) once.
- `c3_01` also reads `workflows/variance_assess_raw/` and the restart files
  in `data/run/estimates/`, and it runs `git` for the provenance tables.
  This works in the project repository with the EpiModelHIV-p clone in
  `../EpiModelHIV-p`.
- Every later step reads only the annual files and earlier tables.

## Project conventions observed

These are the same as cycles 1–2:

- numbered top-level scripts, run from the project root in a fresh session;
- paths from `R/shared_variables.R`;
- `library()` + `dplyr` + `ggplot2` (`theme_light`);
- section headers `# Title ----`;
- lines of at most 80 columns;
- intermediates under `data/run/`, which is git-ignored.

No package was installed.

## Decision log

| Date | Decision | Reason | Confirmed by user |
|---|---|---|---|
| 2026-09-26 | Cycle 3 in `R/E-restart_assessment/cycle3/`, intermediates in `data/run/restart_assessment/cycle3/` | same layout as cycle 2 | no |
| 2026-09-26 | Keep all 256 chains | no extinction in the cold-start runs (c3_01) | no |
| 2026-09-26 | Year k = steps (k − 1)·52 + 1 … k·52; year-1 flows rescaled from 51 to 52 weeks | step 1 is the initialisation and records only `num` | no |
| 2026-09-26 | Each experiment against its own π; no pooling of levels | π_cold ≠ π_x0 (c3_03) | no |
| 2026-09-26 | Mean fits over a tail window (\|offset\| ≤ 3 SD for good) | the first decades are a nonlinear overshoot; validated in c3_02 | no |
| 2026-09-26 | `EQ_START_C3` = 240 | c3_04 rule: slowest key/state time at 0.1 / 10% (190 y, a Hispanic-population variance overshoot) rounded up to 10, + 50 | no |
| 2026-09-26 | The HPC `netest-hpc.rds` is inferred, not read | it is not available locally; see c3_01 for the check to run on the HPC | no |
| 2026-09-26 | No new simulations | analysis of existing output only, as in cycles 1–2 | no |
