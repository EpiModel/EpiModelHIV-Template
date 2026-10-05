# C5-02. Validation of the paired-effect estimators

## Question

Do the estimators of C5-M2 recover known answers with the two designs of
cycle 5?

- **Balanced:** 32 points × 4 runs in both arms (S1–S3).
- **Unbalanced:** 32 × 4 against cycle 4's 1–15 runs per point (S4).

## Method

[c5_METHODS.md](c5_METHODS.md) C5-M2. Script: `c5_02_validate.R`.

- **Synthetic runs.** Equilibrium variance 1, split into 0.25 between points
  and 0.75 within (ICC 0.25, as the project outcome in cycle 4).
- **The scenario** multiplies the level by 1 − e (e = 0 or 0.1) and adds a
  point-level deviation of variance 0, 0.02, 0.1 or 0.3.
- **Noise:** normal, or skewed (centred gamma) to mimic counts.
- **Size:** 32 cases × 1,000 replications.
- **Criteria**, as in earlier cycles:
  - bias |z| < 3;
  - CI coverage in [0.93, 0.97];
  - with no heterogeneity, a rejection rate in [0.03, 0.07].

## Results

Source: `tables/c5_02_validation.csv`.

| check | passed | detail |
|---|---|---|
| average effect: bias and paired t CI | **32 / 32** | coverage 0.936–0.964 |
| heterogeneity test: size | **4 / 4** | rejection rate 0.047–0.057 with no heterogeneity |
| heterogeneity σ²_Δ: bias and F-inverted CI | 29 / 32 | the 3 misses are all in the unbalanced design, at no or small heterogeneity: coverage 0.922–0.927, biases fine (\|z\| ≤ 1.6) |

**Power of the heterogeneity test** (balanced design, from the rejection
rates):

| added heterogeneity (share of the equilibrium variance) | rejection rate |
|---|---|
| 0.02 | 0.07–0.09 |
| 0.1 | 0.23–0.25 |
| 0.3 | 0.69–0.75 |

On the project outcome's scale (CV 1.9%), 0.1 of the equilibrium variance
is σ_e ≈ 0.6 pp, and 0.3 is σ_e ≈ 1.0 pp.

## Interpretation

1. **The average effect and its paired CI are reliable** in both designs,
   also with skewed noise.
2. **The heterogeneity test holds its level.** A significant result is not
   an artefact.
3. **With 32 points, the test is weak for small heterogeneity.** It detects
   σ_e ≈ 1 pp about 7 times in 10, and σ_e ≈ 0.6 pp about 1 time in 4. The
   CIs are what counts: they say which values are compatible with the data.
4. **For S4 the heterogeneity CIs are slightly too narrow** (about 92%
   instead of 95%).

## Decision / input for next steps

- c5_03 uses the F-inverted CI, with the point bootstrap as a check.
- c5_05 reads S4's heterogeneity results as approximate.

## Caveats and deviations

- Normal and one skewed distribution only. Real runs have heavier dependence
  between outcomes, which this does not test.
