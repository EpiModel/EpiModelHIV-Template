# 04. From the single restart point to full variance (Q1)

## Question

Every run starts from the same state x0. How many years pass until the
distribution across runs has the stationary variance and mean? The question
is asked for annual values, and for the 20-year research windows actually
used after a post-restart burn-in B.

## Method

[METHODS.md](../METHODS.md) M2.2, M2.4, M2.5, M2.7. Script:
`04_relaxation_from_x0.R`.

- **Direct measurement.** 254 futures of the same x0 give
  $r(t)=v(t)/v_\pi$, the share of the stationary variance present $t$ years
  after the restart. The offset $o(t)$ of the mean is measured in SD units.
- **Time to full variance.** $T_{\text{var}}(\varepsilon)$ comes from a
  fitted relaxation curve, and $T_{\text{mean}}(\delta)$ likewise for the
  mean. Detection rules are not used because they fail validation (step 02).
- **Uncertainty.** 95% CIs from 200 chain-bootstrap refits.

## Results

### Annual values

The full table, for all 53 variables with fitted time constants, is
`tables/04_t_full_wide.csv` (long format: `tables/04_t_full.csv`).

| variable | τ (variance) | $T_{\text{var}}(0.1)$ | $T_{\text{var}}(0.2)$ | offset at year 1 | $T_{\text{mean}}(0.1)$ | $T_{\text{mean}}(0.2)$ |
|---|---|---|---|---|---|---|
| prev | 30.1 | 73 [59, 131] | 52 [43, 71] | −0.36 | 83 [74, 119] | 74 [67, 91] |
| prev.B | 27.2 | 66 [54, 84] | 48 [39, 58] | −0.69 | 82 [73, 118] | 74 [66, 86] |
| prev.W | 28.0 (+slow) | 88 [58, 571] | 54 [41, 87] | +0.17 | 85 [73, 162] | 72 [64, 94] |
| prev.H | 15.3 | 37 [30, 62] | 26 [22, 34] | −0.48 | 63 [47, 86] | 48 [38, 63] |
| incid_rate | 19.1 | 2 [0, 11] | 0 | +1.67 | 55 [47, 64] | 39 [34, 45] |
| dx_frac | 1.1 + 27.1 | 26 [13, 45] | 7 [4, 16] | +0.40 | 94 [18, 111] | 60 [15, 77] |
| supp_frac | 1.6 | 5 [4, 13] | 4 [3, 5] | −0.06 | 39 [8, 57] | 4 [2, 14] |
| prep_cov | 0.7 | 2 [2, 2] | 2 [2, 2] | +0.15 | 24 [20, 28] | 17 [14, 20] |
| gono_prev | 1.2 + 20.7 | 36 [24, 74] | 22 [14, 30] | +1.36 | 36 [32, 40] | 30 [26, 33] |
| chla_prev | 11.8 + 310 | 42 [29, 162] | 22 [13, 35] | −4.35 | 54 [44, 70] | 41 [34, 51] |
| syph_prev | 2.2 + 63.6 | 59 [29, 114] | 16 [8, 31] | −1.04 | 62 [49, 77] | 45 [36, 54] |
| num | 20.8 + 218 | 75 [49, 281] | 45 [35, 69] | −1.52 | 48 [41, 191] | 42 [36, 54] |

Figures: `figures/04_var_ratio_key.png` ($r(t)$ with bands and fits) and
`figures/04_mean_offset_key.png` ($o(t)$).

### 20-year research windows after a burn-in B

The table below gives $\operatorname{Var}(M_{20}(B))/\operatorname{Var}_\pi(M_{20})$,
the share of the stationary **between-run** variance of the 20-year window
mean (`tables/04_window_burnin.csv`):

| variable | B = 0 | B = 20 | B = 50 | B = 70 | B = 100 |
|---|---|---|---|---|---|
| prev | 0.14 [0.11, 0.16] | 0.53 [0.43, 0.63] | 0.82 [0.67, 0.96] | 0.90 [0.75, 1.06] | 0.94 [0.78, 1.11] |
| prev.B | 0.16 [0.13, 0.18] | 0.54 [0.44, 0.65] | 0.85 [0.72, 0.99] | 0.96 [0.82, 1.13] | 1.01 [0.86, 1.18] |
| prev.W | 0.19 [0.16, 0.23] | 0.63 [0.52, 0.74] | 0.76 [0.65, 0.92] | 0.84 [0.72, 1.00] | 0.89 [0.74, 1.06] |
| prev.H | 0.28 [0.23, 0.33] | 0.90 [0.75, 1.04] | 1.00 [0.85, 1.14] | 1.00 [0.84, 1.14] | 1.02 [0.84, 1.20] |
| incid_rate | 0.53 [0.44, 0.62] | 0.75 [0.61, 0.90] | 0.88 [0.74, 1.04] | 1.09 [0.90, 1.28] | 1.13 [0.94, 1.32] |
| dx_frac | 0.58 [0.50, 0.68] | 0.81 [0.66, 0.98] | 0.98 [0.80, 1.18] | 1.01 [0.83, 1.20] | 1.12 [0.92, 1.32] |
| gono_prev | 0.42 [0.35, 0.48] | 0.75 [0.63, 0.88] | 1.06 [0.87, 1.26] | 1.00 [0.83, 1.19] | 1.00 [0.84, 1.18] |
| chla_prev | 0.42 [0.35, 0.52] | 0.67 [0.56, 0.80] | 0.92 [0.76, 1.09] | 0.87 [0.74, 1.01] | 1.00 [0.82, 1.20] |
| syph_prev | 0.53 [0.44, 0.61] | 0.63 [0.52, 0.73] | 0.92 [0.77, 1.09] | 0.93 [0.75, 1.12] | 0.89 [0.73, 1.07] |
| num | 0.18 [0.15, 0.21] | 0.61 [0.50, 0.72] | 0.94 [0.77, 1.12] | 0.94 [0.80, 1.10] | 0.84 [0.68, 1.02] |

