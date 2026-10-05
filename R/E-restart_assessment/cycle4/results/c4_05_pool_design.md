# C4-05. Pool design with the direct ICC

## Question

With the direct ICC (c4_04) in place of lower bounds or one x0:

- **(a)** Does the actual 32-point pool give runs with the full stationary
  spread? How large is its shared imprint, i.e. the error of the pool mean?
- **(b)** How many points, and how many runs per point, do the project's
  outcomes need, with balanced and with randomised assignment?
- **(c)** How long is the burn-in after a restart with k points?

## Method

[c4_METHODS.md](c4_METHODS.md) C4-M4. Script: `c4_05_pool_design.R`.

- **Design ICC:** $\mathrm{ICC}_w$ with its 95% CI (c4_04), clipped to
  [0, 1].
- **Outcomes:**
  - 20-year means at B = 0;
  - cumulative incidence over years 6–15;
  - values in year 15 (the intervention outcomes, `outcomes.R`);
  - values in year 70 (calibration targets after a 70-year run from a
    restart).

## Results

### (a) The realised pool

`tables/c4_05_realised_pool.csv`, `figures/c4_05_realised_variance.png`,
`figures/c4_05_realised_offset.png`.

**Spread.** The across-run variance of the 256 runs, relative to v_π:

| variable | h = 1 | h = 10 | h = 20 | expected for these counts |
|---|---|---|---|---|
| prev | 0.94 [0.50, 1.39] | 1.01 [0.65, 1.36] | 1.11 [0.80, 1.36] | 0.97–0.98 |
| num | 0.83 [0.39, 1.34] | 0.92 [0.60, 1.19] | 0.98 [0.75, 1.16] | 0.97–0.98 |
| incid_rate | 1.18 [0.87, 1.43] | 1.02 [0.80, 1.21] | 0.89 [0.76, 1.01] | 0.99–1.00 |
| dx_frac | **0.59** [0.38, 0.79] | 0.91 [0.73, 1.08] | 1.05 [0.88, 1.24] | 0.97–1.00 |
| gono_prev | 0.86 [0.39, 1.49] | 0.84 [0.71, 0.99] | 0.85 [0.72, 0.99] | 0.97–0.99 |

**Imprint.** The error of the pool mean, in SD_π, against the expected
RMS for 32 points × these counts:

- prev: +0.07 at h = 1 (RMS 0.19), +0.15 at h = 20 (RMS 0.15);
- 3.6% of all (variable, year) offsets exceed twice the expected RMS.

### (b) Points needed

`tables/c4_05_points_needed.csv`: points needed for an MCSE inflation
≤ +10% of the mean outcome, [CI from the ICC CI].

| outcome | ICC | balanced, N = 32 | balanced, N = 256 | random, N = 32 | random, N = 256 |
|---|---|---|---|---|---|
| prev, 20-year mean | 0.84 [0.81, 0.87] | 26 | 205 [204, 207] | 125 | 1024 |
| num, 20-year mean | 0.81 [0.78, 0.85] | 26 | 204 | 121 | 989 |
| chla_prev, 20-year mean | 0.57 [0.50, 0.63] | 24 | 188 | 85 | 694 |
| incid_rate, 20-year mean | 0.37 [0.25, 0.48] | 21 [18, 23] | 164 [139, 179] | 55 | 453 |
| cumulative incidence, years 6–15 | 0.25 [0.07, 0.40] | 18 [9, 22] | 139 [67, 169] | 37 [11, 60] | 301 [90, 488] |
| same, Hispanic MSM | 0.07 [0.00, 0.20] | 9 [0, 16] | 66 [0, 126] | 11 | 89 |
| prev, year 15 | 0.69 [0.61, 0.75] | 25 | 197 | 103 | 840 |
| i.prev.dx.B, year 15 | 0.72 [0.67, 0.76] | 25 | 199 | 107 | 876 |
| i.prev.dx.B, year 70 | 0.00 [0.00, 0.12] | 0 [0, 12] | 0 [0, 92] | 1 [1, 18] | 1 [1, 143] |
| ir100.gono, year 70 | 0.04 [0.00, 0.25] | 5 [0, 18] | 39 [0, 139] | 6 | 45 |

**Precision for N = 32 runs per scenario** (`tables/c4_05_pool_mcse.csv`).
MCSE inflation, balanced / randomised assignment:

