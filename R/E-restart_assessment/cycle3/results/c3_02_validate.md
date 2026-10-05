# C3-02. Validation of the cycle 3 estimators on synthetic cold starts

## Question

Do the new estimators recover known answers on synthetic data shaped like
the cold-start runs (256 chains × 600 years)?

- tolerance times after a cold start, the residual bias at year 70 and the
  research-window offsets;
- the tests of equal stationary laws.

## Method

[c3_METHODS.md](c3_METHODS.md) C3-M2 to C3-M4. Script: `c3_02_validate.R`.

**Series.** The truths are in the script comments.

| series | construction | what it tests |
|---|---|---|
| C0 | stationary AR(1), a = 0.9 | no false transient |
| C1 | AR(1), a = 0.9, every chain started at 5 (the brief's S1) | a plain cold start |
| C2 | AR(1), a = 0.95, $x_0\sim N(-3,2^2)$ | over-dispersed start, $r(t)>1$ |
| C3 | slow (τ = 17.5 y, 80% of the variance) + fast (τ = 8 y) AR(1), started at +64 / −95 SD | HIV-like overshoot: starts below π, peaks near +12.6 SD, slow tail |

**Same-law tests.** Two synthetic experiments of 256 and 254 chains, 301
stationary years, six correlated variables. The rejection rates are over
replications.

**Criterion.** As in cycle 1: |z| < 3, with z = (estimate − truth) /
SE_boot, or a stated range.

## Results

The full table is `tables/c3_02_validation.csv`: 37 rows. **All 29 rows
with a pass/fail criterion pass**; the other 8 are reported only.

**Tolerance times** (estimate [95% CI] vs truth):

| series | T_mean(0.1) | T_mean(0.2) | T_var(0.1) | o(70), fitted | o(70), empirical |
|---|---|---|---|---|---|
| C1 | 38.8 [33.0, 50.5] vs 37.3 | 31.8 [28.7, 36.5] vs 30.8 | 9.3 [8.0, 46.3] vs 11.0 | 0.004 vs 0.003 | 0.068 [−0.064, 0.19] vs 0.003 |
| C2 | 65.0 [53.5, 116] vs 66.5 | 52.0 [44.5, 64.2] vs 53.0 | 28.8 [19.3, 93.7] vs 33.3 | −0.076 vs −0.083 | −0.094 [−0.21, 0.012] vs −0.083 |
| C3 | 115.5 [104.5, 162] vs 113.3 | 102.8 [96.5, 114] vs 101.0 | 23.3 [15.0, 98.6] vs 18.5 | 1.20 [1.09, 1.33] vs 1.16 | 1.18 [1.05, 1.32] vs 1.16 |

**The MCSE-criterion time** on C3, δ = 0.2/√256 = 0.0125: 153 [139, 1840]
vs a truth of 149.5. The point estimate is right, but the upper CI is very
long, because the fit extrapolates below the noise.

**The tail window** starts at year 54 for C3 [53, 54], where the offset
first stays within 3 SD. Fitting from year 5 instead gives
T_mean(0.1) = 114.8 and o(70) = 1.20 on C3. Here the tail window changes
little, because C3 is exactly a sum of two exponentials. On the real data
it guards against the misspecified nonlinear transient.

**No transient (C0).** T_mean(0.1) = 0 and T_var(0.1) = 8, within the
0–10 criterion.

**Research-window offsets** (C3, 20-year mean, SD_π(M₂₀) units):

- B = 50: 2.60 [2.48, 2.75] vs 2.53;
- B = 100: 0.24 [0.12, 0.36] vs 0.15.

**Replications of C3** (30 datasets, 100 bootstrap refits each):

- the mean T_mean(0.1) is 114.4 [111.1, 117.7] vs 113.3;
- the CI of T_mean(0.1) covers the truth in 1.00 of cases, and the CI of
  the empirical o(70) in 0.90.

**Same-law tests:**

| check | result |
|---|---|
| H0, means, rejection rate at 5% (200 replications) | 0.05 |
| H0, variances, rejection rate | 0.07 |
| H1, mean shift of 0.1 SD in one variable, power | 1.00 |
| H1, variance × 1.1 in one variable, power | 0.99 |
| energy test, H0 rejection rate (100 replications) | 0.06 |
| energy test, shift of 0.2 SD in one variable, power (50 replications) | 1.00 |

## Interpretation

- **The fit-based tolerance times work after a cold start**, including an
  HIV-like overshoot and an over-dispersed start. They are nearly unbiased
  (C3: +1.2 years over 30 replications) and their CIs are conservative for
  T_mean.
- **The residual bias at year 70** is recovered empirically (coverage 0.90)
  and by the fit.
- **Times for the MCSE criterion** (tolerance ≪ noise) have the right point
  estimate but very long upper CIs. They extrapolate the fitted tail.
- **The permutation tests hold their level.** They detect a 0.1 SD mean
  difference or a 10% variance difference in one variable with power ≈ 1,
  which is the resolution c3_03 needs.

## Decision / input for next steps

- Use the fit-based times (tail window for the mean) in c3_04 and c3_05.
- Use the permutation and energy tests in c3_03.

## Caveats and deviations

- **Empirical o(70)** has a SE of about 1/16 SD with 256 chains. Only the
  fit can resolve smaller biases, and it assumes the tail keeps its fitted
  shape.
- **T_var(0.1) CIs are long** (upper ends 46–99 years), as in cycles 1–2:
  the variance ratio has a yearly relative SE of about 9%.
- **One variance-test rejection rate (0.07)** is above 0.05 but inside the
  binomial range for 200 replications (criterion 0.02–0.085).
