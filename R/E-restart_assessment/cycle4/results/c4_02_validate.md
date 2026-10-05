# C4-02. Validation of the nested-design estimators

## Question

Do the cycle 4 estimators recover known answers on synthetic data with the
same design? That is, 32 restart points drawn from π, the actual counts of
1–15 runs per point, and 600 years. The estimators are:

- the direct ICC(h), `icc_w` and `icc_a`, and its point-bootstrap CI;
- the ICC of 20-year means after a burn-in B;
- the time to full variance from one point, from a fit;
- the pool variance formula;
- the one-year-change continuity test.

## Method

[c4_METHODS.md](c4_METHODS.md) C4-M2 to C4-M4. Script: `c4_02_validate.R`.

- **S1:** one slow AR(1), a = 0.97, like prevalence.
- **S2:** fast (a = 0.6, 60% of the variance) + slow (a = 0.97, 40%).
- **Truths:** $\mathrm{ICC}(h)=\sum_c v_c a_c^{2h}$, and the closed form
  for window means (script comments).
- **Criterion:** |z| < 3 or a stated range, as in cycles 1–3.

## Results

`tables/c4_02_validation.csv`: 33 rows; 32 have a pass/fail criterion and
**28 pass**.

**`icc_w` passes every check:**

| check | truth | estimate [95% CI] |
|---|---|---|
| S1 icc_w(1) | 0.941 | 0.938 [0.924, 0.949] |
| S1 icc_w(10) | 0.544 | 0.479 [0.373, 0.583] |
| S1 icc_w(20) | 0.296 | 0.266 [0.086, 0.400] |
| S2 icc_w(5) | 0.299 | 0.310 [0.164, 0.441] |
| S1 20-year mean, B = 0 | 0.659 | 0.592 [0.496, 0.674] |
| S2 20-year mean, B = 0 | 0.504 | 0.485 [0.396, 0.562] |
| S1 icc_w(10), mean of 50 replications | 0.544 | 0.532 [0.518, 0.545] |
| S1 icc_w(10), CI coverage | 0.95 | 0.88 |

**`icc_a` fails 4 checks,** all on S1:

- the single realisation at h = 5, 10, 20 has z = −3.9, −3.8, −3.1;
- over 50 replications the mean is 0.513 vs 0.544 (z = −3.1);
- its CI coverage is 0.90.

**One point, time to full variance (S2):**

- ε = 0.1: 20.8 [13.5, 794] vs a truth of 23.0;
- ε = 0.2: 11.8 [7.5, 18.8] vs 11.5.

**Pool formula.** The mean across-run variance ratio at h = 10 is 0.961
[0.921, 1.001], against 0.982 predicted for these counts.

**Continuity test:**

- rejection rate under H0: 0.045 (200 replications);
- power for a 0.1 SD jump: 1.00.

## Interpretation

- **`icc_w` is the estimator to use.**
  - **Accuracy:** it is unbiased (the mean over replications is within its
    CI) and its CIs cover 0.88. That is slightly under 0.95, as for the
    cycle 1 ACF.
  - **Precision:** its CI half-width is ≈ 0.01 when ICC is near 1, and
    grows to ≈ 0.15 when ICC is near 0.3. With 224 within-point df the
    within-point variance has a relative SE of ≈ 9.5%, and 1 − ICC scales
    that error.
- **`icc_a` is biased low with 32 points,** by about 6% relative at
  ICC ≈ 0.5, and the bias is correlated across horizons in one realisation.
  This is the known small-sample bias of the ANOVA intraclass correlation.
  It is kept only as a check. It is useful near ICC = 0, where it is more
  precise than `icc_w`.
- **The one-point burn-in, the pool formula and the continuity test work.**
  Upper CIs of burn-in times are long, as in cycles 1–3.

## Decision / input for next steps

- **c4_04:** report `icc_w` with its point-bootstrap CI, and `icc_a` as a
  check.
- **c4_03:** use the continuity test.

## Caveats and deviations

- **`icc_a` failures.** They are documented, not fixed: the estimator is
  the standard ANOVA one. Fixing it would mean another estimator, e.g.
  REML, which is not installed and has similar small-k bias.
- **CIs are ~88% intervals.** They come from 32 clusters, and the
  point-bootstrap CIs of `icc_w` are slightly narrow.
