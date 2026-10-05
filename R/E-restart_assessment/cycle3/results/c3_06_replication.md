# C3-06. Do the cycle 1–2 dynamics carry over to the cold-start model?

## Question

The two experiments have different stationary laws (c3_03). Do the
independent cold-start runs reproduce what cycles 1–2 measured about the
**dynamics**?

- the autocorrelation and τ_int;
- the split of a 20-year run's variance between over time and between runs;
- the lower bounds on the share of variance fixed by the restart state
  (ICC).

## Method

METHODS.md M2.3, M2.6, M2.7, with cycle 1's estimators unchanged. Script:
`c3_06_replication.R`.

- **Years.** Both experiments on the same years, 240–600 (`EQ_START_C3`,
  c3_04). τ_int and the variance–time curve depend on the series length, so
  this is the like-for-like comparison. The cycle 1 values (years 150–600)
  are shown for reference.
- **CIs.** 500 chain bootstraps. The experiments are independent, so
  differences of bootstrap replicates give the CI of the difference.
- **Lower bounds.**
  - pseudo-restarts every 5 years, t0 = 245–560: 16,384 (cold) and 16,256
    (x0) rows;
  - 212 features;
  - ridge and own-value models with chain-blocked CV;
  - 214 responses: values at h = 5, 10, 20, 30, 20-year means at
    B = 0, 10, 20, and the 10-year cumulative incidence at B = 5.

## Results

### Memory: τ_int

`tables/c3_06_acf_tau.csv`, years 240–600:

| variable | cold start | x0 runs | difference | cycle 1 (150–600) |
|---|---|---|---|---|
| prev | 52.9 [49.2, 58.1] | 68.0 [58.0, 78.1]* | −15.1 [−27.2, −3.1] | 66.5* |
| prev.B | 47.6 [44.3, 52.5] | 57.4 [51.0, 65.5]* | −9.8 [−18.9, −1.2] | 58.0* |
| prev.W | 48.9 [45.1, 55.5] | 66.2 [55.1, 76.1]* | −17.3 [−28.1, −4.1] | 62.0* |
| prev.H | 33.1 [30.8, 36.5] | 40.5 [35.5, 46.0] | −7.4 [−12.8, −1.5] | 40.3 |
| num | 51.7 [46.4, 58.2]* | 52.9 [47.3, 59.8]* | −1.2 [−11.1, 7.8] | 49.6 |
| gono_prev | 20.8 [18.3, 22.9] | 22.6 [20.2, 25.2] | −1.8 [−5.4, 1.3] | 22.3 |
| chla_prev | 21.5 [20.2, 23.6] | 23.4 [20.8, 26.4] | −1.8 [−5.1, 1.5] | 22.9 |
| syph_prev | 14.5 [13.8, 15.7] | 19.1 [17.6, 21.2] | −4.6 [−6.7, −2.8] | 18.4 |
| dx_frac | 10.5 [10.1, 10.9] | 10.2 [9.9, 10.7] | +0.2 [−0.4, 0.7] | 10.4 |
| incid_rate | 7.6 [6.9, 8.4] | 9.5 [8.2, 11.0] | −1.9 [−3.6, −0.2] | 9.6 |
| supp_frac | 7.0 [6.5, 7.5] | 7.2 [6.6, 7.7] | −0.2 [−0.9, 0.6] | 7.1 |
| prep_cov | 2.8 [2.5, 3.0] | 3.1 [2.7, 3.3] | −0.3 [−0.7, 0.1] | 3.1 |

\* Geyer's sequence was truncated at lag 150, so the value is a lower one.

The variance–time curve at L = 150 (`tables/c3_06_variance_time_split.csv`)
gives prevalence 46.5 [42.4, 51.0] (cold) vs 53.5 [47.9, 58.4] (x0).

### The split of a 20-year run

`tables/c3_06_variance_time_split.csv`. The share of v_π seen only
**between** runs:

| variable | cold start | x0 runs | difference |
|---|---|---|---|
| prev | 0.890 [0.885, 0.896] | 0.899 [0.893, 0.904] | −0.008 [−0.016, 0.000] |
| prev.B | 0.868 | 0.875 | −0.007 [−0.016, 0.002] |
| prev.H | 0.762 | 0.777 | −0.015 [−0.028, −0.002] |
| num | 0.861 | 0.864 | −0.003 [−0.012, 0.005] |
| gono_prev | 0.548 | 0.582 | −0.033 [−0.048, −0.016] |
| chla_prev | 0.564 | 0.593 | −0.029 [−0.046, −0.011] |
| syph_prev | 0.495 | 0.563 | −0.069 [−0.086, −0.050] |
| dx_frac | 0.399 | 0.393 | +0.005 [−0.009, 0.021] |
| supp_frac | 0.288 | 0.291 | −0.003 [−0.016, 0.008] |
| incid_rate | 0.187 | 0.194 | −0.007 [−0.017, 0.004] |
| prep_cov | 0.115 | 0.121 | −0.005 [−0.012, 0.002] |

