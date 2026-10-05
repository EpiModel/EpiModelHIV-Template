# C4-03. Is a same-parameter restart seamless?

## Question

Cycle 2 could not tell whether the jumps seen after restarting from x0
came from the restart mechanism or from x0's other parameters (A3). It
recommended a same-parameter restart check. The pool runs are exactly that.

1. Do the runs restarted from the 32 saved states continue as their source
   chains would have, week by week and year by year?
2. Do they settle into the stationary law of the cold-start runs, and not
   into that of the x0 runs?

## Method

[c4_METHODS.md](c4_METHODS.md) C4-M3; same-law tests as c3_03 (C3-M2).
Script: `c4_03_restart_law.R`.

## Results

### Weekly continuity

`tables/c4_03_weekly_continuity.csv`, `tables/c4_03_weekly_global.csv`,
`figures/c4_03_weekly_seam.png`.

The largest first-week scores after the restart:

| variable | z |
|---|---|
| chla.rect.inf | +2.74 |
| prep.indic.B | −2.70 |
| prep.indic | −2.47 |
| chla.inf | +2.32 |

These are ordinary weeks:

- the restart week's maximum |z| over variables (2.74) is reached or
  exceeded in **52%** of the 206 other weeks;
- the median of those weeks' maxima is 2.98.

After the restart from x0 (other parameters), cycle 2 found z up to 23.5
(`../../cycle2/results/tables/c2_01_restart_continuity.csv`).

### One-year change across the restart

`tables/c4_03_one_year_change.csv`, `tables/c4_03_one_year_global.csv`.
$D$ = first simulated year − year 600 of the source chain.

- **Global test:** max over 66 variables of |mean($D$)| / null SD = 2.21
  (for `num`), **p = 0.63**. Three variables have |z| > 2.
- **Per variable** (SD_π units, point-bootstrap CI):

| variable | mean change | variance of the change / stationary |
|---|---|---|
| prev | −0.026 [−0.058, 0.010] | 0.80 [0.55, 0.97] |
| num | −0.073 [−0.114, −0.029] | 0.70 [0.47, 0.94] |
| incid_rate | +0.048 [−0.226, 0.353] | 0.96 [0.69, 1.33] |
| dx_frac | +0.075 [−0.076, 0.201] | 0.89 [0.62, 1.20] |
| chla_prev | +0.130 [0.037, 0.233] | 0.86 [0.62, 1.08] |
| gono_prev | +0.103 [−0.012, 0.226] | 1.12 [0.82, 1.38] |

- **Single CIs:** they exclude 0 for 10 of the 66 means and exclude 1 for
  3 of the 66 variances.

### Same stationary law?

`tables/c4_03_law_global.csv`, `tables/c4_03_energy_test.csv`,
`tables/c4_03_law_compare.csv`, `figures/c4_03_law_z.png`. Years ≥ 300:

| comparison | means: max \|z\|, p | variances: max \|z\|, p | energy (null 95%), p |
|---|---|---|---|
| pool vs cold start | 2.28, 0.40 | 2.36, 0.43 | 0.0036 (0.0054), 0.67 |
| pool vs x0 runs | 33.6, 0.0005 | 7.0, 0.0005 | 0.423 (0.0076), 0.0005 |

- **Pool vs cold start, per variable.** The largest mean difference is
  0.076 SD_π, i.e. 0.2% for the White MSM HIV stocks, and 9 of 63 variables
  have p < 0.05. Those 9 are mostly one correlated group: the White HIV
  stocks, at z ≈ −2.
- **Pool vs x0, per variable.** Prevalence differs by +2.39 SD_π (+3.5%)
  and the STIs by +12% to +25%, as between the cold-start and x0 runs
  (c3_03).

## Interpretation

1. **The restart mechanism is seamless** at the resolution of 256 runs:
   - no week-1 jump beyond ordinary weekly noise;
   - no systematic one-year change (global p = 0.63);
   - the same stationary law as the uninterrupted chains.

   The per-variable CIs that exclude 0 come from correlated groups
   (chlamydia; population size). They vanish in the global test, which
   uses a null built from the cold-start chains themselves.
2. **So the x0 jumps and the x0 equilibrium came from what x0 carries, not
   from restarting.**
   - Restarting from states saved with consistent network coefficients
     reproduces π_cold exactly.
   - Restarting from `restart-hpc.rds` gave π_x0.
   - Among what x0 carries, only the uniform −0.011 edges offset (c4_01)
     persists forever. The old parameters are overridden and the old
     attributes are replaced within one lifetime.

   The −0.011 offset means 1.1% fewer ties in every network, which lowers
   transmission. A rough check: for an endemic infection with prevalence p,
   the relative change of prevalence is about (1 − p)/p times the relative
   change of transmission. For p ≈ 0.25 that predicts ≈ −3.3%, against
   −3.5% observed (the pool vs x0 prevalence difference). This is a
   plausibility argument, not a test.
3. **The pool runs and the cold-start runs are one model.** Levels and
   dynamics can be pooled across the two experiments. This is used for the
   lower bounds (c3_06) in c4_04.

## Decision / input for next steps

- **c4_04** takes π from the pool runs' own years ≥ 300 (checked against
  π_cold).
- **Restart files saved by consistent runs,** with the project's
  `make_restart_point()`, need no burn-in for level shifts. The only burn-in
  question left is the variance of runs sharing a point (c4_04, c4_05).

## Caveats and deviations

- **The per-variable variance ratios** of the one-year change are below 1
  for population size and prevalence (0.70 and 0.80, CIs excluding 1).
  - With only 32 source states, the variance of a quantity shared within a
    point is poorly estimated, and the point-bootstrap CIs are too narrow
    (c4_02).
  - A small reduction of first-year demographic noise after a restart can
    therefore not be excluded. It would be a second-order effect.
- **The weekly level shift** (mean of weeks 1–52 after vs weeks −51…0
  before, `level_shift_sd`) is descriptive only. The "before" side averages
  32 chains, so its noise is ≈ 0.18 SD for fast flows.
- **Coarse check only.** Individual-level consistency (timers, partnership
  durations) is checked only through these aggregates.
