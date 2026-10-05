# 06. How much of the variance does the restart state fix? (ICC)

## Question

For a restart from a state drawn from π, what share of the variance of an
output $h$ years later is fixed by the restart state, i.e. ICC(h)? The same
question is asked for a 20-year window started after a burn-in B. ICC is the
variance a single restart point removes, and it sizes a pool.

## Method

[METHODS.md](../METHODS.md) M2.2, M2.3. Script: `06_restart_memory.R`.

**Lower bound, averaged over π:**

- 20,320 pseudo-restarts: 254 chains × 80 values of $t_0$ = 155, 160, …,
  550.
- 212 features: 53 key and state variables at $t_0$, $t_0-1$, $t_0-2$ and
  $t_0-5$.
- Ridge regression with λ chosen per response, and an own-value model.
- 8 chain-blocked folds; 500 chain bootstraps of the residuals.
- 513 responses.

**Direct value for this x0:** $1-v(h)/v_\pi$ from step 04.

## Results

The full table is `tables/06_icc_bounds.csv` (a compact version:
`tables/06_icc_summary.csv`). Figures: `figures/06_icc_values.png` and
`figures/06_icc_window_mean.png`.

**Annual value h years after restart**, lower bound / direct single x0:

| variable | h = 5 | h = 10 | h = 20 | h = 30 |
|---|---|---|---|---|
| prev | 0.90 / 0.92 | 0.77 / 0.83 | 0.49 / 0.65 | 0.27 / 0.44 |
| prev.B | 0.87 / 0.90 | 0.72 / 0.78 | 0.43 / 0.62 | 0.23 / 0.44 |
| prev.W | 0.86 / 0.89 | 0.70 / 0.78 | 0.42 / 0.52 | 0.23 / 0.33 |
| prev.H | 0.71 / 0.80 | 0.48 / 0.63 | 0.20 / 0.37 | 0.09 / 0.03 |
| num | 0.81 / 0.88 | 0.64 / 0.75 | 0.36 / 0.59 | 0.17 / 0.36 |
| gono_prev | 0.41 / 0.44 | 0.18 / 0.31 | 0.06 / 0.25 | 0.03 / 0.26 |
| chla_prev | 0.43 / 0.49 | 0.19 / 0.36 | 0.07 / 0.23 | 0.03 / 0.18 |
| syph_prev | 0.45 / 0.29 | 0.14 / 0.19 | 0.03 / 0.26 | 0.01 / 0.17 |
| dx_frac | 0.23 / 0.13 | 0.12 / 0.21 | 0.08 / 0.14 | 0.05 / 0.03 |
| incid_rate | 0.08 / −0.09 | 0.05 / 0.16 | 0.03 / 0.07 | 0.01 / −0.11 |
| supp_frac | 0.08 / 0.00 | 0.02 / 0.11 | 0.01 / 0.09 | 0.00 / −0.09 |
| prep_cov | 0.02 / −0.08 | 0.01 / −0.03 | 0.01 / −0.01 | 0.00 / −0.20 |

**Mean of the 20-year window after burn-in B**, lower bound [its lower CI] /
direct single x0:

