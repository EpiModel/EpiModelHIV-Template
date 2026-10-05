# 07. Restart pools: burn-in, size, generation and selection (Q2–Q4)

## Question

- Can a pool of restart points remove the post-restart burn-in?
- How many points are needed?
- How should the points be produced?
- Should they be selected beyond "all processes ongoing"?

## Method

[METHODS.md](../METHODS.md) M3. Script: `07_pool_design.R`.

- **Design ICC.** Per output, the larger of the step 06 lower bound and the
  direct single-x0 value.
- **Pool formulas.** k points iid from π, with N runs spread evenly over
  them:
  - the variance deficit is ICC/k;
  - the MCSE inflation is $\sqrt{1+\mathrm{ICC}(N/k-1)}$.
- **Selection experiment.** Uses real stationary states from this dataset:
  2000 replicates, each picking 32 of 254 candidates. Every candidate has one
  realised 20-year future.

## Results

### Burn-in as a function of pool size

The deficit of annual values at horizon h is ICC(h)/k
(`tables/07_time_to_full_by_k.csv`, `figures/07_time_to_full_by_k.png`).
Years after restart until the deficit stays ≤ 10%, using the lower-bound /
single-x0 ICC:

| variable | k = 1 | k = 2 | k = 4 | k = 8 | k ≥ 16 |
|---|---|---|---|---|---|
| prev | > 40 / > 40 | 40 / > 40 | 25 / 40 | 10 / 15 | 0 |
| num | 40 / > 40 | 30 / > 40 | 20 / 30 | 7 / 10 | 0 |
| chla_prev | 20 / > 40 | 10 / 30 | 7 / 10 | 2 / 3 | 0 |
| gono_prev | 20 / 40 | 10 / 40 | 7 / 20 | 2 / 2 | 0 |
| incid_rate | 5 / 15 | 1 / 0 | 1 / 0 | 1 / 0 | 0 |

For the 20-year window mean at B = 0, the points needed for a variance
deficit ≤ 10% (≤ 5%) are (`tables/07_k_needed.csv`):

- prev: 9 (18);
- num: 9 (17);
- STIs: 5–6 (10–12);
- incid_rate: 5 (10);
- dx_frac: 5 (9);
- supp_frac and prep_cov: 2 (3).

### Precision of the research estimates

With N research runs spread over k points, the MCSE of the mean 20-year
window is inflated by $\sqrt{1+\mathrm{ICC}(N/k-1)}$ (`tables/07_pool_mcse.csv`).
For N = 256 and B = 0:

| k | prev | incid_rate | chla_prev |
|---|---|---|---|
| 1 | 14.9 | 11.0 | 12.2 |
| 8 | 5.3 | 4.0 | 4.3 |
| 32 | 2.65 | 2.08 | 2.24 |
| 64 | 1.89 | 1.56 | 1.65 |
| 128 | 1.36 | 1.21 | 1.26 |
| 256 | 1.00 | 1.00 | 1.00 |

Points needed for an MCSE inflation ≤ 10% (≤ 25%) at N = 64 / 256 / 1024
(`tables/07_k_needed.csv`):

- prev: 52 / 206 / 824 (39 / 156 / 621);
- incid_rate: 45 / 178 / 710;
- chla_prev: 47 / 188 / 751;
- supp_frac: 25 / 98 / 391.

### Producing the points

Independent chains are one option. Points taken from **one** chain d years
apart are the other (`tables/07_single_chain_spacing.csv`). Their effective
pool size for prev, using the pooled ACF as the correlation proxy:

| k | d = 10 | d = 20 | d = 30 | d = 50 | d = 75 |
|---|---|---|---|---|---|
| 16 | 2.9 | 5.2 | 7.3 | 10.9 | 13.0 |
| 32 | 5.2 | 9.9 | 14.2 | 21.5 | 25.8 |
| 64 | 10.0 | 19.4 | 28.0 | 42.6 | 51.4 |

### Selection experiment

Selecting 32 of 254 stationary states (`tables/07_selection_summary.csv`,
`tables/07_selection_overall.csv`, `figures/07_selection.png`):

