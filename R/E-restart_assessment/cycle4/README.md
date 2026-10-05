# Cycle 4: runs restarted from a pool of 32 stationary states

This cycle analyses `data/run/variance/df__variance_long_pool.rds`:
256 × 600-year runs restarted, with `randomize.restart = TRUE`, from a pool
of 32 states. The states are the final (year-600) states of cold-start runs
1–32 of cycle 3 (batches 1–4).

This is the nested experiment that cycles 1–2 recommended. It gives:

- **direct ICCs** averaged over the stationary law, including memory the
  lower bounds cannot see;
- a **same-parameter restart check**;
- a **test of cycle 3's network explanation**.

Cycles 1–3 are read-only. Cycle 4 writes only here and to
`data/run/restart_assessment/cycle4/`.

**Start with:** [`results/SUMMARY_cycle4.md`](results/SUMMARY_cycle4.md).
It includes an erratum for cycle 3.

## Questions

1. Where do the points come from, how many runs start from each, and what
   do they carry (parameters, network coefficients)?
2. Is a same-parameter restart seamless, and do the runs keep the
   cold-start runs' stationary law?
3. What share of the variance does a restart state fix, measured directly?
   How much more is it than the lower bounds?
4. How long does one same-parameter point need to reach full variance?
5. How many points, how many runs per point, and which assignment?

## Steps

| Script | Question | Report |
|---|---|---|
| `c4_01_prepare.R` | Provenance, points, runs per point, network coefficients, annual and seam data | [c4_01](results/c4_01_prepare.md) |
| `c4_02_validate.R` | Nested-design estimators on synthetic data with the same design | [c4_02](results/c4_02_validate.md) |
| `c4_03_restart_law.R` | Weekly and one-year continuity at the restart; π_pool vs π_cold and π_x0 | [c4_03](results/c4_03_restart_law.md) |
| `c4_04_icc_direct.R` | Direct ICC for values and windows; vs lower bounds; one-point burn-in | [c4_04](results/c4_04_icc_direct.md) |
| `c4_05_pool_design.R` | The realised pool; points needed; balanced vs random assignment; burn-in by k | [c4_05](results/c4_05_pool_design.md) |

**Supporting files:**

- `c4_config.R`: sources the cycle 1–3 configurations;
- `c4_utils.R`: nested ANOVA, point bootstrap, pool formulas;
- [`results/c4_METHODS.md`](results/c4_METHODS.md): definitions C4-M0 to
  C4-M4.

## How to run

From the project root, after cycles 1 and 3, whose annual data and tables
it reads:

```bash
Rscript R/E-restart_assessment/cycle4/run_all_c4.R   # ~7 min on 12 cores, < 6 GB RAM
```

`c4_01` reads the weekly pool data and the weekly cold-start data (2 GB
each, one after the other), the pool restart file and the workflow maps.
Every later step reads only the annual file and earlier tables.

## Project conventions observed

The same as cycles 1–3. No package was installed.

## Decision log

| Date | Decision | Reason | Confirmed by user |
|---|---|---|---|
| 2026-09-27 | Cycle 4 in `R/E-restart_assessment/cycle4/`, intermediates in `data/run/restart_assessment/cycle4/` | same layout as cycles 2–3 | no |
| 2026-09-27 | Points identified from each run's first row, as the user suggested; sources matched to the last rows of cold-start runs 1–32 | the design is recorded nowhere else | no |
| 2026-09-27 | Main estimator `icc_w` = 1 − within-point variance / v_π; the ANOVA ICC as a check only | the ANOVA ICC fails validation with 32 points (c4_02) | no |
| 2026-09-27 | v_π from the pool runs' own years ≥ 300 | π_pool = π_cold (c4_03) | no |
| 2026-09-27 | Window burn-ins up to 150 years | burn-in times for windows were not determined with B ≤ 60 | no |
| 2026-09-27 | Erratum on cycle 3's network inference, recorded in cycle 4; cycle 3 files untouched | as for cycle 2's errata on cycle 1 | no |