### Share of variance fixed by the restart state (lower bounds)

`tables/c3_06_icc_compare.csv` (full: `tables/c3_06_icc_bounds.csv`):

| response | cold start | x0 runs | cycle 1 |
|---|---|---|---|
| prev, value at h = 20 | 0.48 [0.45, 0.50] | 0.48 [0.46, 0.51] | 0.49 |
| prev, 20-year mean, B = 0 | 0.80 [0.79, 0.81] | 0.81 [0.80, 0.82] | 0.81 |
| prev, 20-year mean, B = 20 | 0.27 [0.25, 0.30] | 0.29 [0.26, 0.31] | 0.29 |
| num, 20-year mean, B = 0 | 0.71 [0.70, 0.73] | 0.72 [0.70, 0.73] | 0.72 |
| dx_frac, 20-year mean, B = 0 | 0.36 [0.34, 0.37] | 0.34 [0.32, 0.35] | 0.34 |
| incid_rate, 20-year mean, B = 0 | 0.31 [0.28, 0.33] | 0.32 [0.30, 0.34] | 0.32 |
| gono_prev, 20-year mean, B = 0 | 0.35 [0.33, 0.37] | 0.38 [0.35, 0.39] | 0.38 |
| syph_prev, value at h = 5 | 0.35 [0.34, 0.36] | 0.45 [0.43, 0.47] | 0.45 |
| supp_frac, 20-year mean, B = 0 | 0.11 [0.09, 0.12] | 0.12 [0.11, 0.13] | 0.12 |
| prep_cov, 20-year mean, B = 0 | 0.13 [0.11, 0.14] | 0.13 [0.12, 0.15] | 0.14 |
| cumulative incidence, years 6–15 | 0.15 [0.13, 0.16] | 0.14 [0.13, 0.16] | |

Figures:

- `figures/c3_06_tau_int.png`;
- `figures/c3_06_icc_compare.png`: all key variables. The points lie on the
  diagonal.

## Interpretation

1. **The restart-memory results of cycles 1–2 transfer to the cold-start
   model.**
   - **Lower bounds.** Their CIs overlap for 202 of the 214 responses,
     and for 171 of the 172 non-STI responses, which differ by at most
     0.02 (`tables/c3_06_icc_compare.csv`). The STI bounds are 0.00–0.10
     lower in the cold-start model. The two experiments give the same
     values:
     - 0.80 vs 0.81 for the 20-year prevalence mean;
     - 0.48 for prevalence 20 years ahead;
     - 0.15 vs 0.14 for 10-year cumulative incidence.
   - **The variance split.** It agrees to within 0.015 for HIV outputs,
     the cascade and PrEP. About 90% of the stationary variance of 20-year
     prevalence is between runs, in either model.
   - **The conclusions that follow** are unchanged:
     - a single restart point is ruled out;
     - pools cost precision in proportion to the ICC;
     - selection on closeness shrinks the variance.
2. **HIV memory is somewhat shorter in the cold-start model.**
   - τ_int for prevalence is 53 years against 68 on the same years
     (difference −15 [−27, −3]).
   - The prevalence tail of the mean relaxation is also fast (13–17 years,
     c3_04).
   - The x0 estimate is truncated (a lower value). The cold-start one is
     not, so the gap may be larger.
   - The effect on the bounds is small (≤ 0.02 for prevalence). The two
     ACFs are close up to lag 20 (ρ(20) = 0.59 vs 0.62) and part only
     beyond it (ρ(50) = 0.11 vs 0.19, `tables/c3_06_acf_tau.csv`). The
     20-year ICCs depend mostly on the first 20–30 years.
3. **STIs are slightly less persistent in the cold-start model,**
   especially syphilis:
   - between-run share 0.50 vs 0.56;
   - ICC bound at h = 5: 0.35 vs 0.45;
   - τ_int 14.5 vs 19.1 years.

   This is consistent with STIs being further above their epidemic
   threshold under the cold-start network (c3_03: +13–26% incidence).
   Faster recovery from fluctuations is expected there.

## Decision / input for next steps

- **Use cycles 1–2 for the restart-memory design** of the production
  model:
  - ICC bounds and pool formulas;
  - k ≈ N for slow level estimates;
  - 8–20 points for the project outcomes.
- **Use the cold-start values** where they differ:
  - τ_int of prevalence ≈ 53 years, so the single-chain spacing heuristic
    becomes d ≥ 2 τ_int ≈ 105 years;
  - syphilis.

## Caveats and deviations

- **Years 240–600 only.** Estimators that truncate (Geyer) give lower
  values than cycle 1's 150–600 for slow variables. That is why both
  experiments are recomputed on the same years.
- **What the bounds see.** They use observed summaries only. Memory in
  unobserved network state is not seen by either experiment's bounds
  (cycle 1 caveat).