| strategy | Var(futures)/Var_π, prev | same, median over key outputs | RMSE of pool mean, prev (SD) | within-run variance, prev | pool-mean bias, max over outputs |
|---|---|---|---|---|---|
| random | 0.99 | 1.00 | 0.175 | 1.00 | 0.007 |
| ongoing (STIs > π 1% quantile) | 0.97 | 0.98 | 0.172 | 1.00 | 0.036 |
| typical (closest to π mean, whole state) | **0.62** | 0.85 | 0.138 | 0.90 | 0.041 |
| target-like (closest on 5 headline outputs) | **0.40** | 0.92 | 0.110 | 0.90 | 0.024 |
| stratified on state PC1 | 1.01 | 1.00 | **0.105** | 1.00 | 0.005 |

The theoretical random-sampling RMSE is $1/\sqrt{32}$ = 0.177.

## Interpretation

1. **A pool removes the post-restart burn-in.** With k points drawn from π,
   the missing variance is ICC/k, which is at most 1/k. With ≥ 10–20
   independent stationary points, runs have ≥ 90–95% of the stationary
   variance from year 0, for every output. A single point needs ~65–90
   years (step 04).
2. **Precision is what drives the pool size, not the time to full
   variance.** HIV prevalence's 20-year mean is ~85% determined by the
   restart state, so research runs that share points are strongly
   correlated. With N = 256 runs on 32 points, the MCSE of mean prevalence
   is 2.65 times that of 256 independent points. That is equivalent to only
   ~36 independent runs. Keeping the MCSE within +10% needs about 0.8 N
   points for prevalence and 0.7 N for incidence and STIs, i.e. close to
   one point per run. Reusing points helps only for the fast outputs
   (suppression, PrEP coverage: ~0.4 N).
3. **How to produce the points.** Run k independent chains from the current
   x0 for the single-restart burn-in and save their final states.
   - The burn-in is ≥ 70–100 years; 100–150 years gives a margin for the
     slow HIV mode and the STI means.
   - This is embarrassingly parallel, and the same pool serves every
     scenario and later projects.
   - One long chain is not cheaper. Points must be ≥ 50–75 years apart to
     be worth ≥ 0.7–0.8 of an independent point (1 point every 75 years of
     serial simulation, vs 1 point per ~100–150 years of *parallel*
     simulation).
   - The existing variance experiment already contains 254 such chains. Had
     it saved states at year ≥ 150, it would have produced a pool of 254
     iid stationary points.
4. **Do not select points on closeness to anything.**
   - Picking "typical" or target-like states shrinks the between-run
     variance: to 62% and 40% of its true value for HIV prevalence. It also
     shrinks the within-run variance (0.90), so research runs from such a
     pool look falsely precise.
   - The smaller RMSE of those pools is bought with that under-dispersion.
   - The "all processes ongoing" filter is almost harmless: bias ≤ 0.04 SD
     and variance ratio ≥ 0.95. Syphilis extinction is rare (step 01).
   - The one legitimate refinement is **stratified random sampling**
     (strata on the slow state mode). It keeps the variance exact (1.00) and
     cuts the error of the pool mean for prevalence from 0.175 to 0.105 SD,
     which is the gain of a 2.8× larger random pool.

## Decision / input for next steps

- **Pool generation.** k independent chains from x0, run 100–150 years;
  keep the final states.
- **Pool size.** k ≈ N (one point per research run) for level estimates of
  slow outputs. With fewer points, report the MCSE with the pool-level
  clustering accounted for: resample points, not runs.
- **Selection.** Random sampling, optionally stratified on the HIV
  prevalence / state PC1. No selection on targets.
- **Phase B test.** Draw ~8 points from the pool and run ~16 replicates
  each for 40 years. This measures ICC directly, averaged over π, including
  unobserved state. It should also measure the ICC of *intervention
  effects*, which is what really sets the pool size for scenario contrasts.

## Caveats and deviations

- **The pool formulas assume points iid from π.** Points from independent
  chains after a 100-year burn-in still share a small x0 imprint. For the
  prevalence window mean it is 1 − 0.94 = 0.06 at B = 100
  (`tables/04_window_burnin.csv`, CI includes 0).
- **The design ICC is for levels.** For contrasts between scenarios run
  from the same point, the shared restart component partly cancels. The
  relevant ICC is that of the effect, which is not measurable here (one
  scenario only).
- **The single-chain spacing table is a heuristic.** It uses the ACF of
  prevalence as a proxy for the correlation between the conditional means
  of two points.
- **Selection experiment.** One realised future per state, so the variance
  ratios are for one run per point. Candidates are one state per chain at a
  random stationary year.
- **Time-to-full table.** The single-x0 ICC at h ≤ 40 is used; "> 40" means
  beyond the evaluated horizons.