| outcome | 1 point | 8 points | 16 points | 32 points |
|---|---|---|---|---|
| cumulative incidence, years 6–15 | 2.95 | 1.32 / 1.40 | 1.12 / 1.22 | 1.00 / 1.11 |
| prev, year 15 | 4.74 | 1.75 / 1.92 | 1.30 / 1.53 | 1.00 / 1.29 |

With 32 randomised points, the 32 runs of a scenario are worth 25.8
independent runs for cumulative incidence, and 19.2 for year-15
prevalence.

**Precision for N = 256** (20-year prevalence mean). MCSE inflation,
balanced / randomised:

| points | inflation, balanced / randomised |
|---|---|
| 32 | 2.63 / 2.78 |
| 128 | 1.36 / 1.64 |
| 256 | 1.00 / 1.36, i.e. 139 effective runs |

### (c) Burn-in with k points

`tables/c4_05_burnin_by_k.csv`. Years after the restart until the
variance deficit ICC(h)/k stays ≤ 10%:

| variable | k = 1 | 2 | 4 | 8 | ≥ 16 |
|---|---|---|---|---|---|
| prev | 51 | 40 | 27 | 11.5 | 0 |
| i.prev.dx.B | 49 | 38 | 26 | 11.5 | 0 |
| num | 76 | 53 | 31 | 8.8 | 0 |
| gono_prev | 34 | 21 | 8.5 | 2 | 0 |
| chla_prev | 31 | 20 | 8.5 | 2 | 0 |
| syph_prev | 24 | 10.5 | 5.8 | 2.3 | 0 |
| dx_frac | 14.5 | 7.3 | 3.5 | 1.5 | 0 |
| incid_rate | 0 | 0 | 0 | 0 | 0 |

## Interpretation

1. **The 32-point pool delivers the stationary spread from year 1.**
   - The across-run variances are ≈ 1 within their (wide) CIs, as the
     formula predicts (deficit ≤ 3%).
   - The pool-mean errors match a random pool.
   - **The exception shows the limit of a single pool.** By chance the 32
     points are under-dispersed in the diagnosed fraction, so runs show 59%
     of its variance in year 1, recovering by year 10. Stratified sampling
     of points (cycle 1) would protect against this.
2. **For level estimates, randomised assignment is expensive.**
   - Drawing points with replacement adds multiplicity even when k = N.
     With 256 points for 256 runs, the MCSE of the 20-year prevalence mean
     is still inflated 1.36-fold; the runs are worth 139.
   - **Balanced assignment** (each point used N/k times) with k ≈ 0.8 N
     points gives ≤ +10%. This confirms cycle 1's k ≈ 0.7–0.8 N, now with
     direct ICCs.
3. **For the project's intervention outcome, 32 randomised points are
   adequate.** Cumulative incidence over years 6–15 (ICC 0.25) needs 18
   points for +10% with N = 32 runs, balanced. With this 32-point pool and
   `randomize.restart = TRUE`:
   - its inflation is 1.11, i.e. 26 effective runs of 32;
   - a single point would give 2.95 (≈ 4 effective runs);
   - 8 recycled points give 1.32–1.40, the current code default with
     batches of 8 (cycle 2, A8).
4. **Calibration from a restart forgets the point by year 70.** The ICC of
   year-70 targets is ≈ 0, with upper CIs of 0.05–0.26. Even one point
   costs little precision there, in line with cycle 2.
5. **With ≥ 16 stationary points no post-restart burn-in is needed** for
   ≥ 90% of the variance of any output. With 8 points, ≈ 10 years for
   prevalence. With one point, ≈ 50 years.

## Decision / input for next steps

- **Pool size:**
  - 32 stationary points are enough for the intervention outcomes at N = 32
    per scenario;
  - for level estimates of slow outputs with N = 256, use ≈ 200 points,
    balanced.
- **Assignment:** prefer balanced assignment (each point used equally, one
  run per point when k = N) to `randomize.restart`. This needs the
  EpiModelHPC batches to offset their restart index (cycle 2, A8).
- **Stratification:** stratified sampling of points on the slow state
  directions (prevalence, population size) keeps a single pool from being
  under-dispersed by chance.

## Caveats and deviations

- **These formulas are for level estimates of one scenario.** For contrasts
  between scenarios run from the same points, the shared component largely
  cancels (cycle 2, C2-M6). Effect heterogeneity across points remains
  unmeasured: this experiment has one scenario.
- **The points-needed CIs** carry the ICC CIs, which are ~88% intervals
  (c4_02).
- **The realised-pool diagnostics** describe this one pool of 32 points.