**Mean offset of the window mean**, in SD_π(M₂₀) units (same file):

| variable | B = 0 | B = 20 | B = 50 | B = 70 |
|---|---|---|---|---|
| prev | +0.59 | +1.11 | +0.43 | +0.12 [0.00, 0.26] |
| gono_prev | +2.30 | +0.48 | +0.01 | |
| incid_rate | +1.64 | +0.79 | +0.10 | |

**Within-window variance share.** At B = 0 it is 2.2 for prev and 4.9 for
chla_prev. Runs that start at x0 contain a trend that inflates the
within-run variance. The share is ≈ 1 from B ≈ 20.

**Burn-in fitted from the between-run curve** (`tables/04_window_burnin_needed.csv`):

| variable | $B$ for ≥ 0.8 | $B$ for ≥ 0.9 |
|---|---|---|
| prev | 45 [34, 65] | 66 [49, 141] |
| prev.B | 42 [32, 54] | 61 [46, 82] |
| prev.W | 46 [30, 126] | 114 [47, 741] |
| incid_rate | 24 [12, 40] | 42 [23, 81] |
| gono_prev | 24 [15, 38] | 38 [25, 174] |
| chla_prev | 33 [18, 75] | 89 [35, 511] |
| syph_prev | 43 [23, 72] | 79 [46, 217] |
| num | 36 [26, 63] | 52 [39, 481] |

Figure: `figures/04_window_burnin_key.png`.

### Multivariate view

**Energy distance.** The key and state variables are whitened into 18
components (95.5% of the variance). Their energy distance to π is
(`tables/04_energy_summary.csv`, `figures/04_energy_distance*.png`):

- year 1: 8.97;
- year 10: 1.52;
- year 20: 0.59;
- year 50: 0.158;
- year 70: 0.064;
- year 100: 0.059.

The null has median 0.052, 95% quantile 0.060 and maximum 0.070.

**Slowest direction.** This is PC1 (`tables/04_pc_t_full.csv`), and it is
the HIV-prevalence mode: loadings −0.91 on prev and −0.85 on prev.B
(`tables/04_pc_loadings.csv`).

- τ = 32.0 years;
- $T_{\text{var}}(0.1)$ = 75 [57, 248];
- $T_{\text{mean}}(0.1)$ = 99 [72, 126].

## Interpretation

1. **Memory from one restart point is long, and set by HIV prevalence.**
   HIV prevalence and the HIV/PrEP counts relax with a single time constant
   of about 25–30 years. The full variance (within 10%) is reached after
   ≈ 65–90 years, and the mean offset takes ≈ 75–100 years to fall below
   0.1 SD.
2. **The research-relevant quantity is even more demanding.** For 20-year
   windows started directly at x0, the HIV-prevalence window means across
   runs show only 14% of their stationary between-run variance. The mean is
   also shifted by +0.6 SD, then +1.1 SD at B = 20. That is the damped
   overshoot visible in `figures/01_key_first100y.png`. Reaching 80% of the
   between-run variance needs ≈ 45 years of post-restart burn-in, and 90%
   needs ≈ 65 years (CIs up to ~140).
3. **x0 is atypical.** At year 1 the mean offsets are:
   - −4.4 SD for chlamydia;
   - +1.4 SD for gonorrhoea;
   - +1.7 SD for HIV incidence;
   - −1.5 SD for population size.

   The STIs relax fast in variance (the first time constant is 1–2 years),
   but their means take 35–60 years to lose the imprint of x0. They also
   carry a small, very slow component (τ₂ ≈ 60–400 years with a tiny
   amplitude), which makes the 5% tolerance unreliable.
4. **Fast outputs forget x0 within a few years.** These are PrEP coverage,
   viral suppression and, for variance, HIV incidence. For them, runs from
   one point are fine after ~5–10 years, *except for the mean offset*.
5. **Multivariate check.** The energy distance falls to the level of the
   null 95% quantile at about year 70 and to the null median by year 100.
   This is consistent with the univariate answer: after ~70–100 years
   nothing distinguishes the state distribution from π.

## Decision / input for next steps

- `EQ_START` = 150: every variable is within tolerance by ~100 years, plus a
  50-year margin.
- Single-restart burn-in needed:
  - ≈ 70 years for 90% of the variance of annual HIV prevalence;
  - ≈ 65 years (up to ~140) for 90% of the between-run variance of 20-year
    windows;
  - ≈ 80–100 years for the mean to be within 0.1 SD.

## Caveats and deviations

- **Upper CIs.** Estimates for ε = 0.05 are at the resolution of 254 chains
  (the variance ratio has a yearly relative SE of ≈ 9%). The 2-exponential
  fits sometimes pick up a tiny, very slow component (τ₂ at the bound of
  1000 years), which produces the long upper CIs. Read ε = 0.1–0.2 as the
  reliable tolerances.
- **One x0 only.** All times are *for this x0*. A less atypical restart
  state would need less time for the mean, but probably not for the
  variance, which is governed by the ~30-year prevalence mode.
- **Brief's rule replaced.** The brief's $T_{\text{cold}}$ rule was replaced
  by fit-based times, because the rule fails validation (step 02).