| variable | B = 0 | B = 10 | B = 20 | B = 30 |
|---|---|---|---|---|
| prev | 0.81 [0.80] / 0.86 | 0.52 [0.50] / 0.66 | 0.29 [0.27] / 0.47 | 0.14 [0.12] / 0.31 |
| prev.B | 0.77 [0.76] / 0.84 | 0.47 [0.45] / 0.65 | 0.25 [0.23] / 0.46 | 0.12 [0.10] / 0.27 |
| prev.W | 0.77 [0.76] / 0.81 | 0.47 [0.45] / 0.56 | 0.26 [0.24] / 0.37 | 0.13 [0.11] / 0.30 |
| num | 0.72 [0.71] / 0.82 | 0.40 [0.39] / 0.59 | 0.19 [0.17] / 0.39 | 0.06 [0.05] / 0.20 |
| gono_prev | 0.38 [0.36] / 0.58 | 0.11 [0.09] / 0.41 | 0.04 [0.03] / 0.25 | 0.01 [0.01] / 0.11 |
| chla_prev | 0.39 [0.37] / 0.58 | 0.12 [0.10] / 0.41 | 0.04 [0.03] / 0.33 | 0.01 [0.01] / 0.17 |
| syph_prev | 0.34 [0.33] / 0.47 | 0.06 [0.05] / 0.40 | 0.02 [0.01] / 0.37 | 0.00 [0.00] / 0.21 |
| dx_frac | 0.34 [0.32] / 0.42 | 0.21 [0.19] / 0.30 | 0.13 [0.11] / 0.19 | 0.06 [0.05] / 0.22 |
| incid_rate | 0.32 [0.30] / 0.47 | 0.15 [0.13] / 0.32 | 0.07 [0.05] / 0.25 | 0.02 [0.01] / 0.17 |
| supp_frac | 0.12 [0.11] / 0.13 | 0.02 [0.02] / 0.10 | 0.01 [0.01] / 0.13 | 0.01 [0.00] / 0.11 |
| prep_cov | 0.14 [0.12] / 0.10 | 0.06 [0.05] / 0.10 | 0.02 [0.01] / 0.05 | 0.00 [0.00] / −0.07 |

**Other window functionals:**

- **Within-window variance.** $R^2 \le 0.002$ for every key variable. The
  restart state does not predict how much a run fluctuates.
- **Within-window slope.** $R^2$ ≈ 0.19–0.32 for prevalences, num and
  dx_frac.

**Sanity check.** At h = 0, $R^2$ ≈ 1 for every variable.

## Interpretation

- **The two estimates agree.** The ridge lower bound is always at or below
  the direct single-x0 value, and the own-value model sits on ρ(h)², as it
  should.
  - For HIV prevalence and population size the two are close (0.81 vs 0.86
    for the window mean at B = 0), so the observed state captures most of
    the memory.
  - For the STIs the direct value is clearly larger at long horizons (e.g.
    chla h = 20: 0.07 vs 0.23). This is expected because x0 is far from
    equilibrium for the STIs: runs from x0 are still relaxing (step 04),
    which is not the average behaviour of a state from π. The true
    π-average ICC lies between the two.
- **A single restart point is ruled out.** The lower bound for the 20-year
  window mean at B = 0 exceeds `ICC_THRESHOLD` = 0.05 for 25 of the 27 key
  outputs, and by an order of magnitude for most. The exceptions are
  prep_cov.H (0.019) and prep_cov.W (0.033). For HIV prevalence, a single point
  removes at least 81% of the between-run variance of the 20-year mean.
- **What the restart state fixes is the level and trend of slow outputs.**
  It does not fix the size of within-run fluctuations.
- **Burn-in reduces ICC, but slowly for HIV prevalence.** Even after a
  30-year post-restart burn-in, ≥ 14% of the variance of the prevalence
  window mean still comes from the (shared) restart state.

## Decision / input for next steps

- **Design ICC for step 07:** the larger of the two point estimates. For
  window means at B = 0:
  - prev 0.86;
  - num 0.82;
  - STIs 0.47–0.58;
  - incid_rate 0.47;
  - dx_frac 0.42;
  - supp_frac 0.13;
  - prep_cov 0.14.
- **Nested-experiment size** (brief rule n ≈ 1 + 1/ICC_lb): ≈ 2 runs per
  point for the slow outputs, and ≈ 8–9 for suppression and PrEP coverage.

## Caveats and deviations

- **Lower bounds miss unobserved memory.** Network structure, individual
  clocks and the like are not in the features. The direct single-x0 value
  includes them, but only for one atypical x0.
- **No random forest** (`ranger` is not installed). Taking the maximum over
  ridge and own-value models adds negligible optimism with 20k rows.
- **Runtime.** One `ridge_cv` call with 2 responses took 76 s in the clean
  run (with other steps running) and 24 s alone. The full run took about
  4–6 min on 8 cores, below the brief's 1-hour stop threshold.
