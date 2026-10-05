# 05. Equilibrium time structure

## Question

At stationarity, how long is each variable's memory? How is the stationary
variance seen over a 20-year run split between variation over time (within a
run) and variation over runs, where the latter is what the restart state
controls?

## Method

[METHODS.md](../METHODS.md) M2.6, M2.7. Script: `05_equilibrium_structure.R`.

- Data: years 150–600, 254 chains.
- Pooled ACF with the global mean, and τ_int by Geyer's initial monotone
  sequence. CIs from 500 chain bootstraps.
- Variance–time curve.
- Exact window decomposition at L = 20.

## Results

**π summary.** Means, SDs and quantiles are in `tables/05_pi_summary.csv`,
together with x0 in SD units (`x0_z`). Relative to π, the x0 snapshot is at:

- −5.5 SD for chla_prev;
- −1.7 SD for num;
- −1.3 SD for syph_prev;
- +1.7 SD for prep_cov.W;
- −0.56 SD for prev.

**Integrated autocorrelation time (years)** (`tables/05_tau_int.csv`):

| variable | τ_int [95% CI] | Geyer truncated at lag 150? |
|---|---|---|
| prev | 66.5 [59.4, 75.2] | yes (lower value) |
| prev.W | 62.0 [53.2, 69.8] | yes |
| prev.B | 58.0 [52.6, 65.3] | yes |
| num | 49.6 [47.3, 54.4] | no |
| prev.H | 40.3 [36.1, 44.8] | no |
| chla_prev | 22.9 [20.8, 25.3] | no |
| gono_prev | 22.3 [20.2, 24.6] | no |
| syph_prev | 18.4 [17.4, 20.0] | no |
| dx_frac | 10.4 [10.0, 10.8] | no |
| incid_rate | 9.6 [8.3, 10.7] | no |
| supp_frac | 7.1 [6.6, 7.6] | no |
| prep_cov | 3.1 [2.8, 3.4] | no |

**Variance–time curve** (`tables/05_variance_time.csv`,
`figures/05_variance_time_key.png`). For prev, $L\operatorname{Var}(M_L)/v_\pi$
is:

- 18.0 at L = 20;
- 46.8 at L = 100;
- 54.3 [50.3, 58.0] at L = 150.

It is still rising at the largest L. The same holds for prev.B/W and num
(43.6 at L = 150). The curves have plateaued for the STIs (≈ 20) and for
dx_frac (≈ 8–9).

**Window decomposition at L = 20** (`tables/05_variance_split_L20.csv`,
`figures/05_variance_split_L20.png`). This is the share of $v_\pi$ seen only
**between** 20-year runs:

| variable | between runs | within a run |
|---|---|---|
| prev | 0.898 [0.893, 0.903] | 0.102 |
| prev.B / prev.W | 0.875 / 0.871 | 0.125 / 0.129 |
| num | 0.864 | 0.136 |
| prev.H | 0.773 | 0.227 |
| chla_prev / gono_prev | 0.582 / 0.576 | 0.418 / 0.424 |
| syph_prev | 0.560 | 0.440 |
| dx_frac | 0.397 | 0.603 |
| supp_frac | 0.294 | 0.706 |
| incid_rate | 0.193 | 0.807 |
| prep_cov | 0.121 | 0.879 |

The identity $\mathbb E[S^2]+\operatorname{Var}(M)=v_\pi$ holds to
≤ 6 × 10⁻⁹ in absolute terms (`identity_error`).

**Reference curves for step 06.** $\rho(h)^2$ and $\rho(2h)$ are in
`tables/05_rho_reference.csv`.

## Interpretation

- **HIV prevalence has a very long memory.** τ_int is at least ~65 years,
  which is more than three research-run lengths. Over a 20-year run, 90% of
  its stationary variance is a between-run level shift that the run cannot
  show over time. The restart state therefore determines most of the
  variation of prevalence across 20-year runs.
- **Incidence, PrEP coverage and viral suppression are dominated by
  short-term noise.** Within a run they show 70–90% of their stationary
  variance, so they are much less sensitive to the restart design.
- **STIs sit in between,** at ≈ 57% between runs.

## Decision / input for next steps

- The slowest key variable is prev (τ_int ≥ 66 y). It sets the
  single-chain spacing heuristic d ≥ 2 τ_int ≈ 130 years (step 07).
- The between-run fractions at L = 20 are the upper limits on what a restart
  state can control. Step 06 measures how much of them it actually fixes.

## Caveats and deviations

- **τ_int for slow variables is a lower value.** For prev, prev.B, prev.W
  and the HIV counts, the Geyer sequence was still positive at lag 150. On
  synthetic data with a slow, low-weight component, Geyer's estimator is
  biased low (step 02, S2), and the variance–time curves are still rising.
- **ESS.** `posterior` is not installed, so ESS-based τ_int was not
  computed. Only Geyer's estimator is reported.
- **ACF CIs are too narrow.** On synthetic data they covered 0.88–0.96 over
  replications, so they may be ~10–20% too narrow.
- **No reversibility check.** The cross-correlation reversibility check was
  not run. $\rho(2h)$ is used only as a heuristic.
