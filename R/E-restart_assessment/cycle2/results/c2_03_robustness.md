# C2-03. Robustness of the cycle 1 methods

## Question

Do the cycle 1 conclusions depend on method choices? This step checks:

- (a) the estimator of the time to full variance;
- (b) the π reference period;
- (c) nonlinear memory in the observed state;
- (d) memory longer than 150 years;
- (e) the behaviour of the detection rules and the fit-based CIs over
  replications;
- (f) the cycle 1 statement "lower bound ≤ direct value".

## Method

[c2_METHODS.md](c2_METHODS.md) C2-M3, C2-M5. Script: `c2_03_robustness.R`.

## Results

**(a) Three estimators of $T_{\text{var}}$ from x0** (`tables/c2_03_t_var_methods.csv`,
`figures/c2_03_t_var_methods.png`):

| variable | exp fit (cycle 1), ε = 0.1 | stretched exp | isotonic | exp fit, ε = 0.2 | stretched | isotonic |
|---|---|---|---|---|---|---|
| prev | 73 [59, 131] | 68 [52, 142] | 82 [51, 122] | 52 [43, 71] | 52 [42, 81] | 58 [38, 85] |
| prev.B | 66 [55, 85] | 61 [49, 80] | 71 [46, 108] | 48 [40, 60] | 48 [40, 60] | 46 [36, 80] |
| i.prev.dx.B | 69 [57, 86] | 62 [48, 86] | 72 [47, 116] | 50 [41, 61] | 50 [40, 61] | 47 [37, 78] |
| num | 75 [49, 327] | 80 [39, 199] | 47 [39, 280] | 45 [35, 69] | 51 [33, 90] | 43 [35, 78] |
| chla_prev | 42 [30, 152] | 63 [33, 129] | 41 [30, 187] | 22 [16, 37] | 28 [19, 44] | 30 [19, 42] |
| dx_frac | 26 [14, 47] | 19 [12, 39] | 27 [14, 67] | 7 [4, 16] | 9 [6, 16] | 5 [4, 27] |
| supp_frac, prep_cov, incid_rate | ≤ 5 | ≤ 5 | ≤ 5 | | | |

**(b) π reference period** (`tables/c2_03_pi_reference.csv`). With π
starting at year 150, 300 or 450:

- $v_\pi$ changes by ≤ 3%;
- $T_{\text{var}}(0.1)$ for prev is 71 / 73 / 70 years;
- the largest sensitivity is for prev.W (79 / 88 / 95) and syph_prev
  (56 / 59 / 79).

**(c) Nonlinear features** (`tables/c2_03_nonlinear_bounds.csv`). Squares
and products of the first 10 PCs change the lower bound by −0.001 to
−0.004 in all 10 responses. That is a small loss from extra variance, never
a gain.

**(d) Memory beyond 150 years** (`tables/c2_03_long_memory.csv`).
$L\operatorname{Var}(M_L)/v_\pi$ for prev:

| L | value |
|---|---|
| 150 | 54.3 |
| 225 | 57.0 |
| 450 | 63.2 [53.3, 73.6] |

- The curve flattens, so τ_int ≈ 60–65 years (cycle 1: ≥ 66, flagged as a
  lower value).
- Other variables plateau as well: num 42–48, STIs 16–22, dx_frac ≈ 8.
- The 450-year chain means are close to normal (kurtosis 2.7–3.7, Shapiro
  p ≥ 0.07). There is no sign of chain-level persistent components.

**(e) Replication study, 30 datasets per series** (`tables/c2_03_replication_summary.csv`):

| series (truth for $T_{\text{var}}(0.1)$) | brief's rule, median (IQR) | null-max rule | fit $T_{\text{var}}(0.1)$ median | CI coverage | fit $T_{\text{mean}}(0.1)$ coverage |
|---|---|---|---|---|---|
| S0 stationary (0) | 132 (1–270) | 66 (1–202) | 0 | 1.00 | 1.00 |
| S1 AR(1), x0 = 3 (10.9) | 149 (68–269) | 99 (28–269) | 11.3 | 0.90 | 0.90 |
| S2 two modes (3.1) | 105 (1–271) | 37 (1–230) | 5.5 | 0.83 | 1.00 |

**(f) Cycle 1 claim** (`tables/c2_03_claim_lb_vs_direct.csv`, `…_cases.csv`):

- **Annual values:** the lower bound exceeds the direct x0 value in 99 of
  297 pairs, and beyond the CI in 6. Those 6 are HIV incidence at h = 3–5,
  syphilis at h = 3–5, and PrEP / suppression at 25–30 years.
- **Window means:** 15 of 108 pairs, none beyond the CI.

## Interpretation

- **The time to full variance from x0 is robust to the estimator.** The
  three estimators agree within their CIs. Cycle 1's ≈ 70 years (ε = 0.1)
  and ≈ 50 years (ε = 0.2) for prevalence stand.
- **The memory is not longer than cycle 1 thought.** τ_int for prevalence
  is ≈ 60–65 years, and nothing suggests centuries-long components.
- **The gap between lower bound and direct is not nonlinearity in the
  observed state.** It comes from unobserved state and/or behaviour
  specific to x0.
- **The detection rules are unreliable in general, not just in one
  realisation.** They return essentially random years over 1–270 for all
  three series.
- **The fit-based times are nearly unbiased, but their bootstrap CIs are
  somewhat optimistic** (coverage 0.83–0.90). Read cycle 1 and cycle 2 CIs
  as ~85–90% intervals.
- **Cycle 1 overstated "lower bound ≤ direct".** The direct value belongs
  to one state. For syphilis and HIV incidence at short horizons it is
  *below* the stationary lower bound: runs from x0 diverge faster than
  average. A plausible cause is the growth phase triggered by the
  parameter change (e.g. syphilis going from 0.012 to 0.018 prevalence),
  which amplifies noise. The direct value is therefore neither an upper
  bound nor the average.

## Decision / input for next steps

- Keep the fit-based times, reported with a caveat on CI coverage.
- For same-parameter points, use the lower bound as the rigorous statement
  ([c2_02](c2_02_project_outcomes.md)).

## Caveats and deviations

- The replication study uses 100 bootstrap refits per dataset (200 on real
  data).
- S2's truth (3.1 years) is short relative to annual resolution; its
  +2.4-year bias is partly a model-misspecification effect of fitting 1–2
  exponentials.
