# C4-04. The share of variance fixed by the restart state, measured directly

## Question

Cycles 1–3 had only two kinds of estimate of ICC(h), the share of the
variance of an output h years ahead that the restart state fixes:

- **lower bounds** from observed summaries at the restart (cycles 1–3);
- the **direct value for one atypical x0** made with other parameters
  (cycle 1).

The pool runs give ICC directly, averaged over 32 states drawn from π. It
includes the memory held in the network, individual histories and the age
structure. Two questions:

1. How large is ICC, and how much larger than the lower bounds?
2. How long does a single same-parameter restart point need to reach full
   variance?

## Method

[c4_METHODS.md](c4_METHODS.md) C4-M2. Script: `c4_04_icc_direct.R`.

- **Main estimate:** $\mathrm{ICC}_w(h)=1-\hat\sigma^2_W(h)/\hat v_\pi$,
  from 224 within-point df. The ANOVA ICC is shown as a check.
- **CIs:** 500 bootstraps over points.
- **Coverage:** values at h = 1–150, 20-year means and 10-year cumulative
  incidence after B = 0–150, for 44 variables.
- **One point:** the time to full variance comes from a fit of
  $w=1-\mathrm{ICC}_w$, with 200 bootstrap refits.

## Results

Full tables:

- `tables/c4_04_icc_all.csv` (summary: `tables/c4_04_icc_summary.csv`);
- `tables/c4_04_vs_bounds.csv`: direct against the lower bounds of the same
  model (c3_06) and the single x0 (cycle 1);
- `tables/c4_04_one_point_T.csv`.

### Direct ICC against the lower bounds

Direct $\mathrm{ICC}_w$ [95% CI] / lower bound of the same model (c3_06) /
single x0 (cycle 1):

| output | h or B | direct | lower bound | x0 |
|---|---|---|---|---|
| prev, value | h = 10 | 0.80 [0.76, 0.83] | 0.76 | 0.83 |
| prev, value | h = 20 | 0.57 [0.47, 0.65] | 0.48 | 0.65 |
| prev, value | h = 30 | 0.39 [0.28, 0.49] | 0.25 | 0.44 |
| prev, 20-year mean | B = 0 | 0.84 [0.81, 0.87] | 0.80 | 0.86 |
| prev, 20-year mean | B = 20 | 0.38 [0.28, 0.50] | 0.27 | 0.47 |
| i.prev.dx.B, 20-year mean | B = 0 | 0.86 [0.84, 0.88] | 0.81 | |
| num, value | h = 30 | 0.49 [0.39, 0.57] | 0.17 | 0.36 |
| num, 20-year mean | B = 0 | 0.81 [0.78, 0.85] | 0.71 | 0.82 |
| num, 20-year mean | B = 20 | 0.48 [0.40, 0.55] | 0.18 | 0.39 |
| gono_prev, 20-year mean | B = 0 | 0.54 [0.46, 0.62] | 0.35 | 0.58 |
| chla_prev, 20-year mean | B = 0 | 0.57 [0.50, 0.63] | 0.37 | 0.58 |
| syph_prev, 20-year mean | B = 0 | 0.43 [0.32, 0.53] | 0.29 | 0.47 |
| incid_rate, 20-year mean | B = 0 | 0.37 [0.25, 0.48] | 0.31 | 0.47 |
| incid_rate, 20-year mean | B = 20 | 0.24 [0.06, 0.39] | 0.05 | 0.25 |
| dx_frac, 20-year mean | B = 0 | 0.36 [0.23, 0.47] | 0.36 | 0.42 |
| supp_frac, 20-year mean | B = 0 | 0.19 [0.00, 0.36] | 0.11 | 0.13 |
| prep_cov, 20-year mean | B = 0 | 0.23 [0.12, 0.33] | 0.13 | 0.10 |
| cumulative incidence, years 6–15 | B = 5 | 0.25 [0.07, 0.40] | 0.15 | |
| same, Black MSM | B = 5 | 0.18 [0.01, 0.35] | 0.14 | |

Over all 214 comparisons:

- the direct value exceeds the lower bound in 175;
- in 80, the lower bound falls below the direct CI.

**Long horizons.** Beyond ≈ 60 years the direct values scatter around 0 by
±0.2 for the slow outputs, which is the resolution of `icc_w` when ICC is
near 0. The ANOVA check stays within ±0.04 there (`icc_a`,
`tables/c4_04_icc_all.csv`).

