# C4-01. The pool runs: provenance, design, annual data

## Question

How were the 256 pool runs made:

- which states are the restart points?
- how many runs start from each?
- which parameters and network coefficients do they carry?

Which annual dataset and which restart-continuity data do the later steps
use?

## Method

[c4_METHODS.md](c4_METHODS.md) C4-M0, C4-M1. Script: `c4_01_prepare.R`.

## Results

### How the runs were made

These are the `netsim` inputs of `workflows/variance_assess_pool/`
(`tables/c4_01_run_setup.csv`):

- a restart from `data/run/estimates/restart_pool.rds`, with `start` = 2 and
  `initialize.net`;
- 31,200 steps (600 years);
- `randomize.restart = TRUE`;
- 256 runs in 32 batches of 8.

**Parameters.** 82 of 82 `param` elements are identical to those of the
cold-start runs of cycle 3 (`tables/c4_01_param_compare.csv`).

### The restart points

The pool file has 32 points, each saved at step 31,200 of its source run
(`tables/c4_01_point_source.csv`).

- **They are the final states of cold-start runs 1–32.** Each point's saved
  row equals, on all 61 recorded variables, the last row of cold-start run
  j = 1…32 (batches 1–4 of `df__variance_long_x0.rds`).
- **They are stationary.** They are drawn 460 years after the end of the
  cold-start transient ($T_{\text{cold}}$ ≈ 100–130 years, c3_04), so they
  are 32 independent draws from π_cold.

**Runs per point** (`tables/c4_01_runs_per_point.csv`,
`tables/c4_01_design.csv`):

- `randomize.restart` gave 1 to 15 runs per point; point 16 has 1 run and
  points 8 and 9 have 15 each;
- $\sum_j n_j^2/N$ = 9.27, against 8 for a balanced design.

**Network coefficients** (`tables/c4_01_network_coefs.csv`). The offset
of the edges coefficient against the local `netest-hpc.rds` (C3-M0):

| restart file | main | casual | one-off |
|---|---|---|---|
| this pool (32 points, 2026-09-27) | 0 (\|offset\| < 5 × 10⁻¹³) | 0 | 0 |
| x0 of cycles 1–2 (`restart-hpc.rds`) | −0.0111 | −0.0111 | −0.0111 |
| September pool (62 points, 2026-09-21), from cycle 3 | −0.0147 | −0.0870 | +0.1004 |

### The data

- **Shape.** 7,987,200 rows × 65 columns, 2 GB: 256 runs × 31,200 steps
  (time 2–31,201), with the variables of the cold-start file and no missing
  value (`logs/c4_01.log`).
- **No extinction** (`tables/c4_01_extinctions_year.csv` is empty). All 256
  runs are kept.
- **Annual dataset** (`data/run/restart_assessment/cycle4/c4_01_annual_pool.rds`,
  124 MB). It holds the cycle 3 variables and dictionary, the point of each
  run, the first simulated year of each run (steps 3–54), and the weekly
  data of weeks −104…104 around the restart for continuity checks.

Figures:

- `figures/c4_01_key_600y.png`: 10 runs, the mean and the 5–95% band, with
  π_cold dashed;
- `figures/c4_01_same_point_runs.png`: every run of the 6 most-used points,
  over 100 years.

## Interpretation

1. **This is the nested experiment that cycles 1–2 asked for,** at a
   larger scale: 32 stationary same-parameter points × 1–15 runs × 600
   years, against the suggested ~8 × ~16 × 40.
2. **The cold-start runs used the local network estimate.**
   - The pool is made of their final states, and every point carries
     exactly the local `netest` coefficients adjusted for its population
     size.
   - Cycle 3 had inferred the opposite from the September pool, whose
     network-specific offsets must have come from the ballpark
     calibration runs it was built from.
   - The erratum is in [SUMMARY_cycle4.md](SUMMARY_cycle4.md).
3. **The pool is consistent with its runs.** It has the same parameters and
   network coefficients, and `num.elig` is saved, so `edges_correct()`
   continues without a jump. Any difference between the pool runs and the
   cold-start runs would therefore come from the restart mechanism itself.
   c4_03 tests this.
4. **How runs from one state spread.** For prevalence, runs from the same
   state stay together for decades and fan out over 30–50 years. For
   incidence they are mixed within a few years
   (`figures/c4_01_same_point_runs.png`).

## Decision / input for next steps

- **c4_03–c4_05** use the annual file, the points and the seam data.
- **One set of 32 points.** The estimates of the pool's own imprint (c4_05)
  refer to this particular pool.

## Caveats and deviations

- **The September pool is gone.** `restart_pool.rds` was overwritten on
  2026-09-27. Cycle 3's table of network coefficients for the September
  pool therefore cannot be reproduced: re-running `c3_01` would read the
  new pool under the old label. The cycle 3 table remains the record.
- **Unbalanced design.** With `randomize.restart` the design is unbalanced,
  and one point has a single run. It contributes to the between-point
  variance only.