Figures:

- `figures/c4_04_icc_values.png`: ICC(h) curves with lower bounds and the
  single-x0 curve;
- `figures/c4_04_icc_windows.png`.

### A single same-parameter restart point: time to full variance

`tables/c4_04_one_point_T.csv`. Years until the runs of one point have
≥ 90% or ≥ 80% of the stationary variance:

| output | ≥ 90% (ε = 0.1) | ≥ 80% (ε = 0.2) |
|---|---|---|
| prev, value | 51 [44, 200] | 40 [34, 50] |
| i.prev.dx.B, value | 49 [40, 162] | 38 [32, 50] |
| num, value | 76 [55, 557] | 53 [42, 74] |
| gono_prev, value | 34 [24, 243] | 21 [14, 29] |
| chla_prev, value | 31 [21, 48] | 20 [15, 28] |
| syph_prev, value | 24 [12, 55] | 10 [8, 17] |
| dx_frac, value | 14 [8, 51] | 7 [5, 12] |
| supp_frac, value | 5 [4, 14] | 4 [3, 5] |
| prep_cov, value | 2 [2, 4] | 2 [1, 3] |
| prev, 20-year mean (burn-in B) | 40 [34, 232] | 30 [24, 151] |
| num, 20-year mean | 63 [41, 429] | 43 [31, 62] |
| cumulative incidence over 10 years (B) | 24 [16, 124] | 11 [0, 24] |

For annual HIV incidence the ICC is below 0.1 from year 2 and below 0.05
after 14 [1, 24] years.

## Interpretation

1. **The lower bounds understate restart memory, a little for HIV and a lot
   for population size and the STIs.**
   - **Prevalence.** The observed state explains most of what the restart
     state fixes: 0.84 vs 0.80 for the 20-year mean. The gap grows with the
     horizon, e.g. +0.14 at h = 30.
   - **Population size.** The observed state misses a large part: at 30
     years, 0.49 against 0.17. The likely carrier is the **age structure**,
     which no feature describes. Whether a population will shrink or grow
     depends on its age distribution, not only its size.
   - **STIs.** They carry +0.15 to +0.20 of unobserved memory in their
     20-year means, plausibly in the network and partnership state (who is
     infected, where).
   - **Consequence.** Cycle 1's rule "design ICC = max(lower bound, x0
     value)" was about right on average, but only thanks to the x0 value.
     The lower bounds alone would have undersized pools for population size
     and the STIs.
2. **A single same-parameter point needs ≈ 50 years for prevalence to reach
   90% of its stationary variance, ≈ 40 years for a 20-year prevalence
   window, and ≈ 25 years for 10-year cumulative incidence.**
   - **Against cycle 2's bounds.** These are just above cycle 2's rigorous
     lower bounds (≥ 50 and ≥ 10 years).
   - **Against the x0 point.** They are shorter than after the x0 point with
     other parameters (73 and 31 years, cycles 1–2), because a stationary
     point has no mean relaxation to add.
   - **Population size** needs ≈ 75 years. STIs need 25–35, the cascade
     ≤ 15, PrEP ≈ 2.
3. **The project's intervention outcome** (cumulative incidence over years
   6–15) has an ICC of **0.25** [0.07, 0.40] for one point.
   - This matches the design value cycle 2 used for it.
   - It sits between the lower bound (0.15) and the single-x0 value.

## Decision / input for next steps

- **c4_05** uses the direct $\mathrm{ICC}_w$ as the design ICC.
- **One same-parameter point, burn-in for 90% of the variance:**
  - ≈ 50 years (prevalence), ≈ 40 years (20-year prevalence windows);
  - ≈ 75 years (population size);
  - ≈ 25 years (10-year cumulative incidence).

## Caveats and deviations

- **Precision.** 32 points with 1–15 runs each give CIs of ±0.02 at ICC
  ≈ 0.9, up to ±0.15 at ICC ≈ 0.3. The CIs are ~88% intervals (c4_02).
- **Upper CIs of the times are long.** The variance has to be resolved at
  the 10% level, as in cycles 1–3.
- **Negative estimates.** Some direct values are negative at long horizons
  or for fast outputs, e.g. prep_cov at h = 20. They are noise around 0.
- **One model only.** These are ICCs of the cold-start (local-netest)
  model. The x0 model's dynamics are similar (c3_06), so the values should
  transfer approximately.
